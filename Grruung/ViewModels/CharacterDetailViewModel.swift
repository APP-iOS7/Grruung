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
#if DEBUG
        // Firebase Emulator 설정
        let settings = Firestore.firestore().settings
        settings.host = "localhost:8080" // Firestore emulator 기본 포트
        settings.isPersistenceEnabled = false
        settings.isSSLEnabled = false
        db.settings = settings
        
        // Storage Emulator 설정
        Storage.storage().useEmulator(withHost: "localhost", port: 9199) // Storage emulator 기본 포트
#endif
        
        self.character = GRCharacter()
        
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
                    let postImage = data["postImage"] as? String ?? ""
                    let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
                    
                    return GRPost(
                        postID: documentID,
                        characterUUID: postCharacterUUID,
                        postImage: postImage,
                        postBody: data["postBody"] as? String ?? "",
                        createdAt: createdAt,
                        updatedAt: updatedAt
                    )
                }
                
                print("Updated self.posts with \(self.posts.count) posts.")
            }
    }
    
} // end of class
