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
    }
    
    func createPost(characterUUID: String, postTitle: String, postBody: String, imageData: Data?) async throws -> String {
        
        var imageUrlToSave: String = ""
        
        if let data = imageData {
            // 1. Firebase Storage에 이미지 고유 경로 생성
            let imageName = UUID().uuidString + ".jpg"
            let imageRef = storage.reference().child("post_images/\(imageName)") // "post_images" 폴더에 저장
            
            do {
                // 2. Firebase Storage에 이미지 데이터 업로드
                print("Firebase Storage로 이미지 데이터 (\(data.count) 바이트) 업로드 중 ...")
                let _ = try await imageRef.putDataAsync(data, metadata: nil) // async/await를 위해 putDataAsync 사용
                
                // 3. 다운로드 URL 가져오기
                let downloadURL = try await imageRef.downloadURL()
                imageUrlToSave = downloadURL.absoluteString
                print("Firebase Storage에 이미지 업로드 완료: \(imageUrlToSave)")
            } catch {
                print("Firebase Storage에 이미지 업로드 실패: \(error)")
                throw error
            }
        }
        
        let newPostData: [String: Any] = [
            "characterUUID": characterUUID,
            "postTitle": postTitle,
            "postImage": imageUrlToSave,
            "postBody": postBody,
            "createdAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date())
        ]
        
        do {
            let documentReference = try await db.collection("GRPost").addDocument(data: newPostData)
            print("게시물 생성 완료. ID: \(documentReference.documentID)")
            return documentReference.documentID
        } catch {
            print("게시물 생성 중 오류 발생: \(error)")
            throw error
        }
    }
    
    func editPost(postID: String, postTitle: String, postBody: String, newImageData: Data?, existingImageUrl: String?) async throws {
        
        var imageUrlToSave = existingImageUrl ?? ""
        if let data = newImageData {
            print("새 이미지 데이터 \(data.count) 바이트를 업로드 해야 합니다.")
            imageUrlToSave = "https://firebasestore.googleapis.com/v0/b/grruung.appspot.com/o/your_image_name.jpg?alt=media&token=your_token"
        }
        
        do {
            try await db.collection("GRPost").document(postID).updateData([
                "postTitle": postTitle,
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
