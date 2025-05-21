//
//  CharacterDetailViewModel.swift
//  Grruung
//
//  Created by NO SEONGGYEONG on 5/2/25.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseStorage

class CharacterDetailViewModel: ObservableObject {
    
    @Published var character: GRCharacter
    @Published var characterStatus: GRCharacterStatus = GRCharacterStatus()
    @Published var user: GRUser
    @Published var posts: [GRPost] = []
    
    // 로딩 상태 추적을 위한 플래그
    @Published var isLoading  = false
    private var isLoadingCharacter = false
    // 혹시 다른 컬렉션에서 캐릭터 상태를 가져와야 할 때를 대비하여 주석 처리
    //    private var isLoadingCharacterStatus = false
    private var isLoadingUser = false
    private var isLoadingPosts = false
    
    
    private var db = Firestore.firestore()
    private var storage = Storage.storage() // Firebase Storage (이미지 업로드용)
    
    init(characterUUID: String = "") {
        // 기본 더미 캐릭터로 초기화
        self.character = GRCharacter(
            id: UUID().uuidString,
            species: .Undefined,
            name: "기본 캐릭터",
            imageName: "",
            birthDate: Date(),
            createdAt: Date()
        )
        
        self.user = GRUser(
            id: UUID().uuidString,
            userEmail: "",
            userName: "",
            chosenCharacterUUID: ""
        )
        
        // 초기화시 UUID가 제공되면 데이터 로드
        if !characterUUID.isEmpty {
            self.loadCharacter(characterUUID: characterUUID)
            // 혹시 다른 컬렉션에서 캐릭터 상태를 가져와야 할 때를 대비하여 주석 처리
            //            self.loadCharacterStatus(characterUUID: characterUUID)
            self.loadPost(characterUUID: characterUUID, searchDate: Date())
            self.loadUser(characterUUID: characterUUID)
        }
    }
    
    func loadCharacter(characterUUID: String) {
        guard !isLoadingCharacter else { return }
        self.isLoadingCharacter = true
        self.isLoading = true
        
        db.collection("GRCharacter").document(characterUUID).getDocument{ [weak self] snapshot, error in
            guard let self = self else { return }
            guard let data = snapshot?.data() else {
                return
            }
            
            // 데이터 파싱 및 GRCharacter 생성
            let species = PetSpecies(rawValue: data["species"] as? String ?? "") ?? .Undefined
            let name = data["name"] as? String ?? "이름 없음"
            let imageName = data["imageName"] as? String ?? ""
            print("imageName: \(imageName)")
            let birthDate = (data["birthDate"] as? Timestamp)?.dateValue() ?? Date()
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            
            // 데이터 파싱 및 GRCharacterStatus 생성
            let level = data["level"] as? Int ?? 1
            let exp = data["exp"] as? Int ?? 0
            let expToNextLevel = data["expToNextLevel"] as? Int ?? 100
            let phase = CharacterPhase(rawValue: data["phase"] as? String ?? "") ?? .egg
            let address = data["address"] as? String ?? "동산"
            
            let status = GRCharacterStatus() // 기본 상태로 초기화
            
            DispatchQueue.main.async {
                self.character = GRCharacter(
                    id: characterUUID,
                    species: species,
                    name: name,
                    imageName: imageName,
                    birthDate: birthDate,
                    createdAt: createdAt,
                    status: status
                )
                
                self.characterStatus = GRCharacterStatus(
                    level: level,
                    exp: exp,
                    expToNextLevel: expToNextLevel,
                    phase: phase,
                    address: address
                )
            }
            // 로딩 완료 후 플래그 해제
            self.isLoadingCharacter = false
            self.checkLoadingComplete()
        }
    }
    
    func updateCharacterName(characterUUID: String, newName: String) {
        // 로딩 상태 확인
        guard !isLoadingCharacter else { return }
        isLoadingCharacter = true
        self.isLoading = true
        
        db.collection("GRCharacter").document(characterUUID).updateData([
            "name": newName
        ]) { error in
            if let error = error {
                print("Error updating character name: \(error)")
                self.isLoadingCharacter = false
                self.checkLoadingComplete()
            } else {
                print("Character name updated successfully")
                self.character.name = newName // 로컬 캐릭터 이름 업데이트
            }
            // 로딩 완료 후 플래그 해제
            self.isLoadingCharacter = false
            self.checkLoadingComplete()
        }
    }
    
    func updateAddress(characterUUID: String, newAddress: Address) {
        // 로딩 상태 확인
        guard !isLoadingCharacter else { return }
        isLoadingCharacter = true
        isLoading = true
        db.collection("GRCharacter").document(characterUUID).updateData([
            "address": newAddress.rawValue
        ]) { error in
            if let error = error {
                print("Error updating address: \(error)")
                self.isLoadingCharacter = false
                self.checkLoadingComplete()
            } else {
                print("Address updated successfully")
                self.characterStatus.address = newAddress.rawValue // 로컬 캐릭터 주소 업데이트
            }
            self.isLoadingCharacter = false
            self.checkLoadingComplete()
        }
    }
    
    func loadUser(characterUUID: String) {
        guard !isLoadingUser else { return }
        isLoadingUser = true
        self.isLoading = true
        
        print("loadUser 함수 호출 됨 - characterUUID: \(characterUUID)")
        db.collection("GRUser").whereField("chosenCharacterUUID", isEqualTo: characterUUID).getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            
            if let error = error {
                print("사용자 정보 가져오기 오류 : \(error)")
                self.isLoadingUser = false
                self.checkLoadingComplete()
                return
            }
            
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                print("No documents found")
                self.isLoadingUser = false
                self.checkLoadingComplete()
                return
            }
            
            let document = documents[0]
            let data = document.data()
            let userID = document.documentID
            let userEmail = data["userEmail"] as? String ?? ""
            let userName = data["userName"] as? String ?? ""
            let chosenCharacterUUID = data["chosenCharacterUUID"] as? String ?? ""
            
            print("사용자 찾음 - User Name: \(userName), Chosen Character UUID: \(chosenCharacterUUID)")
            
            // 메인 스레드에서 user 속성 업데이트
            DispatchQueue.main.async {
                self.user = GRUser(
                    id : userID,
                    userEmail: userEmail,
                    userName: userName,
                    chosenCharacterUUID: chosenCharacterUUID
                )
            }
            
            // 로딩 완료 후 플래그 해제
            self.isLoadingUser = false
            self.checkLoadingComplete()
        }
    }
    
    func loadPost(characterUUID: String, searchDate: Date) {
        print("loadPost called with characterUUID: \(characterUUID) and searchDate: \(searchDate)")
        let calendar = Calendar.current
        let month = calendar.component(.month, from: searchDate)
        let year = calendar.component(.year, from: searchDate)
        
        fetchPostsFromFirebase(characterUUID: characterUUID,year: year, month: month)
    }
    
    func deletePost(postID: String) {
        // 로딩 상태 확인
        guard !isLoadingPosts else { return }
        isLoadingPosts = true
        self.isLoading = true
        db.collection("GRPost").document(postID).delete { error in
            if let error = error {
                print("Error deleting post: \(error)")
                self.isLoadingPosts = false
                self.checkLoadingComplete()
            } else {
                print("Post deleted successfully")
                DispatchQueue.main.async {
                    self.posts.removeAll { $0.postID == postID }
                }
            }
            // 로딩 완료 후 플래그 해제
            self.isLoadingPosts = false
            self.checkLoadingComplete()
        }
    }
    
    func fetchPostsFromFirebase(characterUUID: String,year: Int, month: Int) {
        // 로딩 상태 확인
        guard !isLoadingPosts else { return }
        isLoadingPosts = true
        self.isLoading = true
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = 1
        dateComponents.hour = 0
        dateComponents.minute = 0
        dateComponents.second = 0
        
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(from: dateComponents) else {
            return
        }
        guard let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return
        }
        
        self.db.collection("GRPost")
            .whereField("characterUUID", isEqualTo: characterUUID)
            .whereField("createdAt", isGreaterThanOrEqualTo: startOfMonth)
            .whereField("createdAt", isLessThanOrEqualTo: endOfMonth)
            .order(by: "updatedAt", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching posts: \(error)")
                    self.isLoadingPosts = false
                    self.checkLoadingComplete()
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found")
                    self.posts = []
                    self.isLoadingPosts = false
                    self.checkLoadingComplete()
                    return
                }
                print("Fetched \(documents.count) posts.")
                
                self.posts = documents.compactMap { document -> GRPost? in
                    let data = document.data()
                    let documentID = document.documentID
                    let postCharacterUUID = data["characterUUID"] as? String ?? ""
                    let postTitle = data["postTitle"] as? String ?? ""
                    let postImage = data["postImage"] as? String ?? ""
                    let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
                    
                    return GRPost(
                        postID: documentID,
                        characterUUID: postCharacterUUID,
                        postTitle: postTitle,
                        postBody: data["postBody"] as? String ?? "",
                        postImage: postImage,
                        createdAt: createdAt,
                        updatedAt: updatedAt
                    )
                }
                
                print("Updated self.posts with \(self.posts.count) posts.")
                
                // 로딩 완료 후 플래그 해제
                self.isLoadingPosts = false
                self.checkLoadingComplete()
            }
    }
    
    // 내부 로딩 완료 확인 메서드 추가
    private func checkLoadingComplete() {
        DispatchQueue.main.async {
            self.isLoading = self.isLoadingCharacter || self.isLoadingUser || self.isLoadingPosts
        }
    }
    
    // 혹시 다른 컬렉션에서 캐릭터 상태를 가져와야 할 때를 대비하여 주석 처리
    //    func loadCharacterStatus(characterUUID: String) {
    //
    //        guard !isLoadingCharacterStatus else { return }
    //        self.isLoadingCharacterStatus = true
    //        self.isLoading = true
    //
    //        db.collection("GRCharacter").document(characterUUID).getDocument { [weak self] snapshot, error in
    //            guard let self = self else { return }
    //            guard let data = snapshot?.data() else {
    //                return
    //            }
    //
    //            // 데이터 파싱 및 GRCharacterStatus 생성
    //            let level = data["level"] as? Int ?? 1
    //            let exp = data["exp"] as? Int ?? 0
    //            let expToNextLevel = data["expToNextLevel"] as? Int ?? 100
    //            let phase = CharacterPhase(rawValue: data["phase"] as? String ?? "") ?? .egg
    //
    //            DispatchQueue.main.async {
    //                self.characterStatus = GRCharacterStatus(
    //                    level: level,
    //                    exp: exp,
    //                    expToNextLevel: expToNextLevel,
    //                    phase: phase
    //                )
    //            }
    //            // 로딩 완료 후 플래그 해제
    //            self.isLoadingCharacterStatus = false
    //            self.checkLoadingComplete()
    //        }
    //    }
    
} // end of class
