//
//  WriteStoryViewModel.swift
//  Grruung
//
//  Created by NO SEONGGYEONG on 5/7/25.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseStorage


class WriteStoryViewModel: ObservableObject {
    @Published var posts: [GRPost] = []
    
    
    private var db = Firestore.firestore()
    private var storage = Storage.storage() // Firebase Storage (이미지 업로드용)
    
    init() {
        
//#if DEBUG
//        // Firebase Emulator 설정
//        let settings = Firestore.firestore().settings
//        settings.host = "localhost:8080" // Firestore emulator 기본 포트
//        settings.isPersistenceEnabled = false
//        settings.isSSLEnabled = false
//        db.settings = settings
//        
//        // Storage Emulator 설정
//        Storage.storage().useEmulator(withHost: "localhost", port: 9199) // Storage emulator 기본 포트
//#endif
    }
    
    func createPost(characterUUID: String, postBody: String, imageData: Data?) async throws -> String {
        
        var imageUrlToSave: String = ""
        if let data = imageData {
            // TODO: 이미지 업로드 로직 (임시로 구현 했으므로 실제 구현 필요!!!)
            print("이미지 데이터 \(data.count) 바이트를 업로드 해야 합니다.")
            imageUrlToSave = "https://firebasestore.googleapis.com/v0/b/grruung.appspot.com/o/your_image_name.jpg?alt=media&token=your_token"
        }
        
        let newPostData: [String: Any] = [
            "characterUUID": characterUUID,
            "postImage": imageUrlToSave,
            "postBody": postBody,
            "createdAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date())
        ]
        
        do {
            let documentReference = try await db.collection("GRPost").addDocument(data: newPostData)
            print("Post created with ID: \(documentReference.documentID)")
            return documentReference.documentID
        } catch {
            throw error
        }
    }
    
    func editPost(postID: String, postBody: String, newImageData: Data?, existingImageUrl: String?) async throws {
        
        var imageUrlToSave = existingImageUrl ?? ""
        if let data = newImageData {
            print("새 이미지 데이터 \(data.count) 바이트를 업로드 해야 합니다.")
            imageUrlToSave = "https://firebasestore.googleapis.com/v0/b/grruung.appspot.com/o/your_image_name.jpg?alt=media&token=your_token"
        }
        
        do {
            try await db.collection("GRPost").document(postID).updateData([
                "postImage": imageUrlToSave,
                "postBody": postBody,
                "updatedAt": Timestamp(date: Date())
            ])
            print("Post updated with ID: \(postID)")
        } catch {
            throw error
        }
    }
    
    func deletePost(postID: String) async throws {
        do {
            try await db.collection("GRPost").document(postID).delete()
        } catch {
            throw error
        }
    }
    
    func findPost(postID: String) async throws -> GRPost? {
        do {
            let document = try await db.collection("GRPost").document(postID).getDocument()
            
            guard let data = document.data() else {
                print("Document with ID \(postID) does not exist or has no data.")
                return nil
            }
            print("Post found with ID: \(postID)")
            return GRPost(
                postID: document.documentID,
                characterUUID: data["characterUUID"] as? String ?? "",
                postTitle: data["postTitle"] as? String ?? "",
                postBody: data["postBody"] as? String ?? "",
                postImage: data["postImage"] as? String ?? ""
            )
        } catch {
            throw error
        }
    }
}
