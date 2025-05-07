//
//  ChatModels.swift
//  Grruung
//
//  Created by KimJunsoo on 5/7/25.
//

import Foundation

// MARK: - 0. 메시지 송신자 유형
enum MessageSender: String, Codable {
    case user = "사용자"
    case pet = "펫"
}

// MARK: - 1. 채팅 메시지 구조체
struct ChatMessage: Identifiable, Codable {
    var id: String = UUID().uuidString
    var content: String
    var sender: MessageSender
    var timestamp: Date = Date()
    var isAudioMessage: Bool = false
    
    // MARK: - 2. 테스트용 메시지 생성 함수
    static func sampleMessage() -> [ChatMessage] {
        return [
            ChatMessage(content: "안녕! 오늘 기분이 어때?", sender: .user),
            ChatMessage(content: "냥냥! 오늘은 정말 행복해요~ 주인님과 놀 수 있어서 기뻐요!", sender: .pet),
            ChatMessage(content: "배고파?", sender: .user),
            ChatMessage(content: "냥! 조금 배고파요. 간식 주실래요?", sender: .pet)
        ]
    }
}

// MARK: - 3. 채팅 대화 관리 구조체
struct ChatConversation: Identifiable, Codable {
    var id: String = UUID().uuidString
    var petId: String
    var messages: [ChatMessage] = []
    var lastUpdated: Date = Date()
}
