//
//  GRPetModels.swift
//  Grruung
//
//  Created by KimJunsoo on 5/7/25.
//

import Foundation

/// 캐릭터의 상태 정보를 담는 구조체
struct GRCharacterStatus {
    
    var level: Int
    var exp: Int
    var expToNextLevel: Int
    var phase: CharacterPhase
    var satiety: Int // 포만감
    var stamina: Int // 체력
    var activity: Int // 운동량/활동량
    var affection: Int // 애정도
    var healthy: Int // 건강
    var clean: Int // 청결
    var address: String // 거주지
    var birthDate: Date // 생일
    var appearance: [String: String] // 외모 (성장 이후 바뀔 수 있음)
    
    init(level: Int = 1,
         exp: Int = 0,
         expToNextLevel: Int = 100,
         phase: CharacterPhase = .egg,
         satiety: Int = 50,
         stamina: Int = 50,
         activity: Int = 50,
         affection: Int = 50,
         healthy: Int = 50,
         clean: Int = 50,
         address: String = "usersHome",
         birthDate: Date = Date(),
         appearance: [String: String] = [:]) {
        self.level = level
        self.exp = exp
        self.expToNextLevel = expToNextLevel
        self.phase = phase
        self.satiety = satiety
        self.stamina = stamina
        self.activity = activity
        self.affection = affection
        self.healthy = healthy
        self.clean = clean
        self.address = address
        self.birthDate = birthDate
        self.appearance = appearance
    }
    
    // 캐릭터 성장 단계를 업데이트합니다.
    mutating func updatePhase() {
        switch level {
        case 0:
            phase = .egg
        case 1...2:
            phase = .infant
        case 3...5:
            phase = .child
        case 6...8:
            phase = .adolescent
        case 9...15:
            phase = .adult
        default:
            phase = .elder
        }
    }
    
    // 레벨업 시 호출되는 메서드
    mutating func levelUp() {
        level += 1
        exp = 0
        expToNextLevel = calculateNextLevelExp()
        updatePhase()
    }
    
    // 다음 레벨까지 필요한 경험치 계산
    private func calculateNextLevelExp() -> Int {
        return 100 + (level * 50) // 레벨이 올라갈수록 필요한 경험치 증가
    }
    
    // 상태 텍스트 반환
    func getStatusDescription() -> String {
        var status = ""
        
        if satiety < 30 {
            status += "배고픔 "
        }
        
        if stamina < 30 {
            status += "피곤함 "
        }
        
        if clean < 30 {
            status += "지저분함 "
        }
        
        if healthy < 30 {
            status += "아픔 "
        }
        
        if affection < 30 {
            status += "외로움 "
        }
        
        if status.isEmpty {
            status = "행복함"
        }
        
        return status.trimmingCharacters(in: .whitespaces)
    }
}

// 펫 성장 단계
enum CharacterPhase: String, Codable {
    case egg = "알"
    case infant = "유아기"
    case child = "소아기"
    case adolescent = "청년기"
    case adult = "성년기"
    case elder = "노년기"
}
