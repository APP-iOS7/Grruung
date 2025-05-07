//
//  ChatViewModel.swift
//  Grruung
//
//  Created by KimJunsoo on 5/7/25.
//

import Foundation
import Combine
import AVFoundation
import FirebaseVertexAI

// MARK: - 0. 채팅 뷰모델 클래스
class ChatViewModel: ObservableObject {
    // MARK: - 1. 프로퍼티
    @Published var messages: [ChatMessage] = []
    @Published var inputMessage: String = ""
    @Published var isLoading: Bool = false
    @Published var currentPet: GRPet
    @Published var isSpeaking: Bool = false
    @Published var showSubtitles: Bool = true
    @Published var isVoiceMode: Bool = false
    @Published var isMaleVoice: Bool = true
    
    private var cancellables: Set<AnyCancellable> = []
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var chatModel: GenerativeModel?
    private var chatSession: ChatSession?
    
    // MARK: - 2. 초기화
    init(pet: GRPet) {
        self.currentPet = pet
        
        self.messages = ChatMessage.sampleMessage()
        
        setupChatModel()
    }
    
    // MARK: - 3. Vertex AI 모델 설정
    private func setupChatModel() {
        // TODO: Firebase Vertex AI 연결
        // 테스트용으로만 구현
    }
    
    // MARK: - 4. 메시지 전송 처리
    func sendMessage() {
        guard !inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let userMessage = ChatMessage(content: inputMessage, sender: .user)
        messages.append(userMessage)
        
        let messageToSend = inputMessage
        inputMessage = ""
        isLoading = true
        
        // TODO: Vertex AI로 변경
        generatePetResponse(to: messageToSend)
    }
    
    // MARK: - 5. 음성 메시지 전송
    func sendVoiceMessage(text: String) {
        let userMessage = ChatMessage(content: text, sender: .user, isAudioMessage: true)
        messages.append(userMessage)
        
        isLoading = true
        generatePetResponse(to: text)
    }
    
    // MARK: - 6. 펫 응답 생성 (테스트용)
    private func generatePetResponse(to message: String) {
        // TODO: Vertex AI로 변경
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            let responseText = self.createPetResponse(to: message)
            let petMessage = ChatMessage(content: responseText, sender: .pet)
            self.messages.append(petMessage)
            self.isLoading = false
            
            // 음성 모드이거나 자막이 활성화된 경우 텍스트를 음성으로 변환
            if self.isVoiceMode || self.showSubtitles {
                self.speakText(responseText)
            }
        }
    }
    
    // MARK: - 7. 펫 응답 생성 로직 (테스트용)
    private func createPetResponse(to message: String) -> String {
        // 현재 펫의 종류와 성장 단계에 따라 다른 응답을 생성
        let phase = currentPet.status.phase
        let species = currentPet.species
        
        // 간단한 응답 패턴
        let infantResponses = [
            "냥냥! 반가워요~",
            "어흥? 뭐라고 하셨어요?",
            "냥! 배고파요...",
            "꾸잉! 놀아주세요!"
        ]
        
        let childResponses = [
            "냥냥~ 오늘 정말 재미있어요!",
            "어흥! 주인님과 놀고 싶어요!",
            "그르릉~ 배고픈데 간식 있어요?",
            "꾸잉! 같이 놀아요! 재미있을 것 같아요!"
        ]
        
        let adolescentResponses = [
            "그르릉~ 주인님 오늘 어떻게 지내셨어요?",
            "히히! 주인님이랑 같이 있어서 행복해요!",
            "냥! 오늘 뭐하고 놀까요?",
            "꾸잉! 재미있는 이야기 들려주세요!"
        ]
        
        let adultResponses = [
            "그르릉... 주인님, 오늘 하루는 어떠셨나요?",
            "주인님, 제가 도와드릴 일이 있을까요?",
            "오늘 날씨가 참 좋네요. 산책이라도 가면 어떨까요?",
            "꾸잉! 항상 웃음 가득한 하루 되세요!"
        ]
        
        let seniorResponses = [
            "흠냥흠냥... 주인님, 오늘도 건강하신 하루 되셨나요?",
            "그르릉... 주인님과 함께한 시간들이 참 소중하네요.",
            "오랜 세월을 함께해서 정말 행복합니다.",
            "꾸잉... 단순한 일상의 행복이 가장 큰 행복인 것 같아요."
        ]
        
        // 펫 종류에 따른 응답 접두사 (라이거/쿼카)
        let prefix = species == .liger ? (phase == .senior ? "흠냥흠냥..." : "냥! ") : "꾸잉! "
        
        // 성장 단계에 따른 응답 선택
        var responses: [String]
        switch phase {
        case .egg:
            return "..." // 알은 말을 하지 않음
        case .infant:
            responses = infantResponses
        case .child:
            responses = childResponses
        case .adolescent:
            responses = adolescentResponses
        case .adult:
            responses = adultResponses
        case .senior:
            responses = seniorResponses
        }
        
        // 메시지에 '배고파'가 포함되어 있으면 특별 응답
        if message.contains("배고파") {
            if phase == .infant || phase == .child {
                return prefix + "배고파요! 밥 주세요!"
            } else {
                return prefix + "네, 조금 배가 고픈 것 같아요. 무언가 먹을 것이 있을까요?"
            }
        }
        
        // 랜덤 응답 선택
        let randomResponse = responses.randomElement() ?? "안녕하세요!"
        return randomResponse
    }
    
    // MARK: - 8. 텍스트를 음성으로 변환
    func speakText(_ text: String) {
        // 현재 말하고 있다면 중지
        if isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        
        // 음성 선택 (남성/여성)
        let voice: AVSpeechSynthesisVoice?
        if isMaleVoice {
            voice = AVSpeechSynthesisVoice(language: "ko-KR")
        } else {
            voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Yuna-compact") ?? AVSpeechSynthesisVoice(language: "ko-KR")
        }
        
        utterance.voice = voice
        
        // 펫 성장 단계에 따라 음성 속도와 피치 조절
        switch currentPet.status.phase {
        case .egg:
            // 알은 말하지 않음
            return
        case .infant:
            utterance.rate = 0.5 // 느리게
            utterance.pitchMultiplier = 1.5 // 높은 음
        case .child:
            utterance.rate = 0.55
            utterance.pitchMultiplier = 1.3
        case .adolescent:
            utterance.rate = 0.6
            utterance.pitchMultiplier = 1.1
        case .adult:
            utterance.rate = 0.5
            utterance.pitchMultiplier = 1.0
        case .senior:
            utterance.rate = 0.4 // 아주 느리게
            utterance.pitchMultiplier = 0.9 // 낮은 음
        }
        
        isSpeaking = true
        speechSynthesizer.speak(utterance)
        
        // 음성 합성 완료 알림을 위한 Notification 등록
        NotificationCenter.default.publisher(for: AVSpeechSynthesizer.didFinishSpeechUtteranceNotification, object: speechSynthesizer)
            .sink { [weak self] _ in
                self?.isSpeaking = false
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 9. 성장 단계 변경 (테스트용)
    func changePetPhase(_ phase: PetPhase) {
        var updatedPet = currentPet
        
        // 설정된 성장 단계에 맞게 레벨 조정
        switch phase {
        case .egg:
            updatedPet.status.level = 0
        case .infant:
            updatedPet.status.level = 1
        case .child:
            updatedPet.status.level = 3
        case .adolescent:
            updatedPet.status.level = 6
        case .adult:
            updatedPet.status.level = 9
        case .senior:
            updatedPet.status.level = 16
        }
        
        updatedPet.status.phase = phase
        currentPet = updatedPet
    }
    
    // MARK: - 10. 종 변경 (테스트용)
    func changePetSpecies(_ species: PetSpecies) {
        var updatedPet = currentPet
        updatedPet.species = species
        currentPet = updatedPet
    }
}
