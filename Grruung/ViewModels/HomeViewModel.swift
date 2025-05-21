//
//  HomeViewModel.swift
//  Grruung
//
//  Created by KimJunsoo on 5/21/25.
//

import Foundation


class HomeViewModel: ObservableObject {
    // MARK: - Published 속성
    @Published var satietyValue: Int = 50 // 포만감
    @Published var satietyPercent: CGFloat = 0.5
    
    @Published var energyValue: Int = 50 // 에너지
    @Published var energyPercent: CGFloat = 0.5
    
    @Published var happinessValue: Int = 50 // 행복도
    @Published var happinessPercent: CGFloat = 0.5
    
    @Published var cleanValue: Int = 50 // 청결도
    @Published var cleanPercent: CGFloat = 0.5
    
    @Published var expValue: Int = 0 // 경험치
    @Published var expMaxValue: Int = 100
    @Published var expPercent: CGFloat = 0.0
    
    @Published var isSleeping: Bool = false // 잠자기 상태
    @Published var statusMessage: String = "안녕하세요!" // 상태 메시지
    
    init() {
        updateAllPercents()
    }
    
    // MARK: - 내부 메서드
    private func updateAllPercents() {
        satietyPercent = CGFloat(satietyValue) / 100.0
        energyPercent = CGFloat(energyValue) / 100.0
        happinessPercent = CGFloat(happinessValue) / 100.0
        cleanPercent = CGFloat(cleanValue) / 100.0
        expPercent = CGFloat(expValue) / CGFloat(expMaxValue)
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
            // 레벨업 로직은 나중에 추가
            expValue = expValue - expMaxValue
            expMaxValue += 50 // 다음 레벨은 더 많은 경험치 필요
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
    }
    
    // 2. 놀아주기
    func playWithPet() {
        guard !isSleeping else { return }
        
        happinessValue = min(100, happinessValue + 12)
        energyValue = max(0, energyValue - 8)
        satietyValue = max(0, satietyValue - 5)
        
        addExp(5)
        updateAllPercents()
    }
    
    // 3. 씻기기
    func washPet() {
        guard !isSleeping else { return }
        
        cleanValue = min(100, cleanValue + 15)
        happinessValue = min(100, happinessValue + 5)
        energyValue = max(0, energyValue - 3)
        
        addExp(4)
        updateAllPercents()
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
            
            // 실제 앱에서는 Timer나 비동기 처리로 자는 시간 구현
            // 간단한 데모 버전에서는 사용자가 수동으로 깨워야 함
        }
    }
}

