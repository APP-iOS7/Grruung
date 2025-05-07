//
//  SpeechRecognizer.swift
//  Grruung
//
//  Created by KimJunsoo on 5/6/25.
//

import Foundation
import Speech
import AVFoundation

enum SpeechRecognizerError: Error {
    case notAuthorized
    case recognitionFailed
    case audioEngineFailed
}

class SpeechRecognizer {
    private var speedchRecognizer: SFSpeechRecognizer?
    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    init() {
        // 한국어로 인식
        speedchRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ko-KR"))
    }
    
    // 녹음 시작
    func startRecording(completion: @escaping (Result<String, Error>) -> Void) {
        stopRecording()
        
        SFSpeechRecognizer.requestAuthorization { status in
            switch status {
            case .authorized:
                DispatchQueue.main.async {
                    do {
                        try self.startRecordingInternal(completion: completion)
                    } catch {
                        completion(.failure(error))
                    }
                }
            case .denied, .restricted, .notDetermined:
                completion(.failure(SpeechRecognizerError.notAuthorized))
            @unknown default:
                completion(.failure(SpeechRecognizerError.notAuthorized))
            }
        }
    }
    
    // 녹음 시작 내부 로직
    private func startRecordingInternal(completion: @escaping (Result<String, Error>) -> Void) throws {
        // 음성 인식 작업이 이미 실행 중인지 확인
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        // 오디오 세션 설정
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // 인식 요청 생성
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        // 오디오 입력 노드 설정
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechRecognizerError.recognitionFailed
        }
        
        // 실시간 인식 설정
        recognitionRequest.shouldReportPartialResults = true
        
        // 음성 인식 작업 시작
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                // 인식된 텍스트 처리
                let recognizedText = result.bestTranscription.formattedString
                isFinal = result.isFinal
                
                if isFinal {
                    completion(.success(recognizedText))
                }
            }
            
            if error != nil || isFinal {
                // 오디오 엔진 중지
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        }
        
        // 오디오 버퍼 설정
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        // 오디오 엔진 시작
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    // 녹음 중지
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        
        // 탭 제거
        if audioEngine.inputNode.numberOfInputs > 0 {
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
    }
    
    // 권한 요청
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { _ in
            
        }
    }
}
