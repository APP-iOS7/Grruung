//
//  HomeViewModel.swift
//  Grruung
//
//  Created by KimJunsoo on 5/7/25.
//

import Foundation
import Combine

/// 홈 화면을 위한 ViewModel
class HomeViewModel: ObservableObject {
    // MARK: - 0. 바인딩 프로퍼티
    @Published var characters: [GRCharacter] = []
    @Published var selectedCharacter: GRCharacter?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // 상태 표시용 프로퍼티
    @Published var satietyPercent: CGFloat = 0.5
    @Published var staminaPercent: CGFloat = 0.5
    @Published var activityPercent: CGFloat = 0.5
    @Published var expPercent: CGFloat = 0.5
    
    // 테스트 모드 프로퍼티
    @Published var testMode: Bool = false
    @Published var testSpecies: PetSpecies = .ligerCat
    @Published var testPhase: CharacterPhase = .infant
    
    // 서비스
    private let firebaseService = FirebaseService.shared
    
    // 구독 취소용 객체
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 1. 이닛
    init() {
        setupBindings()
    }
    
    // MARK: - 2. 바인딩 설정
    private func setupBindings() {
        // 선택된 캐릭터 변경 시 상태 퍼센트 업데이트
        $selectedCharacter
            .compactMap { $0 }
            .sink { [weak self] character in
                guard let self = self else { return }
                self.updateStatusPercentages(character.status)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 3. 데이터 로드 메서드
    
    /// 사용자의 모든 캐릭터 목록을 로드합니다.
    func loadCharacters() {
        isLoading = true
        errorMessage = nil
        
        firebaseService.fetchUserCharacters { [weak self] characters, error in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }
            
            if let characters = characters {
                self.characters = characters
                
                // 선택된 캐릭터가 없으면 첫 번째 캐릭터 선택
                if self.selectedCharacter == nil && !characters.isEmpty {
                    self.selectedCharacter = characters[0]
                }
            }
        }
    }
    
    /// 테스트용 캐릭터를 생성하고 선택합니다.
    func createTestCharacter() {
        let name = testSpecies == .ligerCat ? "냥냥이" : "꾸꾸"
        let status = GRCharacterStatus(
            level: levelForPhase(testPhase),
            phase: testPhase,
            satiety: 70,
            stamina: 60,
            activity: 80,
            affection: 90,
            healthy: 85,
            clean: 75
        )
        
        let character = GRCharacter(
            species: testSpecies,
            name: name,
            image: "\(testSpecies.rawValue)_\(testPhase.rawValue)",
            status: status
        )
        
        selectedCharacter = character
        
        // 테스트 모드 설정
        testMode = true
    }
    
    /// 캐릭터 성장 단계에 맞는 레벨을 반환합니다.
    private func levelForPhase(_ phase: CharacterPhase) -> Int {
        switch phase {
        case .egg:
            return 0
        case .infant:
            return 1
        case .child:
            return 3
        case .adolescent:
            return 6
        case .adult:
            return 9
        case .elder:
            return 16
        }
    }
    
    // MARK: - 4. 상태 업데이트 메서드
    
    /// 캐릭터 상태를 업데이트합니다.
    func updateSelectedCharacter(satiety: Int? = nil, stamina: Int? = nil, activity: Int? = nil,
                                 affection: Int? = nil, healthy: Int? = nil, clean: Int? = nil) {
        guard var character = selectedCharacter else { return }
        
        // 상태 업데이트
        character.updateStatus(
            satiety: satiety,
            stamina: stamina,
            activity: activity,
            affection: affection,
            healthy: healthy,
            clean: clean
        )
        
        // 선택된 캐릭터 갱신
        selectedCharacter = character
        
        // 테스트 모드가 아닌 경우에만 저장
        if !testMode {
            saveSelectedCharacter()
        }
    }
    
    /// 선택된 캐릭터를 Firestore에 저장합니다.
    func saveSelectedCharacter() {
        guard let character = selectedCharacter else { return }
        
        isLoading = true
        errorMessage = nil
        
        firebaseService.saveCharacter(character) { [weak self] error in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    /// 캐릭터에게 경험치를 추가합니다.
    func addExperience(_ amount: Int) {
        guard var character = selectedCharacter else { return }
        
        // 경험치 추가
        character.addExp(amount)
        
        // 선택된 캐릭터 갱신
        selectedCharacter = character
        
        // 테스트 모드가 아닌 경우에만 저장
        if !testMode {
            saveSelectedCharacter()
        }
    }
    
    // MARK: - 5. 상태 표시 메서드
    
    /// 캐릭터 상태에 따라 상태 퍼센트를 업데이트합니다.
    private func updateStatusPercentages(_ status: GRCharacterStatus) {
        satietyPercent = CGFloat(status.satiety) / 100.0
        staminaPercent = CGFloat(status.stamina) / 100.0
        activityPercent = CGFloat(status.activity) / 100.0
        
        // 경험치 퍼센트 계산
        if status.expToNextLevel > 0 {
            expPercent = CGFloat(status.exp) / CGFloat(status.expToNextLevel)
        } else {
            expPercent = 1.0
        }
    }
    
    /// 선택된 캐릭터의 상태 메시지를 반환합니다.
    func getStatusMessage() -> String {
        guard let character = selectedCharacter else {
            return "캐릭터를 선택해주세요."
        }
        
        return character.getStatusMessage()
    }
    
    // MARK: - 6. 채팅 관련 메서드
    
    /// 채팅 화면으로 이동하기 위한 챗펫 프롬프트를 생성합니다.
    func generateChatPetPrompt() -> String? {
        guard let character = selectedCharacter else { return nil }
        
        let petPrompt = PetPrompt(
            petType: character.species,
            phase: character.status.phase,
            name: character.name
        )
        
        return petPrompt.generatePrompt(status: character.status)
    }
}
