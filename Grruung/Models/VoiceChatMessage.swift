//
//  VoiceChatMessage.swift
//  Grruung
//
//  Created by KimJunsoo on 5/6/25.
//

import Foundation

struct VoiceChatMessage: Identifiable, Codable {
    let id: String
    let content: String
    let isUser: Bool
    let timestamp: Date
    let audioURL: URL? // 음성 메시지가 있을 경우 저장
}
