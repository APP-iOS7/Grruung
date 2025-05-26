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
    @Published var animationInProgress: Bool = false // 애니메이션 진행 상태
    
    // 스탯 관련
    @Published var satietyValue: Int = 50 // 포만감
    @Published var satietyPercent: CGFloat = 0.5
    
    @Published var energyValue: Int = 50 // 에너지
    @Published var energyPercent: CGFloat = 0.5
    
    @Published var happinessValue: Int = 50 // 행복도
    @Published var happinessPercent: CGFloat = 0.5
    
    @Published var cleanValue: Int = 50 // 청결도
    @Published var cleanPercent: CGFloat = 0.5
    
    @Published var activityValue: Int = 50 // 활동량 (6분마다 1씩 회복)
    @Published var activityPercent: CGFloat = 0.5
    
    @Published var healthyValue: Int = 50 // 건강도 (히든 스탯)
    @Published var healthyPercent: CGFloat = 0.5
    
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
    
    // 액션 관리자
    private let actionManager = ActionManager.shared
    
    // MARK: TODO.2 - 성장 단계에 따른 경험치 요구량을 업데이트
    // 성장 단계별 경험치 요구량
    private let phaseExpRequirements: [CharacterPhase: Int] = [
        .egg: 50,
        .infant: 100,
        .child: 150,
        .adolescent: 200,
        .adult: 300,
        .elder: 500
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
            healthyValue = character.status.healthy
            activityValue = character.status.activity
        }
        
        updateAllPercents()
    }
    
    // MARK: TODO.8 - 성장 단계별 기능 해금
    private func unlockFeaturesByPhase(_ phase: CharacterPhase) {
        switch phase {
        case .egg:
            // 알 단계에서는 제한된 기능만 사용 가능
            sideButtons[3].unlocked = false // 일기
            sideButtons[4].unlocked = false // 채팅
            
        case .infant:
            // 유아기에서는 일기 기능 해금
            sideButtons[3].unlocked = true // 일기
            sideButtons[4].unlocked = false // 채팅
            
        case .child:
            // 소아기에서는 채팅 기능 해금
            sideButtons[3].unlocked = true // 일기
            sideButtons[4].unlocked = true // 채팅
            
        case .adolescent, .adult, .elder:
            // 청년기 이상에서는 모든 기능 해금
            sideButtons[3].unlocked = true // 일기
            sideButtons[4].unlocked = true // 채팅
        }
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
    
    // MARK: - 액션 관련 관리
    
    // 액션 버튼을 현재 상태에 맞게 갱신
    private func refreshActionButtons() {
        guard let character = character else { return }
        
        // ActionManager를 통해 현재 상황에 맞는 액션 버튼 가져오기
        let buttons = actionManager.getActionsButtons(
            phase: character.status.phase,
            isSleeping: isSleeping
        )
        
        // UI 표시용 actionButtons 업데이트
        actionButtons = buttons.map { button in
            (icon: button.icon, unlocked: button.unlocked, name: button.name)
        }
    }
    
    // MARK: - 경험치 및 레벨업 관리
    
    // 경험치를 추가하고 레벨업을 체크합니다.
    // - Parameter amount: 추가할 경험치량
    private func addExp(_ amount: Int) {
        // 성장 단계에 따른 경험치 보너스 적용
        var adjustedAmount = amount
        
        if let character = character, character.status.phase == .egg {
            // 운석(알) 상태에서는 경험치 5배로 획득
            adjustedAmount *= 5
        }
        
        expValue += adjustedAmount
        
        // 레벨업 체크
        if expValue >= expMaxValue {
            levelUp()
        } else {
            // 레벨업이 아닌 경우에도 퍼센트 업데이트 및 캐릭터 동기화
            expPercent = CGFloat(expValue) / CGFloat(expMaxValue)
            updateCharacterStatus()
        }
    }
    
    // 레벨업 처리
    private func levelUp() {
        level += 1
        expValue -= expMaxValue
        
        // 새로운 성장 단계 결정
        let oldPhase = character?.status.phase
        updateGrowthPhase()
        
        // 새 경험치 요구량 설정
        updateExpRequirement()
        
        // 퍼센트 업데이트
        expPercent = CGFloat(expValue) / CGFloat(expMaxValue)
        
        // 레벨업 보너스 지급
        applyLevelUpBonus()
        
        // 성장 단계가 변경 되었으면 기능 해금
        if oldPhase != character?.status.phase {
            unlockFeaturesByPhase(character?.status.phase ?? .egg)
            // 액션 버튼 갱신
            refreshActionButtons()
        }
        
        // 캐릭터 상태 업데이트
        updateCharacterStatus()
        
        // 레벨업 메시지
        if oldPhase != character?.status.phase {
            statusMessage = "축하합니다! \(character?.status.phase.rawValue ?? "")로 성장했어요!"
        } else {
            statusMessage = "레벨 업! 이제 레벨 \(level)입니다!"
        }
    }
    
    
    // 현재 레벨에 맞는 성장 단계를 업데이트
    private func updateGrowthPhase() {
        guard var character = character else { return }
        
        // 레벨에 따른 성장 단계 결정
        switch level {
        case 0:
            character.status.phase = .egg
        case 1...2:
            character.status.phase = .infant
        case 3...5:
            character.status.phase = .child
        case 6...8:
            character.status.phase = .adolescent
        case 9...15:
            character.status.phase = .adult
        default:
            character.status.phase = .elder
        }
        
        self.character = character
    }
    
    // MARK: TODO.2 - 성장 단계에 따른 경험치 요구량을 업데이트
    private func updateExpRequirement() {
        guard let character = character else { return }
        
        // 성장 단계에 맞는 경험치 요구량 설정
        if let requirement = phaseExpRequirements[character.status.phase] {
            expMaxValue = requirement
        } else {
            // 기본값 (성장 단계를 찾지 못했을 경우)
            expMaxValue = 100 + (level * 50)
        }
    }
    
    // 레벨업 시 보너스 적용
    private func applyLevelUpBonus() {
        // 레벨 업 시 모든 스텟 20% 회복
        satietyValue = min(100, satietyValue + 20)
        energyValue = min(100, energyValue + 20)
        activityValue = min(100, activityValue + 20)
        
        // 업데이트
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
