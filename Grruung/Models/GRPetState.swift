//
//  GRPetState.swift
//  Grruung
//
//  Created by KimJunsoo on 5/6/25.
//

import Foundation

// 펫의 상태를 관리하는 모델
struct GRPetState: Codable {
    var hunger: Int // 포만감
    var happiness: Int // 행복도
    var energy: Int // 에너지/체력
    var cleanliness: Int // 청결도
    var health: Int // 건강
    var affection: Int // 애정도
    var lastInteraction: Date
}
