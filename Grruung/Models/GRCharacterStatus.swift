//
//  GRCharacterStatus.swift
//  Grruung
//
//  Created by mwpark on 5/7/25.
//

import Foundation

struct GRCharacterStatus {
    // MARK: - 유저에게 보이는 데이터
    /// 캐릭터의 현재 레벨
    /// - 0: 운석
    /// - 1~2: 유아기
    /// - 3~5: 소아기
    /// - 6~8: 청년기
    /// - 9~15: 성년기
    /// - 16~99: 노년기
    var level: Int = 0
    
    /// 현재 경험치
    var exp: Int = 0
    
    /// 다음 레벨까지 남은 경험치
    var expToNextLevel: Int = 0
    
    /// 현재 시기
    var phase: String = "운석"
    
    /// 포만감 (레벨 * 50, 예: 레벨 1이면 50)
    var saiety: Int = 0
    
    /// 체력
    var stamina: Int = 0
    
    /// 운동량 / 활동량
    var activity: Int = 0
    
    /// 거주지
    var address: String = ""
    
    /// 외모
    var appearance: String = ""
    
    
    // MARK: - 유저에게 보이지 않는 데이터
    /// 주기별 애정도
    var affectionCycle: Int = 0
    
    /// 펫 애정도
    var affectionEntry: Int = 0
    
    /// 건강도
    var healthy: Int = 0
    
    /// 청결도
    var clean: Int = 0
}
