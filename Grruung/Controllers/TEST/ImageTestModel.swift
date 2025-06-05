//
//  ImageTestModel.swift
//  Grruung
//
//  Created by NoelMacMini on 6/2/25.
//

import Foundation
import SwiftData

// SwiftData 모델에 Identifiable 프로토콜 명시적 추가
@Model
class ImageTestModel: Identifiable {
    // SwiftData는 자동으로 id를 관리하므로 수동 UUID 제거
    var characterType: String
    var phaseType: String
    var animationType: String
    var frameIndex: Int
    var filePath: String
    var isDownloaded: Bool
    var createdAt: Date
    
    // 초기화 메서드 - UUID 제거
    init(characterType: String,
         phaseType: String,
         animationType: String,
         frameIndex: Int,
         filePath: String,
         isDownloaded: Bool = false) {
        
        // self.id = UUID() 제거 - SwiftData가 자동 관리
        self.characterType = characterType
        self.phaseType = phaseType
        self.animationType = animationType
        self.frameIndex = frameIndex
        self.filePath = filePath
        self.isDownloaded = isDownloaded
        self.createdAt = Date()
    }
}
