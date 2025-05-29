//
//  BundleAnimationLoader.swift
//  Grruung
//
//  Created by NoelMacMini on 5/29/25.
//

import SwiftUI

class BundleAnimationLoader: ObservableObject {
    
    // MARK: - 단일 이미지 로드 (첫 번째 프레임)
    static func loadFirstFrame(
        characterType: String,
        phase: CharacterPhase,
        animationType: String = "normal"
    ) -> UIImage? {
        
        // 파일 경로 구성 (예: "quokka_egg_normal_001")
        let phaseString = phaseToString(phase)
        let fileName = "\(characterType)_\(phaseString)_\(animationType)_001"
        
        // Bundle에서 이미지 찾기 (png 우선, 없으면 jpg)
        if let image = UIImage(named: fileName) {
            print("이미지 로드 성공: \(fileName)")
            return image
        } else if let image = UIImage(named: "\(fileName).png") {
            print("이미지 로드 성공: \(fileName).png")
            return image
        } else if let image = UIImage(named: "\(fileName).jpg") {
            print("이미지 로드 성공: \(fileName).jpg")
            return image
        } else {
            print("이미지 로드 실패: \(fileName)")
            return nil
        }
    }
    
    // MARK: - 캐릭터 타입을 문자열로 변환
    static func characterTypeToString(_ species: PetSpecies) -> String {
        switch species {
        case .quokka:
            return "quokka"
        case .CatLion:
            return "catlion"
        case .Undefined:
            return "egg" // 기본값
        }
    }
    
    // MARK: - 성장 단계를 문자열로 변환
    static func phaseToString(_ phase: CharacterPhase) -> String {
        switch phase {
        case .egg:
            return "egg"
        case .infant:
            return "infant"
        case .child:
            return "child"
        case .adolescent:
            return "adolescent"
        case .adult:
            return "adult"
        case .elder:
            return "elder"
        }
    }
}
