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
    }
    
    // MARK: - 5. 음성 메시지 전송
    func sendVoiceMessage() {
        
    }
    
    // MARK: - 6. 펫 응답 생성 (테스트용)
    private func generatePetResponse() {
        
    }
    
    // MARK: - 7. 펫 응답 생성 로직 (테스트용)
    private func createPetResponse() {
        
    }
    
    // MARK: - 8. 텍스트를 음성으로 변환
    func speakText() {
        
    }
    
    // MARK: - 9. 성장 단계 변경 (테스트용)
    func changePetPhase() {
        
    }
    
    // MARK: - 10. 종 변경 (테스트용)
    func changePetSpecies() {
        
    }
    
}
