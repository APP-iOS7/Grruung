//
//  GRAnimationMetadata.swift
//  Grruung
//
//  Created by NoelMacMini on 5/12/25.
//

import Foundation
import SwiftData

@Model
class GRAnimationMetadata {
    // 식별 정보
    var characterType: String       // 예: "egg", "quokka"
    var animationType: String       // 예: "eggbasic", "eggbreak"
    var frameIndex: Int             // 예: 1, 2, 3...
    
    // 파일 정보
    var filePath: String            // 저장된 파일 경로
    var fileSize: Int               // 파일 크기 (바이트)
    
    // 상태 정보
    var downloadDate: Date          // 다운로드 날짜
    var lastAccessed: Date          // 마지막 접근 시간
    
    // 관리 정보
    var isDownloaded: Bool          // 다운로드 완료 여부
    
    init(characterType: String, animationType: String, frameIndex: Int, filePath: String, fileSize: Int = 0) {
        self.characterType = characterType
        self.animationType = animationType
        self.frameIndex = frameIndex
        self.filePath = filePath
        self.fileSize = fileSize
        self.downloadDate = Date()
        self.lastAccessed = Date()
        self.isDownloaded = true
    }
}

