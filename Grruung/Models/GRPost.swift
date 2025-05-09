//
//  GRPost.swift
//  Grruung
//
//  Created by KimJunsoo on 5/7/25.
//

import Foundation

// 캐릭터에게 들려준 이야기를 담는 구조체
struct GRPost: Identifiable {
    
    var id: String = UUID().uuidString
    var characterUUID: String
    var postTitle: String
    var postBody: String
    var postImages: [String] // 이미지 URL 또는 경로 배열
    var createdAt: Date
    var updatedAt: Date
    
    init(characterUUID: String,
         postTitle: String,
         postBody: String,
         postImages: [String] = [],
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.characterUUID = characterUUID
        self.postTitle = postTitle
        self.postBody = postBody
        self.postImages = postImages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
