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
    @Published var posts: [GRPost] = []
    
    private var db = Firestore.firestore()
    private var storage = Storage.storage() // Firebase Storage (이미지 업로드용)
    
    init(characterUUID: String = "") {  
        // 기본 더미 캐릭터로 초기화
        self.character = GRCharacter(
            id: UUID().uuidString,
            species: .Undefined,
            name: "기본 캐릭터",
            imageName: "pawprint.fill",
            birthDate: Date(),
            createdAt: Date()
            
        )
        
        // 초기화시 UUID가 제공되면 데이터 로드
        if !characterUUID.isEmpty {
            self.loadCharacter(characterUUID: characterUUID)
            self.loadPost(characterUUID: characterUUID, searchDate: Date())
        }
    }
    
    func loadCharacter(characterUUID: String) {
        
        db.collection("GRCharacter").document(characterUUID).getDocument{ [weak self] snapshot, error in
            guard let self = self else { return }
            
            
            guard let data = snapshot?.data() else {
                return
            }
            
            // 데이터 파싱 및 GRCharacter 생성
            let species = PetSpecies(rawValue: data["species"] as? String ?? "") ?? .Undefined
            let name = data["name"] as? String ?? "이름 없음"
            let imageName = data["imageName"] as? String ?? "pawprint.fill"
            let birthDate = (data["birthDate"] as? Timestamp)?.dateValue() ?? Date()
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            print("캐릭터 생성 된 날짜 : \(createdAt)")
            // 상태 정보 파싱 (실제 앱에 맞게 조정 필요)
            // 만약 status가 별도의 필드로 저장되어 있다면 해당 필드에서 가져와야 함
            let status = GRCharacterStatus() // 기본 상태로 초기화 (실제 데이터와 연결 필요)
            
            self.character = GRCharacter(
                id: characterUUID,
                species: species,
                name: name,
                imageName: imageName,
                birthDate: birthDate,
                createdAt: createdAt,
                status: status
            )
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
        db.collection("GRPost").document(postID).delete { error in
            if let error = error {
                print("Error deleting post: \(error)")
            } else {
                print("Post deleted successfully")
                DispatchQueue.main.async {
                    self.posts.removeAll { $0.postID == postID }
                }
            }
        }
    }
    
    
    func fetchPostsFromFirebase(characterUUID: String,year: Int, month: Int) {
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
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found")
                    self.posts = []
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
            }
    }
    
} // end of class

// MARK: NavigationView 사용 시 수정 뷰로 이동 안되므로 꼭 상위 뷰에서 NavigationStack을 사용해야 함
import SwiftUI
#Preview {
    NavigationStack {
        CharacterDetailView(characterUUID: "CF6NXxcH5HgGjzVE0nVE")
    }
}
