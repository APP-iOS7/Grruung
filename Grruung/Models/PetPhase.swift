//
//  PetPhase.swift
//  Grruung
//
//  Created by KimJunsoo on 5/6/25.
//

import Foundation

// 펫 성장 단계
enum PetPhase: String, Codable, CaseIterable {
    case egg = "운석"
    case infant = "유아기"
    case child = "소아기"
    case teenage = "청년기"
    case adult = "성년기"
    case senior = "노년기"
    
    // 레벨에 맞는 성장 단계 설정
    static func phaseForLevel(_ level: Int) -> PetPhase {
        switch level {
        case 0:
            return .egg
        case 1...2:
            return .infant
        case 3...5:
            return .child
        case 6...8:
            return .teenage
        case 9...15:
            return .adult
        default:
            return .senior
        }
    }
}

// 펫 종류
enum PetSpecies: String, Codable, CaseIterable {
    case liger = "고양이사자"
    case quokka = "쿼카"
}
