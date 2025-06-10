//
//  HomeViewModel.swift
//  Grruung
//
//  Created by KimJunsoo on 5/21/25.
//

import Foundation
import SwiftUI
import Combine
import FirebaseFirestore

class HomeViewModel: ObservableObject {
    // MARK: - Properties
    // 캐릭터 관련
    @Published var character: GRCharacter?
    @Published var statusMessage: String = "안녕하세요!" // 상태 메시지
    @Published var goldMessage: String = ""

    // 레벨 관련
    @Published var level: Int = 1
    @Published var expValue: Int = 0
    @Published var expMaxValue: Int = 100
    @Published var expPercent: CGFloat = 0.0
    @Published var animationInProgress: Bool = false // 애니메이션 진행 상태
    
    // 보이는 스탯 (UI 표시)
    @Published var satietyValue: Int = 100 // 포만감 (0~100, 시작값 100)
    @Published var satietyPercent: CGFloat = 1.0
    
    @Published var staminaValue: Int = 100 // 운동량 (0~100, 시작값 100)
    @Published var staminaPercent: CGFloat = 1.0
    
    @Published var activityValue: Int = 100 // 활동량/피로도 (0~100, 시작값 100) - 행동력 개념
    @Published var activityPercent: CGFloat = 1.0
    
    // 히든 스탯 (UI에 직접 표시 안함)
    @Published var affectionValue: Int = 0 // 누적 애정도 (0~1000, 시작값 0)
    @Published var weeklyAffectionValue: Int = 0 // 주간 애정도 (0~100, 시작값 0)
    
    @Published var healthyValue: Int = 50 // 건강도 (0~100, 시작값 50)
    @Published var cleanValue: Int = 50 // 청결도 (0~100, 시작값 50)
    
    // 상태 관련
    @Published var isSleeping: Bool = false // 잠자기 상태
    
    @Published var energyTimer: Timer? // 에너지 증가 타이머
    @Published var lastUpdateTime: Date = Date()
    @Published var cancellables = Set<AnyCancellable>()
    
    private var statDecreaseTimer: Timer?      // 보이는 스탯 감소용
    private var hiddenStatDecreaseTimer: Timer? // 히든 스탯 감소용
    private var weeklyAffectionTimer: Timer?    // 주간 애정도 체크용
    private var lastActivityDate: Date = Date() // 마지막 활동 날짜
    
    // Firebase 연동 상태
    @Published var isFirebaseConnected: Bool = false
    @Published var isLoadingFromFirebase: Bool = false
    @Published var firebaseError: String?
    private let firebaseService = FirebaseService.shared
    private var characterListener: ListenerRegistration?
    
    // 무한 루프 방지를 위한 플래그
    private var isUpdatingFromFirebase: Bool = false
    private var saveDebounceTimer: Timer?
    
    @Published var isDataReady: Bool = false
    @Published var userViewModel = UserViewModel()
    @Published var isAnimationRunning: Bool = false

    // 디버그 모드 설정 추가
#if DEBUG
    private let isDebugMode = true
    private let debugSpeedMultiplier = 5 // 디버그 시 5배 빠르게/많이
#else
    private let isDebugMode = false
    private let debugSpeedMultiplier = 1
#endif
    
    // 활동량(피로도) 회복 주기: 6분 → 15분으로 조정
    private var energyTimerInterval: TimeInterval {
#if DEBUG
        return 30.0 // 디버그: 30초마다
#else
        return 900.0 // 릴리즈: 15분마다 (15 * 60 = 900초)
#endif
    }
    
    // 보이는 스탯 감소 주기: 10분 → 20분으로 조정
    private var statDecreaseInterval: TimeInterval {
#if DEBUG
        return 40.0 // 디버그: 40초마다
#else
        return 1200.0 // 릴리즈: 20분마다 (20 * 60 = 1200초)
#endif
    }
    
    // 히든 스탯 감소 주기: 30분 → 1시간으로 조정
    private var hiddenStatDecreaseInterval: TimeInterval {
#if DEBUG
        return 120.0 // 디버그: 2분마다
#else
        return 3600.0 // 릴리즈: 1시간마다 (60 * 60 = 3600초)
#endif
    }
    
    // 주간 애정도 체크 주기: 1시간마다 체크하되, 월요일 00시에만 실제 처리
    private var weeklyAffectionInterval: TimeInterval {
#if DEBUG
        return 180.0 // 디버그: 3분마다
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
    
    // 스탯 표시 형식 수정 (3개의 보이는 스탯만)
    @Published var stats: [(icon: String, iconColor: Color, color: Color, value: CGFloat)] = [
        ("fork.knife", Color.orange, Color.orange, 1.0), // 포만감
        ("figure.run", Color.blue, Color.blue, 1.0),     // 운동량
        ("bolt.fill", Color.yellow, Color.yellow, 1.0)   // 활동량
    ]
    
    // 스탯 값에 따라 색상을 반환하는 유틸 함수
    func colorForValue(_ value: CGFloat) -> Color {
        switch value {
        case 0...0.3: return .red
        case 0.3...0.79: return .yellow
        default: return .green
        }
    }
    
    // 액션 관리자
    private let actionManager = ActionManager.shared
    
    // 성장 단계별 경험치 요구량
    private let phaseExpRequirements: [CharacterPhase: Int] = [
        .egg: 50,
        .infant: 100,
        .child: 150,
        .adolescent: 200,
        .adult: 300,
        .elder: 500
    ]
    
    // MARK: - Initialization
    
    init() {
        setupFirebaseIntegration()
        setupAppStateObservers()
        startStatDecreaseTimers()
        
        userViewModel = UserViewModel()
        
        // 캐릭터 주소 변경 이벤트 구독
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCharacterAddressChanged(_:)),
            name: NSNotification.Name("CharacterAddressChanged"),
            object: nil
        )
        
        // 캐릭터 이름 변경 이벤트 구독
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCharacterNameChanged(_:)),
            name: NSNotification.Name("CharacterNameChanged"),
            object: nil
        )
#if DEBUG
        print("🚀 HomeViewModel 초기화 완료")
        print("🚀 디버그 모드 활성화!")
        print("   - 타이머 속도: \(debugSpeedMultiplier)배 빠르게")
        print("   - 스탯 변화: \(debugSpeedMultiplier)배")
        print("   - 경험치 획득: \(debugSpeedMultiplier)배")
        print("   - 에너지 회복: \(energyTimerInterval)초마다")
        print("   - 스탯 감소: \(statDecreaseInterval)초마다")
#endif
    }
    
    // Firebase 연동을 초기화합니다
    private func setupFirebaseIntegration() {
        isLoadingFromFirebase = true
        firebaseError = nil
        
        print("🔥 Firebase 연동 초기화 시작")
        
        // 메인 캐릭터 로드
        Task {
            await loadMainCharacterFromFirebaseAsync()
        }
    }
    
    // 비동기 방식으로 메인 캐릭터 로드
    private func loadMainCharacterFromFirebaseAsync() async {
        // 기존 메서드 호출 대신 비동기 방식으로 구현
        do {
            let character = try await loadMainCharacterAsync()
            
            if let character = character {
                // 메인 스레드에서 UI 업데이트
                await MainActor.run {
                    // Firebase에서 로드한 캐릭터 설정
                    setupCharacterFromFirebase(character)
                    isLoadingFromFirebase = false
                    isDataReady = true
                }
                
                // 실시간 리스너 설정
                setupRealtimeListener(characterID: character.id)
                
                // 오프라인 보상 처리
                processOfflineTime()
                
                print("✅ Firebase에서 캐릭터 로드 완료: \(character.name)")
            } else {
                // 캐릭터가 없는 경우
                await MainActor.run {
                    isLoadingFromFirebase = false
                    isDataReady = true
                }
                print("📝 메인 캐릭터가 없습니다.")
            }
        } catch {
            await MainActor.run {
                firebaseError = "캐릭터 로드 실패: \(error.localizedDescription)"
                isLoadingFromFirebase = false
                isDataReady = true
            }
            print("❌ Firebase 캐릭터 로드 실패: \(error.localizedDescription)")
        }
    }
    
    // 비동기 방식으로 메인 캐릭터 로드 (Firebase 서비스 확장 필요)
    private func loadMainCharacterAsync() async throws -> GRCharacter? {
        return try await withCheckedThrowingContinuation { continuation in
            firebaseService.loadMainCharacter { character, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: character)
                }
            }
        }
    }
    
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
        
        // 캐릭터 위치 변경 이벤트 구독 개선
        NotificationCenter.default.publisher(for: NSNotification.Name("CharacterAddressChanged"))
            .sink { [weak self] notification in
                guard let self = self else { return }
                guard let characterUUID = notification.userInfo?["characterUUID"] as? String,
                      let addressRaw = notification.userInfo?["address"] as? String else {
                    return
                }
                
                // 현재 보고 있는 캐릭터가 변경된 캐릭터와 같은지 확인
                if let character = self.character, character.id == characterUUID {
                    // 주소가 userHome이 아니거나 space인 경우 새 메인 캐릭터 로드
                    if addressRaw != "userHome" || addressRaw == "space" {
                        DispatchQueue.main.async {
                            self.loadMainCharacterFromFirebase()
                        }
                    }
                } else {
                    // 다른 캐릭터가 메인으로 설정된 경우를 대비해 메인 캐릭터 다시 로드
                    DispatchQueue.main.async {
                        self.loadMainCharacterFromFirebase()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Firebase Integration

    // Firestore에서 메인 캐릭터를 로드
    private func loadMainCharacterFromFirebase() {
        isLoadingFromFirebase = true
        firebaseError = nil
        
        print("🔥 Firebase 연동 초기화 시작")
        
        // 메인 캐릭터 로드
        firebaseService.loadMainCharacter { [weak self] character, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoadingFromFirebase = false
                
                if let error = error {
                    self.firebaseError = "캐릭터 로드 실패: \(error.localizedDescription)"
                    print("❌ Firebase 캐릭터 로드 실패: \(error.localizedDescription)")
                    return
                }
                
                if let character = character {
                    // Firebase에서 로드한 캐릭터 설정
                    self.setupCharacterFromFirebase(character)
                    self.setupRealtimeListener(characterID: character.id)
                    
                    // 오프라인 보상 처리
                    self.processOfflineTime()
                    
                    print("✅ Firebase에서 캐릭터 로드 완료: \(character.name)")
                } else {
                    // 캐릭터가 없는 경우는 처리하지 않음 (온보딩에서 생성하기 때문)
                    print("📝 메인 캐릭터가 없습니다.")
                    self.character = nil
                    
                    // 캐릭터가 없을 때 UI 업데이트
                    self.updateEmptyCharacterUI()
                }
            }
        }
    }
    
    // 빈 캐릭터 UI 업데이트 메서드 추가
    private func updateEmptyCharacterUI() {
        // 빈 상태의 UI로 업데이트
        level = 0
        expValue = 0
        expMaxValue = 0
        expPercent = 0.0
        
        satietyValue = 0
        staminaValue = 0
        activityValue = 0
        
        satietyPercent = 0.0
        staminaPercent = 0.0
        activityPercent = 0.0
        
        // 스탯 바 비활성화
        stats = [
            ("fork.knife", Color.gray, Color.gray, 0.0),
            ("figure.run", Color.gray, Color.gray, 0.0),
            ("bolt.fill", Color.gray, Color.gray, 0.0)
        ]
        
        // 액션 버튼 비활성화 (캐릭터 생성 버튼만 활성화)
        actionButtons = [
            ("plus.circle", true, "캐릭터 생성"),
            ("gamecontroller.fill", false, "놀아주기"),
            ("shower.fill", false, "씻기기"),
            ("bed.double", false, "재우기")
        ]
        
        // 사이드 버튼 비활성화
        sideButtons = [
            ("backpack.fill", true, "인벤토리"),
            ("cart.fill", true, "상점"),
            ("mountain.2.fill", true, "동산"),
            ("book.fill", false, "일기"),
            ("microphone.fill", false, "채팅"),
            ("gearshape.fill", true, "설정")
        ]
        
        // 상태 메시지 업데이트
        statusMessage = "아직 펫이 없어요. 새로운 친구를 만나보세요!"
    }
    
    // 기본 캐릭터를 생성하고 Firebase에 저장
    private func createAndSaveDefaultCharacter() {
        print("🆕 기본 캐릭터 생성 중...")
        
        let status = GRCharacterStatus(
            level: 0,
            exp: 0,
            expToNextLevel: 50,
            phase: .egg,
            satiety: 100,
            stamina: 100,
            activity: 100,
            affection: 0,
            affectionCycle: 0,
            healthy: 50,
            clean: 50
        )
        
        let newCharacter = GRCharacter(
            species: .quokka,
            name: "냥냥이",
            imageName: "quokka",
            birthDate: Date(),
            createdAt: Date(),
            status: status
        )
        
        // 로컬에 먼저 설정
        self.character = newCharacter
        self.setupCharacterFromFirebase(newCharacter)
        
        // Firebase에 캐릭터 생성 및 메인으로 설정
        firebaseService.createAndSetMainCharacter(character: newCharacter) { [weak self] characterID, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    self.firebaseError = "캐릭터 생성 실패: \(error.localizedDescription)"
                    print("❌ 기본 캐릭터 생성 실패: \(error.localizedDescription)")
                    // 오류가 있어도 로컬에서는 사용 가능
                    return
                }
                
                if let characterID = characterID {
                    print("✅ 기본 캐릭터 생성 완료: \(characterID)")
                    self.setupRealtimeListener(characterID: characterID)
                    self.isFirebaseConnected = true
                }
            }
        }
    }
    
    // Firebase에서 로드한 캐릭터로 ViewModel 상태를 설정
    private func setupCharacterFromFirebase(_ character: GRCharacter) {
        self.isUpdatingFromFirebase = true
        
        self.character = character
        
        // 캐릭터 스탯을 ViewModel에 동기화
        level = character.status.level
        expValue = character.status.exp
        expMaxValue = character.status.expToNextLevel
        
        satietyValue = character.status.satiety
        staminaValue = character.status.stamina
        activityValue = character.status.activity
        
        affectionValue = character.status.affection
        weeklyAffectionValue = character.status.affectionCycle
        healthyValue = character.status.healthy
        cleanValue = character.status.clean
        
        // UI 업데이트
        updateAllPercents()
        unlockFeaturesByPhase(character.status.phase)
        refreshActionButtons()
        
        isFirebaseConnected = true
        self.isUpdatingFromFirebase = false
        
#if DEBUG
        print("📊 Firebase 캐릭터 동기화 완료")
        print("   - 레벨: \(level), 경험치: \(expValue)/\(expMaxValue)")
        print("   - 포만감: \(satietyValue), 운동량: \(staminaValue), 활동량: \(activityValue)")
        print("   - 건강: \(healthyValue), 청결: \(cleanValue), 애정: \(affectionValue)")
#endif
    }
    
    // Firebase에서 받은 캐릭터 데이터를 로컬과 동기화
    private func syncCharacterFromFirebase(_ character: GRCharacter) {
        // 무한 루프 방지: Firebase에서 업데이트 중이거나 로컬에서 저장 중일 때는 스킵
        guard !isUpdatingFromFirebase && !animationInProgress else {
            return
        }
        
        // 변경사항이 있는지 확인
        let hasChanges = level != character.status.level ||
        expValue != character.status.exp ||
        satietyValue != character.status.satiety ||
        staminaValue != character.status.stamina ||
        activityValue != character.status.activity ||
        healthyValue != character.status.healthy ||
        cleanValue != character.status.clean ||
        affectionValue != character.status.affection
        
        if hasChanges {
            self.isUpdatingFromFirebase = true
            
            // 캐릭터 정보 업데이트
            self.character = character
            
            level = character.status.level
            expValue = character.status.exp
            expMaxValue = character.status.expToNextLevel
            
            satietyValue = character.status.satiety
            staminaValue = character.status.stamina
            activityValue = character.status.activity
            
            affectionValue = character.status.affection
            weeklyAffectionValue = character.status.affectionCycle
            healthyValue = character.status.healthy
            cleanValue = character.status.clean
            
            updateAllPercents()
            
            self.isUpdatingFromFirebase = false
            
#if DEBUG
            print("🔄 Firebase에서 캐릭터 동기화됨 (외부 변경사항)")
#endif
        }
    }
    
    // 실시간 캐릭터 동기화 리스너를 설정
    private func setupRealtimeListener(characterID: String) {
        // 기존 리스너 해제
        
        characterListener?.remove()
        
        // 새 리스너 설정
        characterListener = firebaseService.setupCharacterListener(characterID: characterID) { [weak self] character, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    self.firebaseError = "실시간 동기화 오류: \(error.localizedDescription)"
                    print("❌ 실시간 동기화 오류: \(error.localizedDescription)")
                    return
                }
                
                if let character = character {
                    // 실시간 업데이트 (무한 루프 방지)
                    self.syncCharacterFromFirebase(character)
                }
            }
        }
        
        print("🔄 실시간 동기화 리스너 설정 완료")
    }
    
    
    
    // MARK: - Data Persistence

    // 현재 캐릭터 상태를 Firestore에 저장
    private func saveCharacterToFirebase() {
        // Firebase에서 업데이트 중이면 저장하지 않음 (무한 루프 방지)
        guard !isUpdatingFromFirebase else { return }
        
        // 기존 타이머 취소
        saveDebounceTimer?.invalidate()
        
        // 0.5초 후에 저장 (디바운싱)
        saveDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.performSaveToFirebase()
        }
    }
    
    // 실제 Firebase 저장을 수행
    private func performSaveToFirebase() {
        guard let character = character, isFirebaseConnected else { return }
        
        firebaseService.saveCharacter(character) { [weak self] error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    self.firebaseError = "저장 실패: \(error.localizedDescription)"
                    print("❌ Firebase 저장 실패: \(error.localizedDescription)")
                } else {
                    self.firebaseError = nil
#if DEBUG
                    print("💾 Firebase에 캐릭터 저장 완료")
#endif
                }
            }
        }
    }
    
    // 스탯 변화를 기록하고 Firebase에 저장
    /// - Parameters:
    ///   - changes: 변화된 스탯 [스탯명: 변화량]
    ///   - reason: 변화 원인
    private func recordAndSaveStatChanges(_ changes: [String: Int], reason: String) {
        guard let character = character, isFirebaseConnected else { return }
        
        // 스탯 변화 기록
        firebaseService.recordStatChanges(
            characterID: character.id,
            changes: changes,
            reason: reason
        ) { error in
            if let error = error {
                print("❌ 스탯 변화 기록 실패: \(error.localizedDescription)")
            }
        }
        
        // 캐릭터 저장
        saveCharacterToFirebase()
    }
    
    // MARK: - Offline Data Processing

    // 앱 재시작 시 오프라인 시간 계산 및 보상 적용
    private func processOfflineTime() {
        guard let character = character else { return }
        
        firebaseService.getCharacterLastActiveTime(characterID: character.id) { [weak self] lastActiveTime, error in
            guard let self = self, let lastActiveTime = lastActiveTime else { return }
            
            let now = Date()
            let elapsedTime = now.timeIntervalSince(lastActiveTime)
            
            // 1분 이상 차이가 날 때만 오프라인 보상 적용
            guard elapsedTime > 60 else { return }
            
            DispatchQueue.main.async {
                self.applyOfflineReward(elapsedTime: elapsedTime)
                
                // 마지막 활동 시간 업데이트
                self.firebaseService.updateCharacterLastActiveTime(characterID: character.id) { _ in }
            }
        }
    }
    
    // 오프라인 보상을 적용합니다.
    private func applyOfflineReward(elapsedTime: TimeInterval) {
        let hours = Int(elapsedTime / 3600)
        let minutes = Int((elapsedTime.truncatingRemainder(dividingBy: 3600)) / 60)
        
        print("⏰ 오프라인 시간: \(hours)시간 \(minutes)분")
        
        // 최대 12시간까지만 보상
        let maxOfflineHours = 12
        let effectiveHours = min(hours, maxOfflineHours)
        
        // 기본 회복량 계산 (15분마다 활동량 10 회복)
        let recoveryIntervals = Int(elapsedTime / (isDebugMode ? 30.0 : 900.0))
        let baseRecovery = min(recoveryIntervals * (isDebugMode ? (10 * debugSpeedMultiplier) : 10), 50)
        
        // 스탯 감소 계산 (20분마다 포만감/운동량 2씩 감소)
        let decreaseIntervals = Int(elapsedTime / (isDebugMode ? 40.0 : 1200.0))
        let baseDecrease = min(decreaseIntervals * (isDebugMode ? (2 * debugSpeedMultiplier) : 2), 30)
        
        // 변화량 기록용
        var statChanges: [String: Int] = [:]
        
        // 활동량 회복 적용
        if baseRecovery > 0 && activityValue < 100 {
            let oldActivity = activityValue
            activityValue = min(100, activityValue + baseRecovery)
            statChanges["activity"] = activityValue - oldActivity
        }
        
        // 스탯 감소 적용
        if baseDecrease > 0 {
            if satietyValue > 0 {
                let oldSatiety = satietyValue
                satietyValue = max(0, satietyValue - baseDecrease)
                statChanges["satiety"] = satietyValue - oldSatiety
            }
            
            if staminaValue > 0 {
                let oldStamina = staminaValue
                staminaValue = max(0, staminaValue - baseDecrease)
                statChanges["stamina"] = staminaValue - oldStamina
            }
        }
        
        // UI 업데이트
        updateAllPercents()
        updateCharacterStatus()
        
        // 변화사항 기록 및 저장
        if !statChanges.isEmpty {
            recordAndSaveStatChanges(statChanges, reason: "offline_reward_\(effectiveHours)h")
        }
        
        // 사용자에게 알림
        if effectiveHours > 0 {
            statusMessage = "오랜만이에요! \(effectiveHours)시간 동안 쉬면서 회복했어요."
        } else if minutes > 0 {
            statusMessage = "잠깐 자리를 비우셨네요! 조금 회복했어요."
        }
        
#if DEBUG
        print("🎁 오프라인 보상 적용: \(statChanges)")
#endif
    }
    
    
    // MARK: - Timer Management

    private func startStatDecreaseTimers() {
        // 활동량(피로도) 회복 타이머 (15분마다)
        energyTimer = Timer.scheduledTimer(withTimeInterval: energyTimerInterval, repeats: true) { [weak self] _ in
            self?.recoverActivity()
        }
        
        // 보이는 스탯 감소 (20분마다)
        statDecreaseTimer = Timer.scheduledTimer(withTimeInterval: statDecreaseInterval, repeats: true) { [weak self] _ in
            self?.decreaseVisibleStats()
        }
        
        // 히든 스탯 감소 (1시간마다)
        hiddenStatDecreaseTimer = Timer.scheduledTimer(withTimeInterval: hiddenStatDecreaseInterval, repeats: true) { [weak self] _ in
            self?.decreaseHiddenStats()
        }
        
        // 주간 애정도 체크 (1시간마다 체크하되, 월요일 00시에만 실제 처리)
        weeklyAffectionTimer = Timer.scheduledTimer(withTimeInterval: weeklyAffectionInterval, repeats: true) { [weak self] _ in
            self?.checkWeeklyAffection()
        }
        
#if DEBUG
        print("⏰ 디버그 모드: 모든 타이머들 시작됨")
        print("   - 활동량 회복: \(energyTimerInterval)초마다")
        print("   - 보이는 스탯 감소: \(statDecreaseInterval)초마다")
        print("   - 히든 스탯 감소: \(hiddenStatDecreaseInterval)초마다")
        print("   - 주간 애정도 체크: \(weeklyAffectionInterval)초마다")
#endif
    }
    
    // 모든 타이머를 정지합니다.
    private func stopAllTimers() {
        energyTimer?.invalidate()
        energyTimer = nil
        
        statDecreaseTimer?.invalidate()
        statDecreaseTimer = nil
        
        hiddenStatDecreaseTimer?.invalidate()
        hiddenStatDecreaseTimer = nil
        
        weeklyAffectionTimer?.invalidate()
        weeklyAffectionTimer = nil
    }
    
    // 활동량(피로도) 회복 처리 - 15분마다 실행
    private func recoverActivity() {
        let baseRecoveryAmount = isSleeping ? 15 : 10
        let finalRecoveryAmount = isDebugMode ? (baseRecoveryAmount * debugSpeedMultiplier) : baseRecoveryAmount
        
        if activityValue < 100 {
            let oldValue = activityValue
            activityValue = min(100, activityValue + finalRecoveryAmount)
            
            updateAllPercents()
            updateCharacterStatus()
            
            // Firebase에 기록
            let recoveryChanges = ["activity": activityValue - oldValue]
            recordAndSaveStatChanges(recoveryChanges, reason: "timer_recovery")
            
#if DEBUG
            print("⚡ 디버그 모드 활동량 회복: +\(finalRecoveryAmount)" + (isSleeping ? " (수면 보너스)" : ""))
#endif
        }
    }
    
    // 보이는 스탯 감소 (포만감, 활동량)
    private func decreaseVisibleStats() {
        // 잠자는 중에는 감소 속도 절반
        let satietyDecrease = isSleeping ? 1 : 2
        let staminaDecrease = isSleeping ? 1 : 2
        
        // 디버그 모드에서는 배수 적용
        let finalSatietyDecrease = isDebugMode ? (satietyDecrease * debugSpeedMultiplier) : satietyDecrease
        let finalStaminaDecrease = isDebugMode ? (staminaDecrease * debugSpeedMultiplier) : staminaDecrease
        
        var statChanges: [String: Int] = [:]
        
        // 포만감 감소
        if satietyValue > 0 {
            let oldValue = satietyValue
            satietyValue = max(0, satietyValue - finalSatietyDecrease)
            statChanges["satiety"] = satietyValue - oldValue
        }
        
        // 운동량 감소
        if staminaValue > 0 {
            let oldValue = staminaValue
            staminaValue = max(0, staminaValue - finalStaminaDecrease)
            statChanges["stamina"] = staminaValue - oldValue
        }
        
        updateAllPercents()
        updateCharacterStatus()
        
        // Firebase에 기록
        if !statChanges.isEmpty {
            recordAndSaveStatChanges(statChanges, reason: "timer_decrease")
        }
        
#if DEBUG
        print("📉 디버그 모드 보이는 스탯 감소: \(statChanges)" + (isSleeping ? " (수면 중)" : ""))
#endif
    }
    
    // 히든 스탯 감소 (건강, 청결)
    private func decreaseHiddenStats() {
        let healthDecrease = isDebugMode ? debugSpeedMultiplier : 1
        let cleanDecrease = isDebugMode ? (2 * debugSpeedMultiplier) : 2
        
        var statChanges: [String: Int] = [:]
        
        // 건강도 감소
        if healthyValue > 0 {
            let oldValue = healthyValue
            healthyValue = max(0, healthyValue - healthDecrease)
            statChanges["healthy"] = healthyValue - oldValue
        }
        
        // 청결도 감소
        if cleanValue > 0 {
            let oldValue = cleanValue
            cleanValue = max(0, cleanValue - cleanDecrease)
            statChanges["clean"] = cleanValue - oldValue
        }
        
        updateAllPercents()
        updateCharacterStatus()
        
        // Firebase에 기록
        if !statChanges.isEmpty {
            recordAndSaveStatChanges(statChanges, reason: "timer_hidden_decrease")
        }
        
#if DEBUG
        print("🔍 디버그 모드 히든 스탯 감소: \(statChanges)")
#endif
    }
    
    // 주간 애정도 체크 - 매주 월요일 00시에 주간 애정도를 누적 애정도에 추가
    private func checkWeeklyAffection() {
        let currentDate = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: currentDate)
        let hour = calendar.component(.hour, from: currentDate)
        
        let shouldProcessWeeklyAffection = isDebugMode ? true : (weekday == 2 && hour == 0)
        
        if shouldProcessWeeklyAffection && weeklyAffectionValue > 0 {
            let bonusMultiplier = isDebugMode ? debugSpeedMultiplier : 1
            let affectionToAdd = weeklyAffectionValue * bonusMultiplier
            
            let oldAffection = affectionValue
            affectionValue = min(1000, affectionValue + affectionToAdd)
            weeklyAffectionValue = 0
            
            updateAllPercents()
            updateCharacterStatus()
            
            statusMessage = "한 주 동안의 사랑이 쌓였어요! 애정도가 증가했습니다."
            
            // Firebase에 기록
            let affectionChanges = ["affection": affectionValue - oldAffection]
            recordAndSaveStatChanges(affectionChanges, reason: "weekly_affection")
            
#if DEBUG
            print("💖 디버그 모드 주간 애정도 처리: +\(affectionToAdd)")
#endif
        }
        
        checkAffectionDecrease()
    }
    
    // 활동 부족으로 인한 애정도 감소 체크
    private func checkAffectionDecrease() {
        let currentDate = Date()
        let calendar = Calendar.current
        let daysSinceLastActivity = calendar.dateComponents([.day], from: lastActivityDate, to: currentDate).day ?? 0
        
        let daysThreshold = isDebugMode ? 1 : 3
        
        if daysSinceLastActivity >= daysThreshold {
            let baseDecrease = min(50, daysSinceLastActivity * 10)
            let finalDecrease = isDebugMode ? (baseDecrease * debugSpeedMultiplier) : baseDecrease
            
            if affectionValue > 0 {
                let oldValue = affectionValue
                affectionValue = max(0, affectionValue - finalDecrease)
                updateAllPercents()
                updateCharacterStatus()
                
                statusMessage = "오랫동안 관심을 받지 못해서 외로워해요..."
                
                // Firebase에 기록
                let affectionChanges = ["affection": affectionValue - oldValue]
                recordAndSaveStatChanges(affectionChanges, reason: "affection_decrease")
                
#if DEBUG
                print("💔 디버그 모드 애정도 감소: -\(finalDecrease)")
#endif
            }
        }
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
    
    // MARK: - App Lifecycle Management
    
    private func handleAppWillResignActive() {
        // 앱이 백그라운드로 나갈 때 시간 기록 및 모든 타이머 정지
        lastUpdateTime = Date()
        stopAllTimers()
        
        // Firebase에 현재 상태 저장
        saveCharacterToFirebase()
#if DEBUG
        print("📱 앱이 백그라운드로 이동 - 모든 타이머 정지")
#endif
    }
    
    // handleAppDidBecomeActive에 오프라인 보상 추가
    private func handleAppDidBecomeActive() {
        print("📱 앱이 포그라운드로 복귀")
        
        // Firebase 오프라인 보상 처리
        processOfflineTime()
        
        // 모든 타이머 다시 시작
        startStatDecreaseTimers()
        
#if DEBUG
        print("📱 앱이 포그라운드로 복귀 - 모든 타이머 재시작")
#endif
    }
    
    // MARK: - Character Status Management

    // 모든 스탯의 퍼센트 값을 업데이트
    private func updateAllPercents() {
        // 보이는 스탯 퍼센트 업데이트 (0~100 → 0.0~1.0)
        satietyPercent = CGFloat(satietyValue) / 100.0
        staminaPercent = CGFloat(staminaValue) / 100.0
        activityPercent = CGFloat(activityValue) / 100.0
        
        // 경험치 퍼센트 업데이트
        expPercent = expMaxValue > 0 ? CGFloat(expValue) / CGFloat(expMaxValue) : 0.0
        
        // UI 표시용 스탯 배열 업데이트 (3개의 보이는 스탯만)
        stats = [
            ("fork.knife", Color.orange, colorForValue(satietyValue), satietyPercent),      // 포만감
            ("figure.run", Color.blue, colorForValue(staminaValue), staminaPercent),       // 운동량
            ("bolt.fill", Color.yellow, colorForValue(activityValue), activityPercent)     // 활동량
        ]
        
        // 상태 메시지 업데이트
        updateStatusMessage()
    }
    
    // 캐릭터 상태에 따른 메시지를 업데이트
    private func updateStatusMessage() {
        guard let character = character else {
            statusMessage = "안녕하세요!"
            return
        }
        
        // 운석 상태인 경우 특별한 메시지 표시
        if character.status.phase == .egg {
            // 운석 상태일 때는 랜덤으로 다양한 미묘한 메시지 표시
            let eggMessages = [
                "*흔들흔들*",
                "*따뜻해...*",
                "*미세한 움직임*",
                "*두근두근*",
                "*콩닥콩닥*",
                "*똑똑*"
            ]
            statusMessage = eggMessages.randomElement() ?? "..."
            return
        }
        
        if isSleeping {
            statusMessage = "쿨쿨... 잠을 자고 있어요."
            return
        }
        
        // 우선순위에 따른 상태 메시지 (낮은 스탯 우선)
        if satietyValue < 20 {
            statusMessage = "너무 배고파요... 밥 주세요!"
        } else if activityValue < 20 {
            statusMessage = "너무 지쳐요... 쉬고 싶어요."
        } else if staminaValue < 20 {
            statusMessage = "몸이 너무 피곤해요..."
        } else if healthyValue < 30 {
            statusMessage = "몸이 아파요... 병원에 가고 싶어요."
        } else if cleanValue < 30 {
            statusMessage = "더러워요... 씻겨주세요!"
        } else if satietyValue < 50 {
            statusMessage = "조금 배고파요..."
        } else if activityValue < 50 {
            statusMessage = "좀 피곤해요..."
        } else if affectionValue < 100 {
            statusMessage = "심심해요... 놀아주세요!"
        } else if satietyValue > 80 && staminaValue > 80 && activityValue > 80 {
            statusMessage = "정말 행복해요! 감사합니다!"
        } else {
            statusMessage = "오늘도 좋은 하루에요!"
        }
    }
    
    // 캐릭터 모델의 상태 정보를 현재 ViewModel 값들로 업데이트
    private func updateCharacterStatus() {
        guard var character = character else { return }
        
        // 캐릭터 상태 업데이트
        character.status.satiety = satietyValue
        character.status.stamina = staminaValue
        character.status.activity = activityValue
        character.status.affection = affectionValue
        character.status.affectionCycle = weeklyAffectionValue
        character.status.healthy = healthyValue
        character.status.clean = cleanValue
        character.status.exp = expValue
        character.status.expToNextLevel = expMaxValue
        character.status.level = level
        
        // 캐릭터 업데이트
        self.character = character
        
        // Firestore에 저장
        saveCharacterToFirebase()
    }
    
    // 활동 날짜 업데이트 메서드 추가
    private func updateLastActivityDate() {
        lastActivityDate = Date()
        print("📅 마지막 활동 날짜 업데이트")
    }
    
    // MARK: - Level & Experience System
    
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
        expValue = 0 // 초과분 이월 없이 0으로 초기화
        
        // 새로운 성장 단계 결정
        let oldPhase = character?.status.phase
        updateGrowthPhase()
        
        // 진화 상태 업데이트
        updateEvolutionStatus()
        
        // 새 경험치 요구량 설정
        updateExpRequirement()
        
        // 퍼센트 업데이트
        expPercent = 0.0 // 0으로 초기화
        
        // 레벨업 보너스 지급
        applyLevelUpBonus()
        
        // 성장 단계가 변경되었으면 기능 해금
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
        
        // 레벨업 시 골드 획득 추가
        let goldReward = calculateLevelUpGoldReward()
        addGold(goldReward)
        
    #if DEBUG
        print("🎉 레벨업! Lv.\(level) - \(character?.status.phase.rawValue ?? "") (경험치 0으로 초기화)")
    #endif
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
    
    // 성장 단계에 따른 경험치 요구량을 업데이트
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
        // 레벨 업 시 모든 보이는 스탯 20% 회복
        let bonusAmount = isDebugMode ? (20 * debugSpeedMultiplier) : 20
        
        satietyValue = min(100, satietyValue + bonusAmount)
        staminaValue = min(100, staminaValue + bonusAmount)
        activityValue = min(100, activityValue + bonusAmount)
        
        // 히든 스탯도 약간 회복
        let hiddenBonusAmount = isDebugMode ? (10 * debugSpeedMultiplier) : 10
        healthyValue = min(100, healthyValue + hiddenBonusAmount)
        cleanValue = min(100, cleanValue + hiddenBonusAmount)
        
        // 업데이트
        updateAllPercents()
        
#if DEBUG
        print("🎁 레벨업 보너스: 보이는 스탯 +\(bonusAmount), 히든 스탯 +\(hiddenBonusAmount)")
#endif
    }
    
    // 진화 상태 업데이트 메서드
    private func updateEvolutionStatus() {
        guard var character = character else { return }
        
        // 레벨에 따라 진화 상태 변경
        switch level {
        case 0:
            character.status.evolutionStatus = .eggComplete
        case 1:
            // 레벨 1이 되면 유아기로 진화 중 상태
            character.status.evolutionStatus = .toInfant
            // 레벨 1 달성 시 부화 팝업 표시 (다음 단계에서 구현)
            showEvolutionPopup = true
        case 3:
            character.status.evolutionStatus = .toChild
        case 6:
            character.status.evolutionStatus = .toAdolescent
        case 9:
            character.status.evolutionStatus = .toAdult
        case 16:
            character.status.evolutionStatus = .toElder
        default:
            // 다른 레벨에서는 진화 상태 변경 없음
            break
        }
        
        self.character = character
        
    #if DEBUG
        print("🔄 레벨 \(level) 달성 -> 진화 상태: \(character.status.evolutionStatus.rawValue)")
    #endif
    }

    // 부화 팝업 표시 여부 (다음 단계에서 사용)
    @Published var showEvolutionPopup: Bool = false
    
    // 진화 완료 메서드
    func completeEvolution(to phase: CharacterPhase) {
        guard var character = character else { return }
        
        // 진화 상태를 완료로 변경
        switch phase {
        case .infant:
            character.status.evolutionStatus = .completeInfant
        case .child:
            character.status.evolutionStatus = .completeChild
        // ... 다른 단계들
        default:
            break
        }
        
        // 캐릭터 업데이트
        self.character = character
        updateCharacterStatus()
    }
    
    // MARK: - Action System
    
    // 액션 버튼을 현재 상태에 맞게 갱신
    private func refreshActionButtons() {
        guard let character = character else {
            // 캐릭터가 없으면 기본 액션(캐릭터 생성) 등장 설정
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
        
#if DEBUG
        print("🔄 액션 버튼 갱신됨: \(character.status.phase.rawValue) 단계 (레벨 \(character.status.level)), 잠자는 상태: \(isSleeping)")
        print("📋 현재 액션들: \(actionButtons.map { $0.name }.joined(separator: ", "))")
        print("📊 레벨별 상세 정보:")
        print("   - 현재 레벨: \(level)")
        print("   - 현재 단계: \(character.status.phase.rawValue)")
        print("   - 잠자는 상태: \(isSleeping)")
        print("   - 총 액션 수: \(actionButtons.count)")
#endif
    }
    
    // 재우기/깨우기 액션 처리
    func putPetToSleep() {
        if isSleeping {
            // 이미 자고 있으면 깨우기
            isSleeping = false
            statusMessage = "일어났어요! 이제 활동할 수 있어요!"
        } else {
            // 자고 있지 않으면 재우기
            isSleeping = true
            // 수면 시 즉시 회복 효과
            let sleepBonus = isDebugMode ? (15 * debugSpeedMultiplier) : 15
            activityValue = min(100, activityValue + sleepBonus)
            
            statusMessage = "쿨쿨... 잠을 자고 있어요."
            updateAllPercents()
        }
        
        // 수면 상태 변경 시 액션 버튼 갱신
        refreshActionButtons()
        
        // 캐릭터 모델 업데이트
        updateCharacterStatus()
        
        // 활동 날짜 업데이트
        updateLastActivityDate()
        
        // Firebase에 수면 상태 변화 기록
        let sleepChanges = ["sleep_state": isSleeping ? 1 : 0]
        recordAndSaveStatChanges(sleepChanges, reason: isSleeping ? "sleep_start" : "sleep_end")
        
#if DEBUG
        print("😴 " + (isSleeping ? "펫을 재웠습니다" : "펫을 깨웠습니다"))
#endif
    }
    
    // 인덱스를 기반으로 액션을 실행합니다.
    /// - Parameter index: 실행할 액션의 인덱스
    func performAction(at index: Int) {
        // 애니메이션 중이면 액션 수행하지 않음
        guard !isAnimationRunning else {
            print("🚫 애니메이션 실행 중: 액션 무시됨")
            return
        }
        
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
        
        // 애니메이션 시작 (액션에 따라 적절한 지속 시간 설정)
        let animationDuration = 1.0 // 기본 1초
        startAnimation(duration: animationDuration)
        
        // 액션 아이콘에 따라 해당 메서드 호출
        switch action.icon {
        case "bed.double":
            putPetToSleep()
            print(isSleeping ? "😴 펫을 재웠습니다" : "😊 펫을 깨웠습니다")
            
        default:
            // ActionManager에서 가져온 액션 처리
            if let actionId = getActionId(for: action.icon) {
                executeActionManagerAction(actionId: actionId)
            } else {
                print("❓ 알 수 없는 액션: \(action.name), 아이콘: \(action.icon)")
            }
        }
        
        // 액션 실행 후 액션 버튼 갱신
        refreshActionButtons()
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
        
        // 변화량 기록용
        var statChanges: [String: Int] = [:]
        
        // 활동량 소모
        let oldActivity = activityValue
        activityValue = max(0, activityValue - action.activityCost)
        statChanges["activity"] = activityValue - oldActivity
        
        // 액션 효과 적용
        for (statName, value) in action.effects {
            let adjustedValue = isDebugMode ? (value * debugSpeedMultiplier) : value
            
            switch statName {
            case "satiety":
                let oldValue = satietyValue
                satietyValue = max(0, min(100, satietyValue + adjustedValue))
                statChanges["satiety"] = satietyValue - oldValue
            case "stamina":
                let oldValue = staminaValue
                staminaValue = max(0, min(100, staminaValue + adjustedValue))
                statChanges["stamina"] = staminaValue - oldValue
            case "happiness", "affection":
                let oldValue = weeklyAffectionValue
                weeklyAffectionValue = max(0, min(100, weeklyAffectionValue + abs(adjustedValue)))
                statChanges["affection"] = weeklyAffectionValue - oldValue
            case "clean":
                let oldValue = cleanValue
                cleanValue = max(0, min(100, cleanValue + adjustedValue))
                statChanges["clean"] = cleanValue - oldValue
            case "healthy":
                let oldValue = healthyValue
                healthyValue = max(0, min(100, healthyValue + adjustedValue))
                statChanges["healthy"] = healthyValue - oldValue
            default:
                break
            }
        }
        
        // 경험치 획득 - 디버그 모드 배수 적용은 addExp() 메서드에서 처리
        if action.expGain > 0 {
            let oldExp = expValue
            addExp(action.expGain)
            
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
        
        // Firebase에 스탯 변화 기록
        recordAndSaveStatChanges(statChanges, reason: "action_\(actionId)")
        
        // 골드 획득 처리 추가
        let goldReward = calculateGoldReward(for: actionId)
        if goldReward > 0 {
            addGold(goldReward)
        }
        
        print("✅ '\(action.name)' 액션을 실행했습니다")
        
    #if DEBUG
        print("📊 현재 스탯 - 포만감: \(satietyValue), 운동량: \(staminaValue), 활동량: \(activityValue)")
        print("📊 히든 스탯 - 건강: \(healthyValue), 청결: \(cleanValue), 주간 애정도: \(weeklyAffectionValue)")
    #endif
    }
    
    // 액션 아이콘으로부터 ActionManager의 액션 ID를 가져옵니다.
    /// - Parameter icon: 액션 아이콘
    /// - Returns: 해당하는 액션 ID
    private func getActionId(for icon: String) -> String? {
        switch icon {
            // 운석 전용 액션들 (phaseExclusive = true)
        case "hand.tap.fill":
            return "tap_egg"
        case "flame.fill":
            return "warm_egg"
        case "bubble.left.fill":
            return "talk_egg"
            
            // 기본 액션들 (유아기 이상)
        case "fork.knife":
            return "feed"
        case "gamecontroller.fill":
            return "play"
        case "shower.fill":
            return "wash"
        case "bed.double":
            return "sleep"
            
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
#if DEBUG
            print("❓ 알 수 없는 액션 아이콘: \(icon)")
#endif
            return nil
        }
    }
    
    // MARK: - Feature Management

    // 성장 단계별 기능 해금
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
        
#if DEBUG
        print("🔓 기능 해금 업데이트: \(phase.rawValue) 단계")
#endif
    }
    
    // MARK: - Utility Methods
    
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
    
    func loadCharacter() {
        // Firebase에서 로드하도록 변경
        if firebaseService.getCurrentUserID() != nil {
            loadMainCharacterFromFirebase()
        } else {
            print("⚠️ 사용자가 로그인되지 않았습니다")
            // 로그인되지 않은 경우 로컬 캐릭터만 생성
            createAndSaveDefaultCharacter()
        }
    }
    
    // MARK: - Resource Cleanup
    
    deinit {
        cleanupResources()
        
        print("⏰ 모든 타이머 정리됨")
    }
    
    // 모든 리소스를 정리
    private func cleanupResources() {
        // 타이머 정리
        cancellables.removeAll()
        statDecreaseTimer?.invalidate()
        hiddenStatDecreaseTimer?.invalidate()
        weeklyAffectionTimer?.invalidate()
        energyTimer?.invalidate()
        
        // Firebase 리스너 정리
        characterListener?.remove()
        characterListener = nil
        saveDebounceTimer?.invalidate()
        saveDebounceTimer = nil
        
        print("🧹 모든 리소스 정리 완료")
    }
    
    @objc private func handleCharacterAddressChanged(_ notification: Notification) {
        guard let characterUUID = notification.userInfo?["characterUUID"] as? String,
              let addressRaw = notification.userInfo?["address"] as? String else {
            return
        }
        
        // 현재 보고 있는 캐릭터가 변경된 캐릭터와 같은지 확인
        if let character = self.character, character.id == characterUUID {
            // 주소가 userHome이 아니거나 space인 경우 새 메인 캐릭터 로드
            if addressRaw != "userHome" || addressRaw == "space" {
                loadMainCharacterFromFirebase()
            }
        } else {
            // 다른 캐릭터가 메인으로 설정된 경우를 대비해 메인 캐릭터 다시 로드
            loadMainCharacterFromFirebase()
        }
    }

    @objc private func handleCharacterNameChanged(_ notification: Notification) {
        guard let characterUUID = notification.userInfo?["characterUUID"] as? String,
              let newName = notification.userInfo?["name"] as? String else {
            return
        }
        
        // 현재 보고 있는 캐릭터가 변경된 캐릭터와 같은지 확인
        if var character = self.character, character.id == characterUUID {
            character.name = newName
            self.character = character
        }
    }
    
    // MARK: - 골드 보상 관련 메서드 추가
    func calculateGoldReward(for actionId: String) -> Int {
        // 재우기, 깨우기 액션은 골드 획득 제외
        if actionId == "sleep" {
            return 0
        }
        
        // 액션별 골드 획득량 설정
        let goldRewards: [String: Int] = [
            // 운석 전용 액션
            "tap_egg": 5,
            "warm_egg": 7,
            "talk_egg": 4,
            
            // 유아기 이상 액션
            "feed": 10,
            "play": 15,
            "wash": 8,
            "give_medicine": 12,
            
            // 아동기 이상 액션
            "vitamins": 10,
            
            // 청소년기 이상 액션
            "check_health": 20,
            
            // 기본값
            "default": 5
        ]
        
        // 해당 액션의 골드 획득량 반환, 없으면 기본값 반환
        return goldRewards[actionId] ?? goldRewards["default"]!
    }
    
    // 레벨업 시 골드 획득량 계산
    func calculateLevelUpGoldReward() -> Int {
        // 레벨에 따른 보상량 설정 (레벨이 높을수록 더 많은 골드 획득)
        return level * 50
    }
    
    // 골드 획득 및 Firebase 업데이트
    func addGold(_ amount: Int) {
        guard let userId = firebaseService.getCurrentUserID(), !userId.isEmpty else {
            print("⚠️ 사용자 ID가 없어 골드를 추가할 수 없습니다.")
            return
        }
        
        // 더미 ID 처리
        let realUserId = userId == "" ? "23456" : userId
        
        Task {
            do {
                // 사용자 정보 가져오기
                try await userViewModel.fetchUser(userId: realUserId)
                
                guard let currentUser = userViewModel.user else {
                    print("⚠️ 사용자 정보가 없어 골드를 추가할 수 없습니다.")
                    return
                }
                
                let newGoldAmount = currentUser.gold + amount
                
                // Firebase에 업데이트
                userViewModel.updateCurrency(userId: currentUser.id, gold: newGoldAmount)
                
                print("💰 골드 획득: \(amount) (현재: \(newGoldAmount))")
                
                // 성공 메시지 표시
                if amount > 0 {
                    await MainActor.run {
                        // statusMessage = "💰 \(amount) 골드를 획득했습니다!"
                        goldMessage = "💰 \(amount) 골드를 획득했습니다!"
                        
                        // 일정 시간 후 메시지 초기화 (옵션)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                            self?.goldMessage = ""
                        }
                    }
                }
            } catch {
                print("⚠️ 골드 업데이트 실패: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - 애니메이션 중 버튼 클릭 비활성화 기능 추가

    // 애니메이션 시작/종료 메서드
    func startAnimation(duration: Double = 1.0) {
        isAnimationRunning = true
        
        // 애니메이션 완료 후 상태 변경
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.isAnimationRunning = false
        }
    }
    
    
}
