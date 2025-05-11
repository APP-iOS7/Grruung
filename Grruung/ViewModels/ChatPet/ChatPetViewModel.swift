//
//  ChatPetViewModel.swift
//  Grruung
//
//  Created by KimJunsoo on 5/7/25.
//

import Foundation
import Combine

// 챗펫(AI 반려동물) 대화를 위한 ViewModel
class ChatPetViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showSubtitle: Bool = true
    @Published var voiceGender: SpeechService.VoiceGender = .female
    @Published var voiceType: SpeechService.VoiceType = .human
    @Published var isSpeaking: Bool = false
    @Published var isListening: Bool = false
    @Published var speechEnabled: Bool = false
    
    // 서비스
    private let vertexService = VertexAIService.shared
    private let firebaseService = FirebaseService.shared
    private let speechService = SpeechService.shared
    
    // 프롬프트 및 캐릭터 정보
    private var prompt: String
    private var character: GRCharacter
    
    private var cancellables = Set<AnyCancellable>()
    
    init(character: GRCharacter, prompt: String) {
        self.character = character
        self.prompt = prompt
        
        setupSpeechHandlers()
        loadChatHistory()
    }
    
    // MARK: - 음성 관련 설정
    private func setupSpeechHandlers() {
        // 음성 서비스 이벤트 핸들러 설정
        speechService.onSpeechStart = { [weak self] in
            DispatchQueue.main.async {
                self?.isSpeaking = true
            }
        }
        
        speechService.onSpeechFinish = { [weak self] in
            DispatchQueue.main.async {
                self?.isSpeaking = false
            }
        }
        
        speechService.onRecognitionResult = { [weak self] text in
            DispatchQueue.main.async {
                self?.inputText = text
            }
        }
        
        speechService.onRecognitionFinish = { [weak self] in
            DispatchQueue.main.async {
                self?.isListening = false
                // 인식된 텍스트가 있다면 메시지 전송
                if let self = self, !self.inputText.isEmpty {
                    self.sendMessage()
                }
            }
        }
        
        speechService.onRecognitionError = { [weak self] error in
            DispatchQueue.main.async {
                self?.isListening = false
                self?.errorMessage = error.localizedDescription
            }
        }
    }
    
    // Firestore에서 이전 대화 기록 로드
    func loadChatHistory() {
        isLoading = true
        errorMessage = nil
        
        firebaseService.fetchChatMessages(characterID: character.id) { [weak self] messages, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                if let messages = messages {
                    self.messages = messages
                    
                    // 메시지가 없는 경우 첫 인사 추가
                    if messages.isEmpty {
                        self.addGreetingMessage()
                    }
                }
            }
        }
    }
    
    // 첫 인사 메시지 추가
    func addGreetingMessage() {
        // 성장 단계에 따른 인사말 생성
        let greeting: String
        
        switch character.status.phase {
        case .egg:
            greeting = "알 속에서 꿈틀거리고 있어요..."
        case .infant:
            if character.species == .ligerCat {
                greeting = "냥...! 안녕하세요!"
            } else {
                greeting = "꾸잉...! 안녕하세요!"
            }
        case .child:
            if character.species == .ligerCat {
                greeting = "어흥! 안녕하세요 주인님! 저는 \(character.name)이에요. 냥!"
            } else {
                greeting = "히히! 안녕하세요 주인님! 저는 \(character.name)이에요. 꾸잉!"
            }
        case .adolescent:
            if character.species == .ligerCat {
                greeting = "그르릉~ 안녕하세요! 오늘은 무엇을 하고 싶으신가요?"
            } else {
                greeting = "꾸잉~ 안녕하세요! 오늘은 무엇을 하고 싶으신가요?"
            }
        case .adult, .elder:
            if character.species == .ligerCat {
                greeting = "그르릉... 반갑습니다. 오랜만이네요. 무슨 이야기를 나눌까요?"
            } else {
                greeting = "꾸잉... 반갑습니다. 오랜만이네요. 무슨 이야기를 나눌까요?"
            }
        }
        
        let message = ChatMessage(text: greeting, isFromPet: true)
        addMessage(message)
        
        // 음성으로 인사말 재생
        if showSubtitle && speechEnabled && !greeting.isEmpty {
            speakMessage(greeting)
        }
    }
    
    // Firestore에 메시지 저장
    private func addMessage(_ message: ChatMessage) {
        messages.append(message)
        
        firebaseService.saveChatMessage(message, characterID: character.id) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // 메시지 전송 및 챗펫 응답을 생성
    func sendMessage() {
        guard !inputText.isEmpty else { return }
        
        // 사용자 메시지 추가
        let userMessage = ChatMessage(text: inputText, isFromPet: false)
        addMessage(userMessage)
        
        let userInput = inputText
        inputText = ""
        
        // 쳇팻 응답 생성
        generatePetResponse(to: userInput)
    }
    
    // 챗펫 응답을 생성합니다.
    private func generatePetResponse(to userInput: String) {
        isLoading = true
        errorMessage = nil
        
        // 완전한 프롬프트 구성
        let fullPrompt = prompt + "\n\n사용자: " + userInput
        
        // Vertex AI로 응답 생성
        vertexService.generatePetResponse(prompt: fullPrompt, history: messages) { [weak self] response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                if let response = response, !response.isEmpty {
                    // 챗펫 응답 메시지 추가
                    let petMessage = ChatMessage(text: response, isFromPet: true)
                    self.addMessage(petMessage)
                    
                    // 음성으로 응답 재생 (자막이 활성화된 경우에만)
                    if self.showSubtitle {
                        self.speakMessage(response)
                    }
                } else {
                    // 응답 생성 실패 시 기본 메시지
                    let defaultResponse: String
                    
                    if self.character.species == .ligerCat {
                        defaultResponse = "냥...? (무슨 말인지 잘 이해하지 못한 것 같아요)"
                    } else {
                        defaultResponse = "꾸잉...? (무슨 말인지 잘 이해하지 못한 것 같아요)"
                    }
                    
                    let petMessage = ChatMessage(text: defaultResponse, isFromPet: true)
                    self.addMessage(petMessage)
                    
                    if self.showSubtitle && self.speechEnabled {
                        self.speakMessage(defaultResponse)
                    }
                }
            }
        }
    }
    
    
    // MARK: 음성 관련 메서드
    // 텍스트를 음성으로 말합니다.
    func speakMessage(_ text: String) {
        // 음성 비활성화시 재생되지 않음
        guard speechEnabled else { return }
        
        // 음성 타입 설정
        speechService.setVoiceType(voiceType)
        
        // 텍스트를 음성으로 변환
        speechService.speak(text, gender: voiceGender)
    }
    
    // 음성 인식을 시작합니다.
    func startListening() {
        isListening = true
        inputText = ""
        speechService.startListening()
    }
    
    // 음성 인식을 중지합니다.
    func stopListening() {
        speechService.stopListening()
        isListening = false
    }
    
    // 음성 출력을 중지합니다.
    func stopSpeaking() {
        speechService.speak("", gender: voiceGender) // 빈 문자열로 현재 음성 중지
    }
    
    // MARK: - 5. 설정 메서드
    
    // 자막 표시 설정을 변경합니다.
    func toggleSubtitle() {
        showSubtitle.toggle()
    }
    
    // 음성 성별을 변경합니다.
    func setVoiceGender(_ gender: SpeechService.VoiceGender) {
        voiceGender = gender
    }
    
    // 음성 타입을 변경합니다.
    func setVoiceType(_ type: SpeechService.VoiceType) {
        voiceType = type
        speechService.setVoiceType(type)
    }
}
