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
    
    @Published var staminaValue: Int = 50 // 체력
    @Published var staminaPercent: CGFloat = 0.5
    
    @Published var activityValue: Int = 50 // 활동량 (6분마다 1씩 회복)
    @Published var activityPercent: CGFloat = 0.5
    
    @Published var happinessValue: Int = 50 // 행복도
    @Published var happinessPercent: CGFloat = 0.5
    
    @Published var cleanValue: Int = 50 // 청결도
    @Published var cleanPercent: CGFloat = 0.5
    
    @Published var healthyValue: Int = 50 // 건강도 (히든 스탯)
    @Published var healthyPercent: CGFloat = 0.5
    
    // 상태 관련
    @Published var isSleeping: Bool = false // 잠자기 상태
    
    @Published var energyTimer: Timer? // 에너지 증가 타이머
    @Published var lastUpdateTime: Date = Date()
    @Published var cancellables = Set<AnyCancellable>()
    
    private var statDecreaseTimer: Timer?      // 보이는 스탯 감소용
    private var hiddenStatDecreaseTimer: Timer? // 히든 스탯 감소용
    private var dailyAffectionTimer: Timer?    // 일일 애정도 체크용
    private var lastActivityDate: Date = Date() // 마지막 활동 날짜
    
    // FIXME: 디버그 모드 설정 추가
#if DEBUG
    private let isDebugMode = true
    private let debugSpeedMultiplier = 5 // 디버그 시 5배 빠르게/많이
#else
    private let isDebugMode = false
    private let debugSpeedMultiplier = 1
#endif
    
    private var energyTimerInterval: TimeInterval {
#if DEBUG
        return 10.0 // 디버그: 10초마다
#else
        return 360.0 // 릴리즈: 6분마다
#endif
    }
    
    private var statDecreaseInterval: TimeInterval {
#if DEBUG
        return 20.0 // 디버그: 20초마다
#else
        return 600.0 // 릴리즈: 10분마다
#endif
    }
    
    private var hiddenStatDecreaseInterval: TimeInterval {
#if DEBUG
        return 60.0 // 디버그: 1분마다
#else
        return 1800.0 // 릴리즈: 30분마다
#endif
    }
    
    private var dailyAffectionInterval: TimeInterval {
#if DEBUG
        return 120.0 // 디버그: 2분마다
#else
        return 3600.0 // 릴리즈: 1시간마다
#endif
    }
    
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
    @Published var stats: [(icon: String, iconColor: Color, color: Color, value: CGFloat)] = [
        ("fork.knife", Color.orange, Color.orange, 0.5),
        ("heart.fill", Color.red, Color.red, 0.5),
        ("bolt.fill", Color.yellow, Color.yellow, 0.5)
    ]
    
    // 스탯 값에 따라 색상을 반환하는 유틸 함수
    private func colorForValue(_ value: Int) -> Color {
        switch value {
        case 0...20:
            return .red
        case 21...79:
            return .green
        case 80...100:
            return .blue
        default:
            return .gray
        }
    }
    
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
        startEnergyTimer()
        setupAppStateObservers()
        startStatDecreaseTimers()
#if DEBUG
        print("🚀 디버그 모드 활성화!")
        print("   - 타이머 속도: \(debugSpeedMultiplier)배 빠르게")
        print("   - 스탯 변화: \(debugSpeedMultiplier)배")
        print("   - 경험치 획득: \(debugSpeedMultiplier)배")
        print("   - 에너지 회복: \(energyTimerInterval)초마다")
        print("   - 스탯 감소: \(statDecreaseInterval)초마다")
#endif
    }
    
    deinit {
        stopEnergyTimer()
        cancellables.removeAll()
        
        statDecreaseTimer?.invalidate()
        hiddenStatDecreaseTimer?.invalidate()
        dailyAffectionTimer?.invalidate()
        
        print("⏰ 모든 타이머 정리됨")
    }
    
    // MARK: - 데이터 로드
    func loadCharacter() {
        // 실제로는 Firestore나 Firebase에서 캐릭터 정보를 로드
        // 지금은 더미 데이터 생성
        let status = GRCharacterStatus(
            level: 0,
            exp: 0,
            expToNextLevel: 100,
            phase: .egg,
            satiety: 100,
            stamina: 100,
            activity: 100,
            
            affection: 100,
            healthy: 100,
            clean: 100
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
            staminaValue = character.status.stamina
            happinessValue = character.status.affection
            cleanValue = character.status.clean
            healthyValue = character.status.healthy
            activityValue = character.status.activity
            
            // 성장 단계에 맞는 기능 해금
            unlockFeaturesByPhase(character.status.phase)
        }
        
        updateAllPercents()
        
        // 캐릭터 로드 후 액션 버튼 갱신
        refreshActionButtons()
    }
    
    // MARK: - 타이머 관련 메서드
    private func startStatDecreaseTimers() {
        // 보이는 스탯 감소 (10분마다)
        statDecreaseTimer = Timer.scheduledTimer(withTimeInterval: statDecreaseInterval, repeats: true) { [weak self] _ in
            self?.decreaseVisibleStats()
        }
        
        // 히든 스탯 감소 (30분마다)
        hiddenStatDecreaseTimer = Timer.scheduledTimer(withTimeInterval: hiddenStatDecreaseInterval, repeats: true) { [weak self] _ in
            self?.decreaseHiddenStats()
        }
        
        // 일일 애정도 체크 (1시간마다)
        dailyAffectionTimer = Timer.scheduledTimer(withTimeInterval: dailyAffectionInterval, repeats: true) { [weak self] _ in
            self?.checkDailyAffection()
        }
        
#if DEBUG
        print("⏰ 디버그 모드: 자동 감소 타이머들 시작됨")
        print("   - 보이는 스탯 감소: \(statDecreaseInterval)초마다")
        print("   - 히든 스탯 감소: \(hiddenStatDecreaseInterval)초마다")
        print("   - 일일 애정도 체크: \(dailyAffectionInterval)초마다")
#endif
    }
    
    // 보이는 스탯 감소 (포만감, 활동량)
    private func decreaseVisibleStats() {
        // 잠자는 중에는 감소 속도 절반
        let baseDecreaseAmount = isSleeping ? 1 : 2
        // 디버그 모드에서는 배수 적용
        let finalDecreaseAmount = isDebugMode ? (baseDecreaseAmount * debugSpeedMultiplier) : baseDecreaseAmount
        
        // 포만감 감소
        satietyValue = max(0, satietyValue - finalDecreaseAmount)
        
        // 운동량 감소 (피로 누적)
            if !isSleeping {
                let staminaDecrease = isDebugMode ? debugSpeedMultiplier : 1
                staminaValue = max(0, staminaValue - staminaDecrease)
            }
        
        updateAllPercents()
        updateCharacterStatus()
        
#if DEBUG
        print("📉 디버그 모드 스탯 감소: 포만감 -\(finalDecreaseAmount)" + (isSleeping ? "" : ", 운동량 -\(isDebugMode ? debugSpeedMultiplier : 1)"))
#else
        print("📉 보이는 스탯 감소 - 포만감: -\(finalDecreaseAmount)" + (isSleeping ? "" : ", 운동량: -1"))
#endif
    }
    
    // 히든 스탯 감소 (건강, 청결)
    private func decreaseHiddenStats() {
        // 디버그 모드에서는 배수로 감소
        let healthDecrease = isDebugMode ? debugSpeedMultiplier : 1
        let cleanDecrease = isDebugMode ? (2 * debugSpeedMultiplier) : 2
        
        // 건강도 서서히 감소
        healthyValue = max(0, healthyValue - healthDecrease)
        
        // 청결도 서서히 감소
        cleanValue = max(0, cleanValue - cleanDecrease)
        
        updateAllPercents()
        updateCharacterStatus()
        
#if DEBUG
        print("🔍 디버그 모드 히든 스탯 감소: 건강 -\(healthDecrease), 청결 -\(cleanDecrease)")
#else
        print("🔍 히든 스탯 감소 - 건강: -\(healthDecrease), 청결: -\(cleanDecrease)")
#endif
        
        // 상태가 너무 나빠지면 경고 메시지
        //if healthyValue < 30 || cleanValue < 30 {
        //    statusMessage = "건강이나 청결 상태가 좋지 않아요..."
        //}
    }
    
    // 일일 애정도 체크 (06시 기준, 활동 없으면 감소)
    private func checkDailyAffection() {
        let currentDate = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentDate)
        
        // 디버그 모드에서는 시간 체크 없이 바로 실행
        let shouldCheck = isDebugMode ? true : (hour == 6)
        
        if shouldCheck {
            let daysSinceLastActivity = calendar.dateComponents([.day], from: lastActivityDate, to: currentDate).day ?? 0
            let adjustedDays = isDebugMode ? max(1, daysSinceLastActivity) : daysSinceLastActivity // 디버그에서는 최소 1일로 처리
            
            if adjustedDays >= 1 {
                let baseDecrease = min(10, adjustedDays * 5)
                let finalDecrease = isDebugMode ? (baseDecrease * debugSpeedMultiplier) : baseDecrease
                happinessValue = max(0, happinessValue - finalDecrease)
                
                updateAllPercents()
                updateCharacterStatus()
                
                statusMessage = "오랫동안 관심을 받지 못해서 외로워해요..."
                
#if DEBUG
                print("💔 디버그 모드 일일 애정도 감소: -\(finalDecrease)")
#else
                print("💔 일일 애정도 감소 -\(finalDecrease) (활동 없이 \(adjustedDays)일 경과)")
#endif
            }
        }
    }
    
    // 활동 날짜 업데이트 메서드 추가
    private func updateLastActivityDate() {
        lastActivityDate = Date()
        print("📅 마지막 활동 날짜 업데이트")
    }
    
    // 타이머 설정
    private func startEnergyTimer() {
        // 6분(360초) 마다 타이머 실행 → 에너지 +1, 운동량 -1, 포만감 -1
        energyTimer = Timer.scheduledTimer(withTimeInterval: energyTimerInterval, repeats: true) { [weak self] _ in
            self?.increaseEnergy()
        }
        
#if DEBUG
        print("⏰ 디버그 모드: 에너지 타이머 시작 (\(energyTimerInterval)초마다, \(debugSpeedMultiplier)배 빠르게)")
#endif
    }
    
    private func stopEnergyTimer() {
        energyTimer?.invalidate() // 타이머 중지
        energyTimer = nil
    }
    
    private func increaseEnergy() {
        // 캐릭터가 자는 중이 아니면 실행
        guard !isSleeping else {
            performSleepRecovery()
            return
        }
        
        // 디버그 모드에서는 배수로 회복
        let recoveryAmount = isDebugMode ? debugSpeedMultiplier : 1

        
        // 에너지 증가 (최대 100)
        if activityValue < 100 {
               activityValue = min(100, activityValue + recoveryAmount)
        }
        
        // 애정도 감소 (최소 0) - 디버그 모드에서는 배수로 감소
        let decreaseAmount = isDebugMode ? debugSpeedMultiplier : 1
        if happinessValue > 0 {
            happinessValue = max(0, happinessValue - decreaseAmount)
        }
        
        // 포만감 감소 (최소 0) - 디버그 모드에서는 배수로 감소
        if satietyValue > 0 {
            satietyValue = max(0, satietyValue - decreaseAmount)
        }
        
        // 상태 업데이트
        updateAllPercents()
        updateCharacterStatus()
        
#if DEBUG
        print("⚡ 디버그 모드 회복: 활동량 +\(recoveryAmount), 행복도 -\(decreaseAmount), 포만감 -\(decreaseAmount)")
#endif
    }
    
    private func performSleepRecovery() {
        let baseRecoveryMultiplier = Int.random(in: 2...5)
        let finalRecoveryMultiplier = isDebugMode ? (baseRecoveryMultiplier * debugSpeedMultiplier) : baseRecoveryMultiplier
        
        // 활동량 회복
        activityValue = min(100, activityValue + (5 * finalRecoveryMultiplier))
        
        updateAllPercents()
        updateCharacterStatus()
        
        #if DEBUG
        print("😴 디버그 모드 수면 회복: 활동량 +\(5 * finalRecoveryMultiplier) (\(finalRecoveryMultiplier)배 회복)")
        #else
        print("😴 수면 중 회복: 체력 +\(10 * finalRecoveryMultiplier), 활동량 +\(5 * finalRecoveryMultiplier) (\(finalRecoveryMultiplier)배 회복)")
        #endif
    }
    
    // MARK: - 앱 상태 처리
    private func setupAppStateObservers() {
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.handleAppWillResignActive()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.handleAppDidBecomeActive()
            }
            .store(in: &cancellables)
    }
    
    private func handleAppWillResignActive() {
        // 앱이 백그라운드로 나갈 때 시간 기록 및 타이머 정지
        lastUpdateTime = Date()
        stopEnergyTimer()
    }
    
    private func handleAppDidBecomeActive() {
        // 앱이 다시 켜졌을 때 지난 시간 계산
        let now = Date()
        let elapsedTime = now.timeIntervalSince(lastUpdateTime)
        let activityToAdd = Int(elapsedTime / 360)
        
        if activityToAdd > 0 {
            activityValue = min(100, activityValue + activityToAdd)
            updateAllPercents()
            updateCharacterStatus()
        }
        // 타이머 다시 시작
        startEnergyTimer()
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
        staminaPercent = CGFloat(staminaValue) / 100.0
        activityPercent = CGFloat(activityValue) / 100.0
        
        happinessPercent = CGFloat(happinessValue) / 100.0
        cleanPercent = CGFloat(cleanValue) / 100.0
        expPercent = CGFloat(expValue) / CGFloat(expMaxValue)
        
        // 스탯 배열 업데이트 (UI 표시용)
        stats = [
            ("fork.knife", Color.orange, colorForValue(satietyValue), satietyPercent),      // 포만감
            ("heart.fill", Color.red, colorForValue(staminaValue), staminaPercent),      // 체력
            ("bolt.fill", Color.yellow, colorForValue(activityValue), activityPercent)      // 활동량
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
        } else if staminaValue < 30 {
            statusMessage = "너무 피곤해요... 쉬고 싶어요."
        } else if happinessValue < 30 {
            statusMessage = "심심해요... 놀아주세요!"
        } else if cleanValue < 30 {
            statusMessage = "더러워요... 씻겨주세요!"
        } else if satietyValue > 80 && staminaValue > 80 && happinessValue > 80 {
            statusMessage = "정말 행복해요! 감사합니다!"
        } else {
            statusMessage = "오늘도 좋은 하루에요!"
        }
    }
    
    // MARK: - 액션 관련 관리
    
    // 액션 버튼을 현재 상태에 맞게 갱신
    private func refreshActionButtons() {
        guard let character = character else {
            // 캐릭터가 없으면 기본 액션(캐릭터 추가) 등장 설정
            actionButtons = [
                ("plus.circle", false, "캐릭터 생성")
            ]
            return
        }
        
        // ActionManager를 통해 현재 상황에 맞는 버튼들 가져오기
        let managerButtons = actionManager.getActionsButtons(
            phase: character.status.phase,
            isSleeping: isSleeping,
            count: 4
        )
        
        // ActionButton을 HomeViewModel의 튜플 형식으로 변환
        actionButtons = managerButtons.map { button in
            (icon: button.icon, unlocked: button.unlocked, name: button.name)
        }
        
        print("🔄 액션 버튼 갱신됨: \(character.status.phase.rawValue) 단계, 잠자는 상태: \(isSleeping)")
        print("📋 현재 액션들: \(actionButtons.map { $0.name }.joined(separator: ", "))")
    }
    
    // MARK: - 경험치 및 레벨업 관리
    
    // 경험치를 추가하고 레벨업을 체크합니다.
    // - Parameter amount: 추가할 경험치량
    private func addExp(_ amount: Int) {
        // 성장 단계에 따른 경험치 보너스 적용 (기존 로직 유지)
        var adjustedAmount = amount
        
        if let character = character, character.status.phase == .egg {
            // 운석(알) 상태에서는 경험치 5배로 획득 (기존 로직 유지)
            adjustedAmount *= 5
        }
        
        // 디버그 모드에서는 추가로 배수 적용
        if isDebugMode {
            adjustedAmount *= debugSpeedMultiplier
            print("⭐ 디버그 모드 경험치: 기본 \(amount) → 최종 \(adjustedAmount) (\(debugSpeedMultiplier)배)")
        }
        
        let oldExp = expValue
        expValue += adjustedAmount
        
        // 레벨업 체크 (기존 로직 유지)
        if expValue >= expMaxValue {
            levelUp()
        } else {
            expPercent = CGFloat(expValue) / CGFloat(expMaxValue)
            updateCharacterStatus()
        }
        
#if DEBUG
        print("⭐ 경험치 변화: \(oldExp) → \(expValue) (+\(adjustedAmount))")
#endif
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
        staminaValue = min(100, staminaValue + 20)
        activityValue = min(100, activityValue + 20)
        
        // 업데이트
        updateAllPercents()
    }
    
    // MARK: - 액션 메서드
    /*
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
     */
    // 4. 재우기/깨우기
    func putPetToSleep() {
        if isSleeping {
            // 이미 자고 있으면 깨우기
            isSleeping = false
            updateStatusMessage()
        } else {
            // 자고 있지 않으면 재우기
            isSleeping = true
            staminaValue = min(100, staminaValue + 20)
            updateAllPercents()
        }
        
        // 수면 상태 변경 시 액션 버튼 갱신
        refreshActionButtons()
        
        // 캐릭터 모델 업데이트
        updateCharacterStatus()
    }
    
    // 캐릭터 모델 업데이트
    private func updateCharacterStatus() {
        guard var character = character else { return }
        
        // 캐릭터 상태 업데이트
        character.status.satiety = satietyValue
        character.status.stamina = staminaValue
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
    
    // MARK: - 통합 액션 처리 메서드
    
    // 인덱스를 기반으로 액션을 실행합니다.
    /// - Parameter index: 실행할 액션의 인덱스
    func performAction(at index: Int) {
        // 액션 버튼 배열의 유효한 인덱스인지 확인
        guard index < actionButtons.count else {
            print("⚠️ 잘못된 액션 인덱스: \(index)")
            return
        }
        
        let action = actionButtons[index]
        
        // 잠금 해제된 액션인지 확인
        guard action.unlocked else {
            print("🔒 '\(action.name)' 액션이 잠겨있습니다")
            return
        }
        
        // 잠자는 상태에서는 재우기/깨우기만 가능
        if isSleeping && action.icon != "bed.double" {
            print("😴 펫이 자고 있어서 깨우기만 가능합니다")
            return
        }
        
        // 액션 아이콘에 따라 해당 메서드 호출
        switch action.icon {
            /*
             case "fork.knife":
             feedPet()
             print("🍽️ 펫에게 밥을 줬습니다")
             
             case "gamecontroller.fill":
             playWithPet()
             print("🎮 펫과 놀아줬습니다")
             
             case "shower.fill":
             washPet()
             print("🚿 펫을 씻겨줬습니다")
             */
        case "bed.double":
            putPetToSleep()
            print(isSleeping ? "😴 펫을 재웠습니다" : "😊 펫을 깨웠습니다")
            
        default:
            // ActionManager에서 가져온 액션 처리
            if let actionManager = actionButtons.first(where: { $0.icon == action.icon }),
               let actionId = getActionId(for: action.icon) {
                executeActionManagerAction(actionId: actionId)
            } else {
                print("❓ 알 수 없는 액션: \(action.name), 아이콘: \(action.icon)")
            }
        }
        
        // 액션 실행 후 액션 버튼 갱신
        refreshActionButtons()
    }
    
    // 액션 아이콘으로부터 ActionManager의 액션 ID를 가져옵니다.
    /// - Parameter icon: 액션 아이콘
    /// - Returns: 해당하는 액션 ID
    private func getActionId(for icon: String) -> String? {
        switch icon {
            // 기존 액션들
        case "hand.tap.fill":
            return "tap_egg"
        case "flame.fill":
            return "warm_egg"
        case "bubble.left.fill":
            return "talk_egg"
        case "fork.knife":
            return "feed"
        case "gamecontroller.fill":
            return "play"
        case "shower.fill":
            return "wash"
        case "bed.double":
            return "sleep"
            
            // FIXME: 새로 추가된 이벤트 액션들 매핑
            // 건강 관리 액션들
        case "pills.fill":
            return "give_medicine"
        case "capsule.fill":
            return "vitamins"
        case "stethoscope":
            return "check_health"
            
            // 기타 관련 액션들
        case "sun.max.fill":
            return "weather_sunny"
        case "figure.walk":
            return "walk_together"
        case "figure.seated.side":
            return "rest_together"
            
            // 장소 관련 액션들
        case "house.fill":
            return "go_home"
        case "tree.fill":
            return "go_outside"
            
            // 감정 관리 액션들
        case "hand.raised.fill":
            return "comfort"
        case "hands.clap.fill":
            return "encourage"
            
            // 청결 관리 액션들
        case "comb.fill":
            return "brush_fur"
        case "sparkles":
            return "full_grooming"
            
            // 특별 액션들
        case "figure.strengthtraining.traditional":
            return "special_training"
        case "party.popper.fill":
            return "party"
        case "drop.fill":
            return "hot_spring"
            
        default:
            return nil
        }
    }
    
    // ActionManager를 통해 액션을 실행합니다.
    /// - Parameter actionId: 실행할 액션 ID
    private func executeActionManagerAction(actionId: String) {
        guard let character = character,
              let action = actionManager.getAction(id: actionId) else {
            print("❌ 액션을 찾을 수 없습니다: \(actionId)")
            return
        }
        
        // 활동량 확인 (활동량이 부족하면 실행 불가)
        if activityValue < action.activityCost {
            print("⚡ '\(action.name)' 액션을 하기에 활동량이 부족합니다 (필요: \(action.activityCost), 현재: \(activityValue))")
            statusMessage = action.failMessage.isEmpty ? "너무 지쳐서 할 수 없어요..." : action.failMessage
            return
        }
        
        // 활동량 소모
        activityValue = max(0, activityValue - action.activityCost)
        
        // 액션 효과 적용
        for (statName, value) in action.effects {
            switch statName {
            case "satiety":
                satietyValue = max(0, min(100, satietyValue + value))
            case "energy":
                staminaValue = max(0, min(100, staminaValue + value))
            case "happiness":
                happinessValue = max(0, min(100, happinessValue + value))
            case "clean":
                cleanValue = max(0, min(100, cleanValue + value))
            case "healthy":
                healthyValue = max(0, min(100, healthyValue + value))
            default:
                break
            }
        }
        
        // 경험치 획득 - 디버그 모드 배수 적용은 addExp() 메서드에서 처리
        if action.expGain > 0 {
            let oldExp = expValue
            addExp(action.expGain) // 여기서 디버그 모드 배수가 자동 적용됨
            
#if DEBUG
            print("⭐ 액션 경험치 획득: \(action.name) - \(oldExp) → \(expValue)")
#endif
        }
        
        // 성공 메시지 표시
        if !action.successMessage.isEmpty {
            statusMessage = action.successMessage
        }
        
        // UI 업데이트
        updateAllPercents()
        updateCharacterStatus()
        updateLastActivityDate()
        
        print("✅ '\(action.name)' 액션을 실행했습니다")
    }
}

