//
//  HomeViewModel.swift
//  Grruung
//
//  Created by KimJunsoo on 5/21/25.
//

import Foundation
import SwiftUI
import Combine

class HomeViewModel: ObservableObject {
    // MARK: - Published 속성
    // 캐릭터 관련
    @Published var character: GRCharacter?
    @Published var statusMessage: String = "안녕하세요!" // 상태 메시지
    
    // 레벨 관련
    @Published var level: Int = 1
    @Published var expValue: Int = 0
    @Published var expMaxValue: Int = 100
    @Published var expPercent: CGFloat = 0.0
    
    // 스탯 관련
    @Published var satietyValue: Int = 50 // 포만감
    @Published var satietyPercent: CGFloat = 0.5
    
    @Published var energyValue: Int = 50 // 에너지
    @Published var energyPercent: CGFloat = 0.5
    
    @Published var happinessValue: Int = 50 // 행복도
    @Published var happinessPercent: CGFloat = 0.5
    
    @Published var cleanValue: Int = 50 // 청결도
    @Published var cleanPercent: CGFloat = 0.5
    
    // 상태 관련
    @Published var isSleeping: Bool = false // 잠자기 상태
    
    // 버튼 관련 (모두 풀려있는 상태)
    @Published var sideButtons: [(icon: String, unlocked: Bool, name: String)] = [
        ("backpack.fill", true, "인벤토리"),
        ("cart.fill", true, "상점"),
        ("mountain.2.fill", true, "동산"),
        ("book.fill", true, "일기"),
        ("microphone.fill", true, "채팅"),
        ("gearshape.fill", true, "설정")
    ]
    
    @Published var actionButtons: [(icon: String, unlocked: Bool, name: String)] = [
        ("fork.knife", true, "밥주기"),
        ("gamecontroller.fill", true, "놀아주기"),
        ("shower.fill", true, "씻기기"),
        ("bed.double", true, "재우기")
    ]
    
    // 스탯 표시 형식
    @Published var stats: [(icon: String, color: Color, value: CGFloat)] = [
        ("fork.knife", Color.orange, 0.5),
        ("heart.fill", Color.red, 0.5),
        ("bolt.fill", Color.yellow, 0.5)
    ]
    
    // MARK: - 초기화
    init() {
        loadCharacter()
        updateAllPercents()
    }
    
    // MARK: - 데이터 로드
    func loadCharacter() {
        // 실제로는 Firestore나 Firebase에서 캐릭터 정보를 로드
        // 지금은 더미 데이터 생성
        let status = GRCharacterStatus(
            level: 1,
            exp: 0,
            expToNextLevel: 100,
            phase: .infant,
            satiety: 50,
            stamina: 50,
            activity: 50,
            affection: 50,
            healthy: 50,
            clean: 50
        )
        
        character = GRCharacter(
            species: .CatLion,
            name: "냥냥이",
            imageName: "CatLion",
            birthDate: Date(),
            createdAt: Date(),
            status: status
        )
        
        if let character = character {
            level = character.status.level
            expValue = character.status.exp
            expMaxValue = character.status.expToNextLevel
            
            satietyValue = character.status.satiety
            energyValue = character.status.stamina
            happinessValue = character.status.affection
            cleanValue = character.status.clean
        }
        
        updateAllPercents()
    }
    
    // MARK: - 내부 메서드
    private func updateAllPercents() {
        // 스탯 퍼센트 업데이트
        satietyPercent = CGFloat(satietyValue) / 100.0
        energyPercent = CGFloat(energyValue) / 100.0
        happinessPercent = CGFloat(happinessValue) / 100.0
        cleanPercent = CGFloat(cleanValue) / 100.0
        expPercent = CGFloat(expValue) / CGFloat(expMaxValue)
        
        // 스탯 배열 업데이트 (UI 표시용)
        stats = [
            ("fork.knife", Color.orange, satietyPercent),
            ("heart.fill", Color.red, happinessPercent),
            ("bolt.fill", Color.yellow, energyPercent)
        ]
        
        updateStatusMessage()
    }
    
    private func updateStatusMessage() {
        if isSleeping {
            statusMessage = "쿨쿨... 잠을 자고 있어요."
            return
        }
        
        if satietyValue < 30 {
            statusMessage = "배고파요... 밥 주세요!"
        } else if energyValue < 30 {
            statusMessage = "너무 피곤해요... 쉬고 싶어요."
        } else if happinessValue < 30 {
            statusMessage = "심심해요... 놀아주세요!"
        } else if cleanValue < 30 {
            statusMessage = "더러워요... 씻겨주세요!"
        } else if satietyValue > 80 && energyValue > 80 && happinessValue > 80 {
            statusMessage = "정말 행복해요! 감사합니다!"
        } else {
            statusMessage = "오늘도 좋은 하루에요!"
        }
    }
    
    private func addExp(_ amount: Int) {
        expValue += amount
        if expValue >= expMaxValue {
            // 레벨업 처리
            level += 1
            expValue = expValue - expMaxValue
            expMaxValue += 50 // 다음 레벨은 더 많은 경험치 필요
            
            // 레벨업 시 캐릭터 상태 업데이트
            if let character = character {
                var updatedStatus = character.status
                updatedStatus.level = level
                updatedStatus.exp = expValue
                updatedStatus.expToNextLevel = expMaxValue
                
                // 레벨업 시 스탯 보너스
                updatedStatus.satiety = min(100, updatedStatus.satiety + 10)
                updatedStatus.stamina = min(100, updatedStatus.stamina + 10)
                updatedStatus.affection = min(100, updatedStatus.affection + 10)
                updatedStatus.healthy = min(100, updatedStatus.healthy + 10)
                updatedStatus.clean = min(100, updatedStatus.clean + 10)
                
                // 캐릭터 업데이트
                self.character?.status = updatedStatus
                
                // UI 값 업데이트
                satietyValue = updatedStatus.satiety
                energyValue = updatedStatus.stamina
                happinessValue = updatedStatus.affection
                cleanValue = updatedStatus.clean
            }
        }
        updateAllPercents()
    }
    
    // MARK: - 액션 메서드
    
    // 1. 밥주기
    func feedPet() {
        guard !isSleeping else { return }
        
        satietyValue = min(100, satietyValue + 15)
        energyValue = min(100, energyValue + 5)
        happinessValue = min(100, happinessValue + 3)
        
        addExp(3)
        updateAllPercents()
        
        // 캐릭터 모델 업데이트
        updateCharacterStatus()
    }
    
    // 2. 놀아주기
    func playWithPet() {
        guard !isSleeping else { return }
        
        happinessValue = min(100, happinessValue + 12)
        energyValue = max(0, energyValue - 8)
        satietyValue = max(0, satietyValue - 5)
        
        addExp(5)
        updateAllPercents()
        
        // 캐릭터 모델 업데이트
        updateCharacterStatus()
    }
    
    // 3. 씻기기
    func washPet() {
        guard !isSleeping else { return }
        
        cleanValue = min(100, cleanValue + 15)
        happinessValue = min(100, happinessValue + 5)
        energyValue = max(0, energyValue - 3)
        
        addExp(4)
        updateAllPercents()
        
        // 캐릭터 모델 업데이트
        updateCharacterStatus()
    }
    
    // 4. 재우기/깨우기
    func putPetToSleep() {
        if isSleeping {
            // 이미 자고 있으면 깨우기
            isSleeping = false
            updateStatusMessage()
        } else {
            // 자고 있지 않으면 재우기
            isSleeping = true
            energyValue = min(100, energyValue + 20)
            updateAllPercents()
        }
        
        // 캐릭터 모델 업데이트
        updateCharacterStatus()
    }
    
    // 캐릭터 모델 업데이트
    private func updateCharacterStatus() {
        guard var character = character else { return }
        
        // 캐릭터 상태 업데이트
        character.status.satiety = satietyValue
        character.status.stamina = energyValue
        character.status.affection = happinessValue
        character.status.clean = cleanValue
        character.status.exp = expValue
        character.status.expToNextLevel = expMaxValue
        character.status.level = level
        
        // 캐릭터 업데이트
        self.character = character
        
        // 실제 앱에서는 여기서 Firestore에 저장
        // saveCharacterToFirestore()
    }
}
