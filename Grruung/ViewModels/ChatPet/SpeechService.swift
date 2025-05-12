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
    
    private override init() {
        super.init()
        synthesizer.delegate = self
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
        
        // 타입에 따라 다른 처리
        switch voiceType {
        case .human: speakHumanVoice(text, gender: gender)
        case .animal: speakAnimalVoice(text, gender: gender)
        }
    }
    
    // 사람 음성으로 텍스트를 읽습니다.
    private func speakHumanVoice(_ text: String, gender: VoiceGender) {
        // 음성 설정
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        // 성별에 따른 목소리 설정
        switch gender {
        case .male: utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR") // 한국어 음성
        case .female: utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR") // 한국어 음성
        }
        
        // 음성 재생
        isSpeaking = true
        onSpeechStart?()
        synthesizer.speak(utterance)
    }
    
    // 동물 소리를 재생합니다.
    private func speakAnimalVoice(_ text: String, gender: VoiceGender) {
        // TODO: 추후 개선 - 텍스트 길이나 내용에 따라 다른 소리 재생
        // 현재는 테스트용으로 간단히 구현
        
        // 짧은 효과음 재생
        if let soundURL = Bundle.main.url(forResource: "animal_sound", withExtension: "mp3") {
            do {
                let audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer.play()
                
                // 효과음 길이에 맞춰 이벤트 발생
                DispatchQueue.main.asyncAfter(deadline: .now() + audioPlayer.duration) {
                    self.onSpeechFinish?()
                }
            } catch {
                print("동물 소리 재생 실패: \(error.localizedDescription)")
                self.onSpeechFinish?()
            }
        } else {
            print("동물 소리 파일을 찾을 수 없습니다.")
            self.onSpeechFinish?()
        }
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
    
    private func startRecognition() {
        // 이전 작업 정리
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // 오디오 세션 설정
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            onRecognitionError?(error as NSError)
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
        
        // 인식 작업 시작
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
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
}
