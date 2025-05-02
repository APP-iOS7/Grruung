//
//  AIModel.swift
//  Grruung
//
//  Created by NoelMacMini on 5/2/25.
//

import Foundation

struct ChatMessage: Identifiable {
    let id = UUID() // 각 메시지를 고유하게 식별하기 위한 ID
    let content: String // 메시지 내용
    let isUser: Bool // true면 사용자, false면 AI
}
