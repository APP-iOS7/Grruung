//
//  SpeechService.swift
//  Grruung
//
//  Created by KimJunsoo on 5/7/25.
//

import Foundation
import AVFoundation
import Speech

class SpeechService: NSObject {
    static let shared = SpeechService()
    
    // MARK: - 속성
    
    // 음성 합성 관련
    private let synthesizer = AVSpeechSynthesizer()
    private var voiceType: VoiceType = .human
    private var isSpeaking: Bool = false
    
    // 음성 인식 관련
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ko-KR"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var isListening = false
    
    // 이벤트 핸들러
    var onSpeechStart: (() -> Void)?
    var onSpeechFinish: (() -> Void)?
    var onRecognitionResult: ((String) -> Void)?
    var onRecognitionFinish: (() -> Void)?
    var onRecognitionError: ((Error) -> Void)?
    
    // MARK: - 초기화
    
    private override init() {
        super.init()
        synthesizer.delegate = self
        
        // 필요한 음성 리소스 다운로드 (백그라운드에서)
        if let koreanVoice = AVSpeechSynthesisVoice(language: "ko-KR") {
            let utterance = AVSpeechUtterance(string: " ")
            utterance.voice = koreanVoice
            
            DispatchQueue.global(qos: .background).async {
                // 빈 문자열로 발음하여 음성 리소스 로딩 (음성 재생 없이)
                utterance.volume = 0.0
                self.synthesizer.speak(utterance)
            }
        }
    }
    
    // MARK: - 음성 타입 관리
    
    // 음성 타입 설정
    func setVoiceType(_ type: VoiceType) {
        self.voiceType = type
    }
    
    // 음성 타입
    enum VoiceType {
        case human
        case animal
    }
    
    // 음성 성별
    enum VoiceGender {
        case male
        case female
    }
    
    // MARK: - 텍스트 음성 변환 (TTS)
    
    /// 텍스트를 음성으로 변환하여 재생합니다.
    /// - Parameters:
    ///   - text: 음성으로 변환할 텍스트
    ///   - gender: 음성 성별 (남/여)
    func speak(_ text: String, gender: VoiceGender = .female) {
        // 이미 재생 중인 경우 중지
        if isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        // 빈 텍스트인 경우 (음성 중지 목적)
        if text.isEmpty {
            isSpeaking = false
            onSpeechFinish?()
            return
        }
        
        // 타입에 따라 다른 처리
        switch voiceType {
        case .human: speakHumanVoice(text, gender: gender)
        case .animal: speakAnimalVoice(text, gender: gender)
        }
    }
    
    // 사람 음성으로 텍스트를 읽습니다.
    private func speakHumanVoice(_ text: String, gender: VoiceGender) {
        // 오디오 세션 설정
        do {
            try setupAudioSessionForSpeech()
        } catch {
            print("음성 합성을 위한 오디오 세션 설정 실패: \(error.localizedDescription)")
        }
        
        // 음성 설정
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        // 성별에 따른 목소리 설정
        switch gender {
        case .male:
            // 남성 음성 설정
            if let maleVoice = AVSpeechSynthesisVoice(language: "ko-KR") {
                utterance.voice = maleVoice
                utterance.pitchMultiplier = 0.9 // 낮은 음성
            }
        case .female:
            // 여성 음성 설정
            if let femaleVoice = AVSpeechSynthesisVoice(language: "ko-KR") {
                utterance.voice = femaleVoice
                utterance.pitchMultiplier = 1.1 // 높은 음성
            }
        }
        
        // 음성 재생
        isSpeaking = true
        onSpeechStart?()
        synthesizer.speak(utterance)
    }
    
    // 동물 소리를 재생합니다.
    private func speakAnimalVoice(_ text: String, gender: VoiceGender) {
        // TODO: 추후 개선 - 텍스트 길이나 내용에 따라 다른 소리 재생
        // 현재는 테스트용으로 간단히 구현: 음성 합성 + 피치 변경
        
        // 오디오 세션 설정
        do {
            try setupAudioSessionForSpeech()
        } catch {
            print("음성 합성을 위한 오디오 세션 설정 실패: \(error.localizedDescription)")
        }
        
        // 음성 설정
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        utterance.volume = 1.0
        utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR")
        
        // 동물 음성 효과를 위한 피치 조정
        switch gender {
        case .male:
            utterance.pitchMultiplier = 0.7 // 매우 낮은 피치
        case .female:
            utterance.pitchMultiplier = 1.5 // 매우 높은 피치
        }
        
        // 음성 재생
        isSpeaking = true
        onSpeechStart?()
        synthesizer.speak(utterance)
    }
    
    // MARK: - 음성 인식 (STT)
    
    // 음성 인식 시작
    func startListening() {
        // 이미 인식 중인 경우 정지
        if isListening {
            stopListening()
        }
        
        // 음성 인식 권한 요청
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self.startRecognition()
                case .denied, .restricted, .notDetermined:
                    let error = NSError(domain: "SpeechService", code: 403, userInfo: [NSLocalizedDescriptionKey: "음성 인식 권한이 필요합니다."])
                    self.onRecognitionError?(error)
                @unknown default:
                    break
                }
            }
        }
    }
    
    // 음성 인식 중지
    func stopListening() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        // 상태 초기화
        isListening = false
        recognitionRequest = nil
        recognitionTask = nil
        
        onRecognitionFinish?()
    }
    
    // 오디오 세션 설정 (음성 합성용)
    private func setupAudioSessionForSpeech() throws {
        let audioSession = AVAudioSession.sharedInstance()
        
        // 오디오 세션 카테고리 설정: 재생 + 녹음 혼합 모드
        // .playAndRecord: 재생과 녹음 동시 지원
        // .duckOthers: 다른 앱 오디오 볼륨 일시적 감소
        // .allowBluetooth: 블루투스 장치 사용 허용
        try audioSession.setCategory(.playAndRecord,
                                     mode: .default,
                                     options: [.duckOthers, .allowBluetooth])
        
        // 세션 활성화
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    // 오디오 세션 설정 (음성 인식용)
    private func setupAudioSessionForRecognition() throws {
        let audioSession = AVAudioSession.sharedInstance()
        
        // 음성 인식을 위한 최적화 설정
        // .record: 녹음 최적화 모드
        // .measurement: 최소한의 시스템 사운드 처리 (측정용)
        try audioSession.setCategory(.record,
                                     mode: .measurement,
                                     options: .duckOthers)
        
        // 세션 활성화
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    private func startRecognition() {
        // 이전 작업 정리
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // 오디오 세션 설정
        do {
            try setupAudioSessionForRecognition()
        } catch {
            onRecognitionError?(error)
            return
        }
        
        // 인식 요청 생성
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        // 오디오 입력 노드 설정
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            let error = NSError(domain: "SpeechService", code: 500, userInfo: [NSLocalizedDescriptionKey: "음성 인식 요청 생성에 실패했습니다."])
            onRecognitionError?(error)
            return
        }
        
        // 부분 결과 사용 설정
        recognitionRequest.shouldReportPartialResults = true
        
        // 한국어 음성 인식기 설정
        guard let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ko-KR")) else {
            let error = NSError(domain: "SpeechService", code: 500, userInfo: [NSLocalizedDescriptionKey: "한국어 음성 인식이 지원되지 않습니다."])
            onRecognitionError?(error)
            return
        }
        
        // 인식 작업 시작
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            var isFinal = false
            
            if let result = result {
                // 인식 결과 처리
                let text = result.bestTranscription.formattedString
                self.onRecognitionResult?(text)
                isFinal = result.isFinal
            }
            
            // 오류가 있거나 최종 결과인 경우
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.isListening = false
                self.onRecognitionFinish?()
            }
        }
        
        // 오티오 탭 설정
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        // 오디오 엔진 시작
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            isListening = true
        } catch {
            onRecognitionError?(error as NSError)
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate 구현
extension SpeechService: AVSpeechSynthesizerDelegate {
    // 음성 재생 종료 시 호출
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        onSpeechFinish?()
    }
    
    // 음성 재상 취소 시 호출
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
        onSpeechFinish?()
    }
    
    // 단어 시작 시 호출
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        // 현재 말하고 있는 텍스트 부분 처리 (원하는 경우)
    }
}
