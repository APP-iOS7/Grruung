//
//  GRPetModels.swift
//  Grruung
//
//  Created by KimJunsoo on 5/7/25.
//

import Foundation


// 펫 종류
enum PetSpecies: String, Codable, CaseIterable {
    case liger = "고양이사자"
    case quokka = "쿼카"
}

// 펫 성장 단계
enum PetPhase: String, Codable, CaseIterable {
    case egg = "운석"
    case infant = "유아기"
    case child = "소아기"
    case adolescent = "청년기"
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
            return .adolescent
        case 9...15:
            return .adult
        default:
            return .senior
        }
    }
}

// 펫의 상태를 관리하는 모델
struct PetStatus: Codable {
    var level: Int = 1
    var exp: Int = 0
    var expToNextLevel: Int = 100
    var phase: PetPhase = .infant
    var satiety: Int = 50       // 포만감
    var stamina: Int = 50       // 체력
    var activity: Int = 50      // 운동량/활동량
    var affection: Int = 50     // 애정도
    var health: Int = 100       // 건강
    var cleanliness: Int = 100  // 청결
    var address: String = "사용자의 기기"
    var birthDate: Date = Date()
    
    // 현재 나이 계산 (일 단위)
    var ageInDays: Int {
        return Calendar.current.dateComponents([.day], from: birthDate, to: Date()).day ?? 0
    }
    
    // 상태 설명 생성
    func getStatusDescription() -> String {
        var description = ""
        
        if satiety < 30 {
            description += "배고파 보이는 "
        } else if satiety > 80 {
            description += "배부른 "
        }
        
        if stamina < 30 {
            description += "지쳐 보이는 "
        } else if stamina > 80 {
            description += "활기찬 "
        }
        
        if cleanliness < 30 {
            description += "지저분한 "
        } else if cleanliness > 80 {
            description += "깨끗한 "
        }
        
        if health < 30 {
            description += "아픈 "
        } else if health > 80 {
            description += "건강한 "
        }
        
        return description.isEmpty ? "평범한" : description.trimmingCharacters(in: .whitespaces)
    }
}

struct GRPet: Identifiable, Codable {
    var id: String = UUID().uuidString
    var species: PetSpecies
    var name: String
    var status: PetStatus
    var createdAt: Date = Date()
    
    static func createTestPet(species: PetSpecies, name: String, phase: PetPhase) -> GRPet {
        var pet = GRPet(species: species, name: name, status: PetStatus())
        
        // 설정된 성장 단계에 맞게 레벨 조정
        switch phase {
        case .egg:
            pet.status.level = 0
        case .infant:
            pet.status.level = 1
        case .child:
            pet.status.level = 3
        case .adolescent:
            pet.status.level = 6
        case .adult:
            pet.status.level = 9
        case .senior:
            pet.status.level = 16
        }
        
        pet.status.phase = phase
        return pet
    }
}
