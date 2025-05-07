//
//  GRCharacter.swift
//  Grruung
//
//  Created by mwpark on 5/1/25.
//

import SwiftUICore

/// 캐릭터 정보를 담는 구조체
struct GRCharacter: Identifiable, Hashable {
    
    /// 고유 식별자 (자동 생성)
    let id: UUID = UUID()
    
    /// 종
    var species: String
    
    /// 이름
    var name: String
    
    /// 이미지 파일 이름 (SF Symbol 또는 Asset 이름)
    var imageName: String
    
    /// 생일
    var birthDate: Date
    
    /// 캐릭터 상태 정보
    var grCharacterStatus: GRCharacterStatus
    
    /// 캐릭터 고유 UUID (자동 생성)
    var characterUUID: UUID {
        return id
    }
    
    /// 두 캐릭터가 같은지 비교 (id 기준)
    static func == (lhs: GRCharacter, rhs: GRCharacter) -> Bool {
        lhs.id == rhs.id
    }
    
    /// 해시 값 생성 (id 기준)
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    init(species: String, name: String, imageName: String, birthDate: Date = Date()) {
        self.species = species
        self.name = name
        self.imageName = imageName
        self.birthDate = birthDate
        self.grCharacterStatus = GRCharacterStatus()
    }
}
