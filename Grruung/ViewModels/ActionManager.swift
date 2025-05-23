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
                effects: ["energy": 0], // 실제 스탯 변화 없음
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
                effects: ["energy": 0], // 실제 스탯 변화 없음
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
                effects: ["energy": 0], // 실제 스탯 변화 없음
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
                effects: ["energy": 10],
                expGain: 1,
                successMessage: "쿨쿨... 잠을 자고 있어요.",
                failMessage: "",
                timeRestriction: TimeRestriction(startHour: 20, endHour: 6, isInverted: false)
            ),
            
            // 유아기 이상 액션
            PetAction(
                id: "feed",
                icon: "fork.knife",
                name: "밥주기",
                unlockPhase: .infant, // 유아기부터 사용 가능
                phaseExclusive: false,
                activityCost: 5,
                effects: ["satiety": 15, "energy": 5, "happiness": 3],
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
                phaseExclusive: false,
                activityCost: 10,
                effects: ["happiness": 12, "energy": -8, "satiety": -5],
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
                phaseExclusive: false,
                activityCost: 7,
                effects: ["clean": 15, "healthy": 5, "happiness": 2, "energy": -3],
                expGain: 4,
                successMessage: "깨끗해져서 기분이 좋아요!",
                failMessage: "너무 지쳐서 씻기 힘들어요...",
                timeRestriction: nil
            ),
            
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
