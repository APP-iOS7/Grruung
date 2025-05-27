//
//  ActionManager.swift
//  Grruung
//
//  Created by KimJunsoo on 5/22/25.
//

import Foundation

// 펫 액션 관리를 위한 클래스
class ActionManager {
    // 사용 가능한 모든 액션 목록
    private(set) var allActions: [PetAction] = []
    
    static let shared = ActionManager()
    
    private init() {
        setupActions()
    }
    
    // 기본 액션 설정
    private func setupActions() {
        allActions = [
            // 운석 전용 액션
            // phaseExclusive = true시 그 단계에서만 사용가능한 활동 액션 등장
            PetAction(
                id: "tap_egg",
                icon: "hand.tap.fill",
                name: "두드리기",
                unlockPhase: .egg,
                phaseExclusive: true, // 운석 단계에서만 사용 가능
                activityCost: 1,
                effects: ["stamina": 0], // 실제 스탯 변화 없음
                expGain: 5, // 많은 경험치 획득 (빠른 부화를 위해)
                successMessage: "두드리니 안에서 무언가 움직이는 것 같아요!",
                failMessage: "더 이상 반응이 없어요...",
                timeRestriction: nil
            ),
            PetAction(
                id: "warm_egg",
                icon: "flame.fill",
                name: "따뜻하게",
                unlockPhase: .egg,
                phaseExclusive: true, // 운석 단계에서만 사용 가능
                activityCost: 2,
                effects: ["stamina": 0], // 실제 스탯 변화 없음
                expGain: 7, // 많은 경험치 획득 (빠른 부화를 위해)
                successMessage: "알이 따뜻해지니 기분이 좋아보여요!",
                failMessage: "더 이상 반응이 없어요...",
                timeRestriction: nil
            ),
            PetAction(
                id: "talk_egg",
                icon: "bubble.left.fill",
                name: "말걸기",
                unlockPhase: .egg,
                phaseExclusive: true, // 운석 단계에서만 사용 가능
                activityCost: 1,
                effects: ["stamina": 0], // 실제 스탯 변화 없음
                expGain: 4, // 많은 경험치 획득 (빠른 부화를 위해)
                successMessage: "알이 살짝 흔들리는 것 같아요!",
                failMessage: "더 이상 반응이 없어요...",
                timeRestriction: nil
            ),
            
            // 모든 단계 공통 액션
            PetAction(
                id: "sleep",
                icon: "bed.double",
                name: "재우기",
                unlockPhase: .egg, // 모든 단계에서 사용 가능
                phaseExclusive: false,
                activityCost: 0, // 활동량 소모 없음
                effects: ["stamina": 10],
                expGain: 1,
                successMessage: "쿨쿨... 잠을 자고 있어요.",
                failMessage: "",
                timeRestriction: TimeRestriction(startHour: 22, endHour: 6, isInverted: true)
            ),
            
            // 유아기 이상 액션
            PetAction(
                id: "feed",
                icon: "fork.knife",
                name: "밥주기",
                unlockPhase: .infant, // 유아기부터 사용 가능
                phaseExclusive: true,
                activityCost: 5,
                effects: ["satiety": 15, "stamina": 5, "happiness": 3],
                expGain: 3,
                successMessage: "냠냠! 맛있어요!",
                failMessage: "너무 지쳐서 먹을 힘도 없어요...",
                timeRestriction: nil
            ),
            PetAction(
                id: "play",
                icon: "gamecontroller.fill",
                name: "놀아주기",
                unlockPhase: .infant, // 유아기부터 사용 가능
                phaseExclusive: true,
                activityCost: 10,
                effects: ["happiness": 12, "stamina": -8, "satiety": -5],
                expGain: 5,
                successMessage: "우와! 너무 재밌어요!",
                failMessage: "너무 지쳐서 놀 수 없어요...",
                timeRestriction: nil
            ),
            PetAction(
                id: "wash",
                icon: "shower.fill",
                name: "씻기기",
                unlockPhase: .infant, // 유아기부터 사용 가능
                phaseExclusive: true,
                activityCost: 7,
                effects: ["clean": 15, "healthy": 5, "happiness": 2, "stamina": -3],
                expGain: 4,
                successMessage: "깨끗해져서 기분이 좋아요!",
                failMessage: "너무 지쳐서 씻기 힘들어요...",
                timeRestriction: nil
            ),
            PetAction(
                id: "give_medicine",
                icon: "pills.fill",
                name: "감기약",
                unlockPhase: .infant,
                phaseExclusive: true,
                activityCost: 3,
                effects: ["healthy": 20, "stamina": -2],
                expGain: 2,
                successMessage: "약을 먹고 몸이 좋아졌어요!",
                failMessage: "너무 지쳐서 약을 먹기 힘들어요...",
                timeRestriction: nil
            ),

            PetAction(
                id: "vitamins",
                icon: "capsule.fill",
                name: "영양제",
                unlockPhase: .child,
                phaseExclusive: true,
                activityCost: 2,
                effects: ["healthy": 15, "stamina": 5, "satiety": 3],
                expGain: 3,
                successMessage: "영양제로 건강해졌어요!",
                failMessage: "컨디션이 안 좋아서 영양제를 거부해요...",
                timeRestriction: nil
            ),

            PetAction(
                id: "check_health",
                icon: "stethoscope",
                name: "건강 검진",
                unlockPhase: .adolescent,
                phaseExclusive: true,
                activityCost: 8,
                effects: ["healthy": 25, "happiness": -5], // 병원이라 약간 스트레스
                expGain: 5,
                successMessage: "건강 검진 결과 아주 건강해요!",
                failMessage: "너무 지쳐서 병원에 갈 수 없어요...",
                timeRestriction: TimeRestriction(startHour: 9, endHour: 18, isInverted: false) // 병원 운영시간
            ),

            // MARK: - 기타 관련 액션들
            PetAction(
                id: "weather_sunny",
                icon: "sun.max.fill",
                name: "날씨좋기",
                unlockPhase: .infant,
                phaseExclusive: true,
                activityCost: 0, // 날씨는 활동량 소모 없음
                effects: ["happiness": 8, "stamina": 3],
                expGain: 2,
                successMessage: "좋은 날씨에 기분이 좋아져요!",
                failMessage: "",
                timeRestriction: TimeRestriction(startHour: 6, endHour: 18, isInverted: false) // 낮 시간만
            ),

            PetAction(
                id: "walk_together",
                icon: "figure.walk",
                name: "같이 걷기",
                unlockPhase: .child,
                phaseExclusive: true,
                activityCost: 12,
                effects: ["happiness": 15, "healthy": 10, "stamina": -6, "satiety": -8],
                expGain: 6,
                successMessage: "함께 산책하니 정말 즐거워요!",
                failMessage: "너무 지쳐서 산책할 힘이 없어요...",
                timeRestriction: nil
            ),

            PetAction(
                id: "rest_together",
                icon: "figure.seated.side",
                name: "같이 쉬기",
                unlockPhase: .infant,
                phaseExclusive: true,
                activityCost: 0,
                effects: ["stamina": 12, "happiness": 8],
                expGain: 3,
                successMessage: "함께 쉬니까 편안해요!",
                failMessage: "",
                timeRestriction: nil
            ),

            // MARK: - 장소 관련 액션들
            PetAction(
                id: "go_home",
                icon: "house.fill",
                name: "집가기",
                unlockPhase: .infant,
                phaseExclusive: true,
                activityCost: 5,
                effects: ["happiness": 10, "stamina": 5, "clean": 3],
                expGain: 2,
                successMessage: "집에 돌아와서 안전해요!",
                failMessage: "너무 지쳐서 집에 갈 힘이 없어요...",
                timeRestriction: nil
            ),

            PetAction(
                id: "go_outside",
                icon: "tree.fill",
                name: "외출하기",
                unlockPhase: .child,
                phaseExclusive: true,
                activityCost: 8,
                effects: ["happiness": 12, "stamina": -3, "satiety": -5],
                expGain: 4,
                successMessage: "밖에 나가니까 신나요!",
                failMessage: "너무 지쳐서 나갈 힘이 없어요...",
                timeRestriction: TimeRestriction(startHour: 7, endHour: 19, isInverted: false) // 외출 가능 시간
            ),

            // MARK: - 감정 관리 액션들
            PetAction(
                id: "comfort",
                icon: "hand.raised.fill",
                name: "달래주기",
                unlockPhase: .infant,
                phaseExclusive: true,
                activityCost: 3,
                effects: ["happiness": 15, "stamina": 2],
                expGain: 4,
                successMessage: "달래주니까 기분이 좋아져요!",
                failMessage: "너무 지쳐서 달래기 어려워요...",
                timeRestriction: nil
            ),

            PetAction(
                id: "encourage",
                icon: "hands.clap.fill",
                name: "응원하기",
                unlockPhase: .child,
                phaseExclusive: true,
                activityCost: 4,
                effects: ["happiness": 18, "stamina": 5],
                expGain: 5,
                successMessage: "응원해주니까 힘이 나요!",
                failMessage: "너무 지쳐서 응원받을 기력이 없어요...",
                timeRestriction: nil
            ),

            // MARK: - 청결 관리 액션들 (확장)
            PetAction(
                id: "brush_fur",
                icon: "comb.fill",
                name: "털빗기",
                unlockPhase: .infant,
                phaseExclusive: true,
                activityCost: 5,
                effects: ["clean": 12, "happiness": 6, "stamina": -2],
                expGain: 3,
                successMessage: "털을 빗어주니까 깔끔해져요!",
                failMessage: "너무 지쳐서 가만히 있을 수 없어요...",
                timeRestriction: nil
            ),

            PetAction(
                id: "full_grooming",
                icon: "sparkles",
                name: "그루밍",
                unlockPhase: .adolescent,
                phaseExclusive: true,
                activityCost: 10,
                effects: ["clean": 25, "healthy": 8, "happiness": 10, "stamina": -5],
                expGain: 6,
                successMessage: "완벽한 그루밍으로 멋져졌어요!",
                failMessage: "너무 지쳐서 그루밍을 받을 수 없어요...",
                timeRestriction: nil
            ),

            // MARK: - 특별 액션들
            PetAction(
                id: "special_training",
                icon: "figure.strengthtraining.traditional",
                name: "특별훈련",
                unlockPhase: .adolescent,
                phaseExclusive: true,
                activityCost: 15,
                effects: ["healthy": 15, "stamina": -12, "satiety": -10, "happiness": 8],
                expGain: 12,
                successMessage: "특별 훈련으로 더욱 강해졌어요!",
                failMessage: "특별 훈련을 받기엔 너무 지쳐있어요...",
                timeRestriction: TimeRestriction(startHour: 9, endHour: 17, isInverted: false) // 훈련소 운영시간
            ),

            PetAction(
                id: "party",
                icon: "party.popper.fill",
                name: "파티하기",
                unlockPhase: .child,
                phaseExclusive: true,
                activityCost: 12,
                effects: ["happiness": 25, "stamina": -10, "satiety": -8],
                expGain: 8,
                successMessage: "파티가 너무 즐거워요!",
                failMessage: "파티할 기력이 없어요...",
                timeRestriction: TimeRestriction(startHour: 18, endHour: 22, isInverted: false) // 저녁 파티 시간
            ),

            PetAction(
                id: "hot_spring",
                icon: "drop.fill",
                name: "온천가기",
                unlockPhase: .adult,
                phaseExclusive: true,
                activityCost: 8,
                effects: ["healthy": 20, "clean": 18, "happiness": 15, "stamina": 8],
                expGain: 7,
                successMessage: "온천에서 몸과 마음이 편안해졌어요!",
                failMessage: "온천에 갈 컨디션이 아니에요...",
                timeRestriction: nil
            )
            // 여기에 더 많은 액션 추가 가능
            // ..
            // ..
        ]
    }
    
    // 현재 성장 단계에서 사용 가능한 액션 목록 가져오기
    func getAvailableActions(phase: CharacterPhase, isSleeping: Bool) -> [PetAction] {
        // 현재 성장 단계에서 사용 가능한 액션만 필터링
        return allActions.filter { action in
            // 단계 조건 확인
            let phaseCondition: Bool
            
            if action.phaseExclusive {
                // 단계 전용 액션인 경우 해당 단계에서만 사용 가능
                phaseCondition = action.unlockPhase == phase
            } else {
                // 일반 액션인 경우 해당 단계 이상에서 사용 가능
                phaseCondition = action.unlockPhase.rawValue <= phase.rawValue
            }
            
            // 자는 상태에서는 깨우기 액션만 사용 가능
            if isSleeping {
                return phaseCondition && action.id == "sleep"
            }
            
            return phaseCondition
        }
    }
    
    // 시간대에 맞는 액션 목록 가져오기
    func getTimeFilteredActions(actions: [PetAction], hour: Int) -> [PetAction] {
        return actions.filter { action in
            // 시간 제한이 없으면 항상 표시
            guard let restriction = action.timeRestriction else { return true }
            return restriction.isTimeAllowed(hour: hour)
        }
    }
    
    // 현재 시간, 성장 단계에 맞는 액션 버튼 목록 가져오기
    func getActionsButtons(phase: CharacterPhase, isSleeping: Bool, count: Int = 4) -> [ActionButton] {
        // 현재 시간
        let hour = Calendar.current.component(.hour, from: Date())
        
        // 사용 가능한 액션 목록
        var availableActions = getAvailableActions(phase: phase, isSleeping: false)
        
        // 시간 필터링 (자는 상태가 아닐 때만)
        if !isSleeping {
            availableActions = getTimeFilteredActions(actions: availableActions, hour: hour)
        }
        
        // 결과 액션 목록
        var result: [PetAction] = []
        
        // 재우기/깨우기 액션 처리
        if let sleepAction = allActions.first(where: { $0.id == "sleep" }) {
            // 자고 있는 경우 깨우기 액션으로 변경
            let modifiedSleepAction = isSleeping ? sleepAction.withUpdatedName("깨우기") : sleepAction
            result.append(modifiedSleepAction)
        }
        
        // 나머지 액션 랜덤하게 추가
        if !isSleeping {
            let otherActions = availableActions.filter { $0.id != "sleep" }
            let randomActions = otherActions.shuffled().prefix(count - result.count)
            result.append(contentsOf: randomActions)
        }
        
        // ActionButton으로 변환
        return result.map { action in
            ActionButton(
                icon: action.icon,
                name: action.name,
                unlocked: true,
                actionId: action.id
            )
        }
    }
    
    // ID로 액션 찾기
    func getAction(id: String) -> PetAction? {
        return allActions.first { $0.id == id }
    }
}
