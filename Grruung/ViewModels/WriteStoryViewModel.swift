//
//  WriteStoryViewModel.swift
//  Grruung
//
//  Created by NO SEONGGYEONG on 5/7/25.
//

import Foundation
import Combine
import FirebaseFirestore


// 더미 데이터
struct GRPost {
    let characterUUID: String
    var postImage: String
    var postBody: String
    var createdAt: Date
    var updatedAt: Date
    let postID: String?
    
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
        self.postID = nil
    }
}
// 더미 데이터 끝

class WriteStoryViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    @Published var posts: [GRPost] = []
    
    
    private var db = Firestore.firestore()
    
    init() {
        
    }
    
    func createPost(characterUUID: String, postImage: String, postBody: String) async throws {
        let newPost = GRPost(
            characterUUID: characterUUID,
            postImage: postImage,
            postBody: postBody,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            try await db.collection("posts").addDocument(data: [
                "characterUUID": newPost.characterUUID,
                "postImage": newPost.postImage,
                "postBody": newPost.postBody,
                "createdAt": Timestamp(date: newPost.createdAt),
                "updatedAt": Timestamp(date: newPost.updatedAt)
            ])
        } catch {
            throw error
        }
    }
    
    func editPost(postID: String, postImage: String, postBody: String) async throws {
        do {
            try await db.collection("posts").document(postID).updateData([
                "postImage": postImage,
                "postBody": postBody,
                "updatedAt": Timestamp(date: Date())
            ])
        } catch {
            throw error
        }
    }
   
    func deletePost(postID: String) async throws {
        do {
            try await db.collection("posts").document(postID).delete()
        } catch {
            throw error
        }
    }
}
