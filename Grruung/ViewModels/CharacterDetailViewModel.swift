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
    @Published var growthStages: [GrowthStage] = []
    private let storageService = GrowthStageService()
    
    // MARK: - Loading States
    @Published var isLoading = false
    private var isLoadingCharacter = false
    private var isLoadingUser = false
    private var isLoadingPosts = false
    
    // MARK: - Firebase Services
    private let firebaseService = FirebaseService.shared
    private var characterListener: ListenerRegistration?
    
    private var db = Firestore.firestore()
    private var storage = Storage.storage()
    
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
            setupCharacterListener(characterUUID: characterUUID)
            loadPost(characterUUID: characterUUID, searchDate: Date())
            loadUserByCharacterUUID(characterUUID: characterUUID)
        }
    }
    
    // Firebase에서 캐릭터 실시간 로딩 및 리스너 설정
    private func setupCharacterListener(characterUUID: String) {
        guard !isLoadingCharacter else { return }
        isLoadingCharacter = true
        updateLoadingState()
        
        // FirebaseService를 통해 캐릭터 로드
        characterListener = firebaseService.setupCharacterListener(characterID: characterUUID) { [weak self] character, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ 캐릭터 로드 실패: \(error.localizedDescription)")
                    self.isLoadingCharacter = false
                    self.updateLoadingState()
                    return
                }
                
                if let character = character {
                    print("✅ 캐릭터 로드 성공: \(character.name)")
                    self.character = character
                    self.characterStatus = character.status
                    
                    // 성장 단계 이미지 로드
                    self.loadGrowthStages()
                } else {
                    print("❌ 캐릭터를 찾을 수 없습니다")
                }
                
                self.isLoadingCharacter = false
                self.updateLoadingState()
            }
        }
    }
    
    // 성장 단계 이미지 로드
    func loadGrowthStages() {
        Task {
            // 종에 따라 폴더명 결정
            let folderName: String
            switch character.species {
            case .CatLion:
                folderName = "catlion_growth_stages"
            case .quokka:
                folderName = "quokka_growth_stages"
            default:
                folderName = "growth_stages"
            }
            
            print("📸 성장 단계 이미지 로딩 시작: \(folderName)")
            
            let stages = await storageService.fetchGrowthStageImages(folderName: folderName)
            await MainActor.run {
                print("📸 성장 단계 이미지 로딩 완료: \(stages.count)개")
                self.growthStages = stages
            }
        }
    }
    
    func loadCharacter(characterUUID: String) {
        guard !isLoadingCharacter else { return }
        self.isLoadingCharacter = true
        self.isLoading = true
        
        db.collection("GRCharacter").document(characterUUID).getDocument{ [weak self] snapshot, error in
            guard let self = self else { return }
            guard let data = snapshot?.data() else {
                self.isLoadingCharacter = false
                self.checkLoadingComplete()
                return
            }
            
            // 데이터 파싱 및 GRCharacter 생성
            let species = PetSpecies(rawValue: data["species"] as? String ?? "") ?? .Undefined
            let name = data["name"] as? String ?? "이름 없음"
            
            // 이미지 이름 확인 및 수정
            let imageName = data["imageName"] as? String ?? ""
            // 이미지 이름이 비어있으면 species에 따라 기본 이미지 설정
            let finalImageName = imageName.isEmpty ?
                (species == .quokka ? "quokka" : "CatLion") : imageName
            
            print("imageName: \(finalImageName)")
            
            let birthDate = (data["birthDate"] as? Timestamp)?.dateValue() ?? Date()
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            
            // status 맵에서 캐릭터 상태 정보 가져오기
            var level = 1
            var exp = 0
            var expToNextLevel = 100
            var phase: CharacterPhase = .egg
            var address = "paradise"
            var satiety = 100
            var stamina = 100
            var activity = 100
            
            if let statusMap = data["status"] as? [String: Any] {
                level = statusMap["level"] as? Int ?? 1
                exp = statusMap["exp"] as? Int ?? 0
                expToNextLevel = statusMap["expToNextLevel"] as? Int ?? 100
                phase = CharacterPhase(rawValue: statusMap["phase"] as? String ?? "") ?? .egg
                address = statusMap["address"] as? String ?? "paradise"
                satiety = statusMap["satiety"] as? Int ?? 100
                stamina = statusMap["stamina"] as? Int ?? 100
                activity = statusMap["activity"] as? Int ?? 100
                
                print("status 맵에서 가져온 phase 값: \(statusMap["phase"] as? String ?? "값 없음")")
            }
            
            print("변환된 phase 값: \(phase)")
            
            let status = GRCharacterStatus(
                level: level,
                exp: exp,
                expToNextLevel: expToNextLevel,
                phase: phase,
                satiety: satiety,
                stamina: stamina,
                activity: activity,
                address: address
            )
            
            DispatchQueue.main.async {
                self.characterStatus = GRCharacterStatus(
                    level: level,
                    exp: exp,
                    expToNextLevel: expToNextLevel,
                    phase: phase,
                    satiety: satiety,
                    stamina: stamina,
                    activity: activity,
                    address: address
                )
                self.character = GRCharacter(
                    id: characterUUID,
                    species: species,
                    name: name,
                    imageName: finalImageName,
                    birthDate: birthDate,
                    createdAt: createdAt,
                    status: status
                )
                
                self.loadGrowthStages()
            }
            
            // 캐릭터 정보 로드 후 성장 단계 이미지 로드
            print("Firebase에서 가져온 phase 값: \(data["phase"] as? String ?? "값 없음")")
            print("변환된 phase 값: \(phase)")
            // 로딩 완료 후 플래그 해제
            self.isLoadingCharacter = false
            self.checkLoadingComplete()
        }
    }
    
    // 캐릭터 이름 업데이트
    func updateCharacterName(characterUUID: String, newName: String) {
        guard !newName.isEmpty else { return }
        
        isLoadingCharacter = true
        updateLoadingState()
        
        // FirebaseService를 통해 캐릭터 로드 후 이름 업데이트
        firebaseService.loadCharacterByID(characterID: characterUUID) { [weak self] character, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ 캐릭터 로드 실패: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoadingCharacter = false
                    self.updateLoadingState()
                }
                return
            }
            
            guard var character = character else {
                print("❌ 캐릭터를 찾을 수 없습니다")
                DispatchQueue.main.async {
                    self.isLoadingCharacter = false
                    self.updateLoadingState()
                }
                return
            }
            
            // 이름 업데이트
            character.name = newName
            
            // Firebase에 저장
            self.firebaseService.saveCharacter(character) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ 캐릭터 이름 업데이트 실패: \(error.localizedDescription)")
                    } else {
                        print("✅ 캐릭터 이름 업데이트 성공: \(newName)")
                        
                        // NotificationCenter로 다른 뷰에 알림
                        NotificationCenter.default.post(
                            name: NSNotification.Name("CharacterNameChanged"),
                            object: nil,
                            userInfo: ["characterUUID": characterUUID, "name": newName]
                        )
                    }
                    
                    self.isLoadingCharacter = false
                    self.updateLoadingState()
                }
            }
        }
    }
    
    // 캐릭터 주소(위치) 업데이트
    func updateAddress(characterUUID: String, newAddress: Address) {
        isLoadingCharacter = true
        updateLoadingState()
        
        // FirebaseService를 통해 캐릭터 로드 후 주소 업데이트
        firebaseService.loadCharacterByID(characterID: characterUUID) { [weak self] character, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ 캐릭터 로드 실패: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoadingCharacter = false
                    self.updateLoadingState()
                }
                return
            }
            
            guard var character = character else {
                print("❌ 캐릭터를 찾을 수 없습니다")
                DispatchQueue.main.async {
                    self.isLoadingCharacter = false
                    self.updateLoadingState()
                }
                return
            }
            
            // 주소 업데이트
            character.status.address = newAddress.rawValue
            
            // 현재 메인 캐릭터 ID 확인
            self.firebaseService.getMainCharacterID { mainCharacterID, error in
                // 업데이트하는 캐릭터가 메인이고, 새 주소가 userHome이 아니면 메인 캐릭터 초기화
                if mainCharacterID == characterUUID && newAddress != .userHome {
                    self.firebaseService.setMainCharacter(characterID: "") { _ in
                        // 메인 캐릭터 초기화 후 캐릭터 주소 업데이트
                        self.saveCharacterWithNewAddress(character)
                    }
                } else {
                    // 메인 캐릭터가 아니면 바로 주소 업데이트
                    self.saveCharacterWithNewAddress(character)
                }
            }
        }
    }
    
    // 주소 변경된 캐릭터 저장 (헬퍼 메서드)
    private func saveCharacterWithNewAddress(_ character: GRCharacter) {
        // Firebase에 저장
        self.firebaseService.saveCharacter(character) { [weak self] error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ 캐릭터 주소 업데이트 실패: \(error.localizedDescription)")
                } else {
                    print("✅ 캐릭터 주소 업데이트 성공: \(character.status.address)")
                    
                    // NotificationCenter로 다른 뷰에 알림
                    NotificationCenter.default.post(
                        name: NSNotification.Name("CharacterAddressChanged"),
                        object: nil,
                        userInfo: ["characterUUID": character.id, "address": character.status.address]
                    )
                }
                
                self.isLoadingCharacter = false
                self.updateLoadingState()
            }
        }
    }
    
    // 캐릭터를 메인으로 설정
    func setAsMainCharacter(characterUUID: String) {
        isLoadingCharacter = true
        updateLoadingState()
        
        firebaseService.setMainCharacter(characterID: characterUUID) { [weak self] error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ 메인 캐릭터 설정 실패: \(error.localizedDescription)")
                } else {
                    print("✅ 메인 캐릭터 설정 성공")
                }
                
                self.isLoadingCharacter = false
                self.updateLoadingState()
            }
        }
    }
    
    // 캐릭터 UUID로 사용자 정보 로드
    private func loadUserByCharacterUUID(characterUUID: String) {
        guard !isLoadingUser else { return }
        isLoadingUser = true
        updateLoadingState()
        
        // 현재 로그인된 사용자의 ID 가져오기
        guard let currentUserID = firebaseService.getCurrentUserID() else {
            print("❌ 로그인된 사용자가 없습니다")
            isLoadingUser = false
            updateLoadingState()
            return
        }
        
        // users 컬렉션에서 현재 사용자 정보 로드
        db.collection("users").document(currentUserID).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ 사용자 정보 로드 실패: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoadingUser = false
                    self.updateLoadingState()
                }
                return
            }
            
            guard let data = snapshot?.data() else {
                print("❌ 사용자 데이터가 없습니다")
                DispatchQueue.main.async {
                    self.isLoadingUser = false
                    self.updateLoadingState()
                }
                return
            }
            
            let userEmail = data["userEmail"] as? String ?? ""
            let userName = data["userName"] as? String ?? ""
            let registeredAt = (data["registeredAt"] as? Timestamp)?.dateValue() ?? Date()
            let lastUpdatedAt = (data["lastUpdatedAt"] as? Timestamp)?.dateValue() ?? Date()
            let gold = data["gold"] as? Int ?? 0
            let diamond = data["diamond"] as? Int ?? 0
            let chosenCharacterUUID = data["chosenCharacterUUID"] as? String ?? ""
            
            DispatchQueue.main.async {
                self.user = GRUser(
                    id: currentUserID,
                    userEmail: userEmail,
                    userName: userName,
                    registeredAt: registeredAt,
                    lastUpdatedAt: lastUpdatedAt,
                    gold: gold,
                    diamond: diamond,
                    chosenCharacterUUID: chosenCharacterUUID
                )
                
                print("✅ 사용자 정보 로드 성공: \(userName)")
                
                self.isLoadingUser = false
                self.updateLoadingState()
            }
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
    
    // 특정 월의 게시물 로드
    func loadPost(characterUUID: String, searchDate: Date) {
        print("📝 게시물 로드 시작: \(characterUUID), 날짜: \(searchDate)")
        let calendar = Calendar.current
        let month = calendar.component(.month, from: searchDate)
        let year = calendar.component(.year, from: searchDate)
        
        fetchPostsFromFirebase(characterUUID: characterUUID, year: year, month: month)
    }
    
    // 게시물 삭제
    func deletePost(postID: String) {
        guard !isLoadingPosts else { return }
        isLoadingPosts = true
        updateLoadingState()
        
        db.collection("GRPost").document(postID).delete { [weak self] error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ 게시물 삭제 실패: \(error.localizedDescription)")
                } else {
                    print("✅ 게시물 삭제 성공")
                    self.posts.removeAll { $0.postID == postID }
                }
                
                self.isLoadingPosts = false
                self.updateLoadingState()
            }
        }
    }
    
    // Firebase에서 게시물 가져오기
    private func fetchPostsFromFirebase(characterUUID: String, year: Int, month: Int) {
        guard !isLoadingPosts else { return }
        isLoadingPosts = true
        updateLoadingState()
        
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = 1
        dateComponents.hour = 0
        dateComponents.minute = 0
        dateComponents.second = 0
        
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(from: dateComponents),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            isLoadingPosts = false
            updateLoadingState()
            return
        }
        
        db.collection("GRPost")
            .whereField("characterUUID", isEqualTo: characterUUID)
            .whereField("createdAt", isGreaterThanOrEqualTo: startOfMonth)
            .whereField("createdAt", isLessThanOrEqualTo: endOfMonth)
            .order(by: "updatedAt", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ 게시물 로드 실패: \(error.localizedDescription)")
                        self.isLoadingPosts = false
                        self.updateLoadingState()
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("📝 게시물이 없습니다")
                        self.posts = []
                        self.isLoadingPosts = false
                        self.updateLoadingState()
                        return
                    }
                    
                    print("📝 \(documents.count)개의 게시물을 로드했습니다")
                    
                    self.posts = documents.compactMap { document -> GRPost? in
                        let data = document.data()
                        let documentID = document.documentID
                        let postCharacterUUID = data["characterUUID"] as? String ?? ""
                        let postTitle = data["postTitle"] as? String ?? ""
                        let postImage = data["postImage"] as? String ?? ""
                        let postBody = data["postBody"] as? String ?? ""
                        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                        let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
                        
                        return GRPost(
                            postID: documentID,
                            characterUUID: postCharacterUUID,
                            postTitle: postTitle,
                            postBody: postBody,
                            postImage: postImage,
                            createdAt: createdAt,
                            updatedAt: updatedAt
                        )
                    }
                    
                    self.isLoadingPosts = false
                    self.updateLoadingState()
                }
            }
    }
    
    // 내부 로딩 완료 확인 메서드 추가
    private func checkLoadingComplete() {
        DispatchQueue.main.async {
            self.isLoading = self.isLoadingCharacter || self.isLoadingUser || self.isLoadingPosts
        }
    }
    // 전체 로딩 상태 업데이트
    private func updateLoadingState() {
        DispatchQueue.main.async {
            self.isLoading = self.isLoadingCharacter || self.isLoadingUser || self.isLoadingPosts
        }
    }
    
    deinit {
        characterListener?.remove()
        print("🧹 CharacterDetailViewModel 정리 완료")
    }
    
} // end of class
