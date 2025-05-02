//
//  CharacterDetailViewModel.swift
//  Grruung
//
//  Created by NO SEONGGYEONG on 5/2/25.
//

import Foundation
import Combine
import FirebaseFirestore

// 더미 데이터
struct GRCharacter {
    let characterUUID: String
    let species: String
    let name: String
    let image: String
    let grCharacterStatus: String
    
    init(
        characterUUID: String = UUID().uuidString,
        species: String = "",
        name: String = "",
        image: String = "",
        grCharacterStatus: String = ""
    ) {
        self.characterUUID = characterUUID
        self.species = species
        self.name = name
        self.image = image
        self.grCharacterStatus = grCharacterStatus
    }
}

struct GRPost {
    let characterUUID: String
    var postImage: String
    var postBody: String
    var createdAt: Date
    var updatedAt: Date
    
    init(
        characterUUID: String,
        postImage: String,
        postBody: String,
        createdAt: Date,
        updatedAt: Date
    ){
        self.characterUUID = characterUUID
        self.postImage = postImage
        self.postBody = postBody
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
// --- 여기까지 더미 데이터 ---


class CharacterDetailViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    @Published var character: GRCharacter
    @Published var posts: [GRPost] = []
    
    private var db = Firestore.firestore()
    
    init() {
        self.character = GRCharacter()
    }
    
    func loadCharacter(characterUUID: String) {
        isLoading = true
        errorMessage = nil
        
        db.collection("GRCharacter").document(characterUUID).getDocument{ [weak self] snapshot, error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = "캐릭터 로드 중 에러 발생: \(error.localizedDescription)"
                return
            }
            
            guard let data = snapshot?.data() else {
                self.errorMessage = "캐릭터 데이터를 찾을 수 없습니다."
                return
            }
            
            self.character = GRCharacter(
                characterUUID: characterUUID,
                species: data["species"] as? String ?? "",
                name: data["name"] as? String ?? "",
                image: data["image"] as? String ?? "",
                grCharacterStatus: data["GRCharacterStatus"] as? String ?? ""
            )
        }
    }
    
    func loadPost(characterUUID: String, searchDate: Date) {
        isLoading = true
        errorMessage = nil
        
        let calendar = Calendar.current
        let month = calendar.component(.month, from: searchDate)
        let year = calendar.component(.year, from: searchDate)
        
        fetchPostsFromFirebase(year: year, month: month)
        
        
    }
    
    func fetchPostsFromFirebase(year: Int, month: Int) {
        isLoading = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = 1
        dateComponents.hour = 0
        dateComponents.minute = 0
        dateComponents.second = 0
        
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(from: dateComponents) else {
            self.isLoading = false
            self.errorMessage = "시작 날짜 계산 중 오류."
            return
        }
        guard let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            self.isLoading = false
            self.errorMessage = "종료 날짜 계산 중 오류."
            return
        }
        
        var fefetchedPosts: [GRPost] = []
        
        db.collection("GRPost")
            .whereField("updatedAt", isGreaterThanOrEqualTo: startOfMonth)
            .whereField("updatedAt", isLessThanOrEqualTo: endOfMonth)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching posts: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                for document in documents {
                    let data = document.data()
                    let characterUUID = data["characterUUID"] as? String ?? ""
                    let postImage = data["postImage"] as? String ?? ""
                    let postBody = data["postBody"] as? String ?? ""
                    let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
                    
                    let post = GRPost(
                        characterUUID: characterUUID,
                        postImage: postImage,
                        postBody: postBody,
                        createdAt: createdAt,
                        updatedAt: updatedAt
                    )
                    fefetchedPosts.append(post)
                }
                self.posts = fefetchedPosts
            }
    }
    
} // end of class
