//
//  VoiceChatViewModel.swift
//  Grruung
//
//  Created by KimJunsoo on 5/12/25.
//

import AVFoundation
import Combine
import FirebaseFirestore
import Foundation
import SwiftUI

// 실시간 음성 대화를 위한 ViewModel
class VoiceChatViewModel: ObservableObject {
    // MARK: - Published 프로퍼티
    @Published var currentSpeech: String = ""  // 현재 말하고 있는 텍스트
    @Published var userSpeech: String = ""  // 사용자가 말한 내용
    @Published var isListening: Bool = false  // 듣고 있는 상태
    @Published var isSpeaking: Bool = false  // 말하고 있는 상태
    @Published var showSpeechBubble: Bool = false  // 말풍선 표시 여부
    @Published var errorMessage: String?  // 오류 메시지
    @Published var isLoading: Bool = false  // 로딩 상태
    @Published var subtitleEnabled: Bool = true  // 자막 활성화 여부
    @Published var voiceGender: SpeechService.VoiceGender = .female  // 음성 성별
    @Published var micEnabled: Bool = true  // 마이크 활성화 여부

    // 서비스
    private let vertexService = VertexAIService.shared
    private let firebaseService = FirebaseService.shared
    private let speechService = SpeechService.shared

    // 대화 세션 관리
    private var currentSessionID: String?
    private var recentMessages: [ChatMessage] = []
    private var importantMemories: [[String: Any]] = []

    // 프롬프트 및 캐릭터 정보
    private var character: GRCharacter
    private var basePrompt: String

    private var cancellables = Set<AnyCancellable>()

    // 음성 관련
    private var speechSynthesizer = AVSpeechSynthesizer()

    // MARK: - 초기화
    init(character: GRCharacter, prompt: String) {
        self.character = character
        self.basePrompt = prompt

        setupSpeechHandlers()
        initializeSession()
    }

    // MARK: - 초기화 및 설정

    // 대화 세션을 초기화
    private func initializeSession() {
        isLoading = true
        errorMessage = nil

        // 1. 세션 가져오기 또는 생성
        firebaseService.getOrCreateActiveSession(characterID: character.id) {
            [weak self] sessionID, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "세션 생성 실패: \(error.localizedDescription)"
                }
                return
            }

            if let sessionID = sessionID {
                self.currentSessionID = sessionID

                // 2. 최근 메시지 로드
                self.loadRecentMessages()

                // 3. 중요 기억 로드
                self.loadImportantMemories()

                DispatchQueue.main.async {
                    self.isLoading = false
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "세션을 생성할 수 없습니다."
                }
            }
        }
    }

    // 음성 관련 설정
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

                // 말풍선 숨기기 (약간의 지연 후)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        self?.showSpeechBubble = false
                    }
                }
            }
        }

        speechService.onRecognitionResult = { [weak self] text in
            DispatchQueue.main.async {
                self?.userSpeech = text
            }
        }

        speechService.onRecognitionFinish = { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isListening = false

                // 인식된 텍스트가 있다면 처리
                if !self.userSpeech.isEmpty {
                    self.handleUserSpeech(self.userSpeech)
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

    // MARK: - 대화 기록 관리

    // 최근 메시지를 로드
    private func loadRecentMessages() {
        guard let sessionID = currentSessionID else { return }

        firebaseService.fetchMessagesFromSession(
            sessionID: sessionID,
            characterID: character.id,
            limit: 10
        ) { [weak self] messages, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "메시지 로드 실패: \(error.localizedDescription)"
                }
                return
            }

            if let messages = messages {
                self.recentMessages = messages

                // 초기 인사 추가 (최근 메시지가 없는 경우)
                if messages.isEmpty {
                    self.showGreeting()
                }
            }
        }
    }

    // 중요 기억을 로드
    private func loadImportantMemories() {
        firebaseService.fetchImportantMemories(
            characterID: character.id,
            limit: 5
        ) { [weak self] memories, error in
            guard let self = self else { return }

            if let memories = memories {
                self.importantMemories = memories
            }
        }
    }

    // 초기 인사 메시지
    private func showGreeting() {
        // 성장 단계에 따른 인사말 생성
        let greeting: String

        switch character.status.phase {
        case .egg:
            greeting = "알 속에서 꿈틀거리고 있어요..."
        case .infant:
            if character.species == .CatLion {
                greeting = "냥...! 안녕하세요!"
            } else {
                greeting = "꾸잉...! 안녕하세요!"
            }
        case .child:
            if character.species == .CatLion {
                greeting = "어흥! 안녕하세요 주인님! 저는 \(character.name)이에요. 냥!"
            } else {
                greeting = "히히! 안녕하세요 주인님! 저는 \(character.name)이에요. 꾸잉!"
            }
        case .adolescent:
            if character.species == .CatLion {
                greeting = "그르릉~ 안녕하세요! 오늘은 무엇을 하고 싶으신가요?"
            } else {
                greeting = "꾸잉~ 안녕하세요! 오늘은 무엇을 하고 싶으신가요?"
            }
        case .adult, .elder:
            if character.species == .CatLion {
                greeting = "그르릉... 반갑습니다. 오랜만이네요. 무슨 이야기를 나눌까요?"
            } else {
                greeting = "꾸잉... 반갑습니다. 오랜만이네요. 무슨 이야기를 나눌까요?"
            }
        }

        // 음성으로 인사말 재생 및 Firestore에 저장
        speakAndStore(text: greeting, isFromPet: true)
    }

    // MARK: - 음성 대화 처리

    /// 사용자 음성을 처리합니다.
    private func handleUserSpeech(_ speech: String) {
        // 비어있는 경우 무시
        guard !speech.isEmpty else { return }

        // Firestore에 사용자 메시지 저장
        storeMessage(text: speech, isFromPet: false)

        // 응답 생성
        generatePetResponse(to: speech)

        // 사용자 음성 입력 초기화
        userSpeech = ""
    }

    // 챗펫 응답을 생성
    private func generatePetResponse(to userSpeech: String) {
        isLoading = true

        // 맥락화된 프롬프트 생성
        let contextualPrompt = generateContextualPrompt(userInput: userSpeech)

        // Vertex AI로 응답 생성
        vertexService.generatePetResponse(prompt: contextualPrompt) { [weak self] response, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isLoading = false

                if let error = error {
                    self.errorMessage = "응답 생성 실패: \(error.localizedDescription)"
                    return
                }

                if let response = response, !response.isEmpty {
                    // 응답에서 부적절한 내용 필터링
                    let filteredResponse = self.filterInappropriateContent(response)

                    // 음성으로 응답 재생 및 Firestore에 저장
                    self.speakAndStore(text: filteredResponse, isFromPet: true)

                    // 중요한 대화 내용 분석 및 저장
                    self.analyzeAndStoreImportantContent(
                        userInput: userSpeech, response: filteredResponse)
                } else {
                    // 응답 생성 실패 시 기본 메시지
                    let defaultResponse: String

                    if self.character.species == .CatLion {
                        defaultResponse = "냥...? (무슨 말인지 잘 이해하지 못한 것 같아요)"
                    } else {
                        defaultResponse = "꾸잉...? (무슨 말인지 잘 이해하지 못한 것 같아요)"
                    }

                    self.speakAndStore(text: defaultResponse, isFromPet: true)
                }
            }
        }
    }

    // 맥락화된 프롬프트를 생성
    private func generateContextualPrompt(userInput: String) -> String {
        var prompt = basePrompt

        // 1. 캐릭터 상태 정보 추가
        prompt += "\n\n현재 상태:"
        prompt += "\n- 포만감: \(character.status.satiety)/100"
        prompt += "\n- 체력: \(character.status.stamina)/100"
        prompt += "\n- 청결: \(character.status.clean)/100"
        prompt += "\n- 애정도: \(character.status.affection)/100"
        prompt += "\n- 기분: \(getCurrentMood())"

        // 2. 대화 컨텍스트 추가
        if !recentMessages.isEmpty {
            prompt += "\n\n최근 대화 내용:"

            for message in recentMessages {
                let speaker = message.isFromPet ? character.name : "사용자"
                prompt += "\n\(speaker): \(message.text)"
            }
        }

        // 3. 중요 기억 추가 (관련된 것만)
        if !importantMemories.isEmpty {
            let relevantMemories = filterRelevantMemories(userInput: userInput, maxCount: 2)

            if !relevantMemories.isEmpty {
                prompt += "\n\n중요한 기억:"

                for memory in relevantMemories {
                    if let content = memory["content"] as? String {
                        prompt += "\n- \(content)"
                    }
                }
            }
        }

        // 4. 부적절한 콘텐츠 차단 지침 추가
        prompt += "\n\n중요 지침:"
        prompt += "\n- 사용자의 질문이 부적절하거나 불쾌감을 줄 수 있는 내용이라면, 정중하게 다른 주제로 대화를 전환하세요."
        prompt += "\n- 항상 캐릭터의 성격과 성장 단계에 맞는 어조와 표현을 사용하세요."
        prompt += "\n- 응답은 짧고 간결하게 해주세요. 긴 대답은 피하세요. 음성 대화에 적합한 길이로 답변하세요."

        // 5. 사용자 입력 추가
        prompt += "\n\n사용자: \(userInput)"
        prompt += "\n\(character.name): "

        return prompt
    }

    // 현재 캐릭터의 기분 상태를 반환
    private func getCurrentMood() -> String {
        // 스텟에 따른 기분 상태 계산
        let satiety = character.status.satiety
        let stamina = character.status.stamina
        let clean = character.status.clean
        let affection = character.status.affection

        if satiety < 30 {
            return "배고픔"
        } else if stamina < 30 {
            return "피곤함"
        } else if clean < 30 {
            return "불쾌함"
        } else if affection < 30 {
            return "외로움"
        } else if satiety > 70 && stamina > 70 && clean > 70 && affection > 70 {
            return "매우 행복함"
        } else if satiety > 50 && stamina > 50 && clean > 50 && affection > 50 {
            return "행복함"
        } else {
            return "보통"
        }
    }

    // 관련된 중요 기억을 필터링
    private func filterRelevantMemories(userInput: String, maxCount: Int) -> [[String: Any]] {
        // 간단한 키워드 매칭
        let userWords = userInput.lowercased().components(separatedBy: .whitespacesAndNewlines)

        return
            importantMemories
            .filter { memory in
                if let content = memory["content"] as? String {
                    let memoryLower = content.lowercased()
                    return userWords.contains { word in
                        word.count > 3 && memoryLower.contains(word)
                    }
                }
                return false
            }
            .prefix(maxCount)
            .map { $0 }
    }

    // 부적절한 내용을 필터링
    private func filterInappropriateContent(_ text: String) -> String {
        // 간단한 구현
        let inappropriateWords = ["비속어", "욕설", "성인", "19금"]

        var filteredText = text
        for word in inappropriateWords {
            filteredText = filteredText.replacingOccurrences(
                of: word,
                with: String(repeating: "*", count: word.count)
            )
        }

        return filteredText
    }

    // 텍스트를 음성으로 말하고 Firestore에 저장
    func speakAndStore(text: String, isFromPet: Bool) {
        // 1. 메시지 저장
        storeMessage(text: text, isFromPet: isFromPet)

        // 2. 펫 메시지인 경우 음성으로 말하기
        if isFromPet {
            // 음성으로 말하기 (마이크가 활성화된 경우에만)
            if micEnabled {
                speechService.speak(text, gender: voiceGender)
            }

            // 말풍선 표시 (자막이 활성화된 경우에만)
            if subtitleEnabled {
                DispatchQueue.main.async {
                    withAnimation {
                        self.currentSpeech = text
                        self.showSpeechBubble = true
                    }
                }
            }
        }
    }

    // Firestore에 메시지를 저장
    private func storeMessage(text: String, isFromPet: Bool) {
        // 메시지 생성
        let message = ChatMessage(text: text, isFromPet: isFromPet)

        // 최근 메시지 목록에 추가
        recentMessages.append(message)
        if recentMessages.count > 10 {
            recentMessages.removeFirst()
        }

        // 펫의 현재 상태 정보 생성
        let petStatus: [String: Any] = [
            "phase": character.status.phase.rawValue,
            "mood": getCurrentMood(),
            "dominant": getDominantStat(),
        ]

        // Firestore에 저장
        firebaseService.saveChatMessageWithSession(
            message,
            characterID: character.id,
            sessionID: currentSessionID,
            petStatus: petStatus
        ) { error in
            if let error = error {
                print("메시지 저장 실패: \(error.localizedDescription)")
            }
        }
    }

    // 가장 높은 스텟을 반환
    private func getDominantStat() -> String {
        let stats = [
            ("포만감", character.status.satiety),
            ("체력", character.status.stamina),
            ("청결", character.status.clean),
            ("애정", character.status.affection),
        ]

        return stats.max(by: { $0.1 < $1.1 })?.0 ?? "포만감"
    }

    // 중요한 대화 내용을 분석하고 저장
    private func analyzeAndStoreImportantContent(userInput: String, response: String) {
        // 중요 정보 키워드
        let importantKeywords = ["좋아하는", "싫어하는", "취미", "생일", "가족", "친구", "학교", "직장", "이름"]

        // 사용자 입력에서 중요 정보 검사
        for keyword in importantKeywords {
            if userInput.contains(keyword) || response.contains(keyword) {
                // 중요 정보가 포함된 대화 저장
                let memoryContent = "사용자: \(userInput)\n\(character.name): \(response)"
                let memoryData: [String: Any] = [
                    "content": memoryContent,
                    "importance": 7,  // 중요도 높음
                    "emotionalContext": getCurrentMood(),
                    "category": "사용자_정보",
                    "timestamp": Timestamp(date: Date()),
                ]

                firebaseService.storeImportantMemory(
                    memory: memoryData,
                    characterID: character.id
                ) { _ in }

                break  // 하나의 중요 키워드만 처리
            }
        }
    }

    // MARK: - 음성 인식 제어

    // 음성 인식 시작
    func startListening() {
        // 마이크가 비활성화 상태라면 작동하지 않음
        guard micEnabled else { return }

        isListening = true
        speechService.startListening()
    }

    // 음성 인식을 중지
    func stopListening() {
        if isListening {
            speechService.stopListening()
            isListening = false
        }
    }

    // 음성 출력을 중지
    func stopSpeaking() {
        if isSpeaking {
            speechService.speak("", gender: voiceGender)  // 빈 문자열로 현재 음성 중지

            DispatchQueue.main.async {
                self.isSpeaking = false
                self.showSpeechBubble = false
            }
        }
    }

    // 마이크 상태를 토글
    func toggleMic() {
        micEnabled.toggle()

        // 마이크를 끄면 인식도 중지
        if !micEnabled && isListening {
            stopListening()
        }
    }

    // MARK: - 세션 관리

    // 현재 대화 세션을 종료
    func endCurrentSession(completion: @escaping (Error?) -> Void) {
        guard let sessionID = currentSessionID else {
            completion(
                NSError(
                    domain: "VoiceChatViewModel", code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "활성 세션이 없습니다."]))
            return
        }

        // 세션 요약 생성
        var summary = "음성 대화 요약: "
        if recentMessages.count > 3 {
            let lastMessages = recentMessages.suffix(3)
            summary += lastMessages.map { $0.text.prefix(20) + "..." }.joined(separator: ", ")
        } else {
            summary += "짧은 대화"
        }

        firebaseService.endConversationSession(
            sessionID: sessionID,
            characterID: character.id,
            summary: summary,
            completion: completion
        )
    }
}

