//
//  VertexAIService.swift
//  Grruung
//
//  Created by KimJunsoo on 5/7/25.
//

import Foundation
import FirebaseCore
import FirebaseVertexAI

/// Vertex AI 연동을 위한 서비스 클래스
class VertexAIService {
    // MARK: - Properties
    /// 싱글톤 인스턴스
    static let shared = VertexAIService()
    
    /// 생성 모델
    private var model: GenerativeModel?
    
    // MARK: - Initialization
    private init() {
        setupModel()
    }
    
    // MARK: - Setup
    /// Vertex AI 모델 설정
    private func setupModel() {
        do {
            // Firebase Vertex AI 초기화
            let vertex = try VertexAI.vertexAI()
            // 가장 가벼운 Gemini 모델 사용
            model = vertex.generativeModel(modelName: "gemini-2.0-flash")
            print("[VertexAI] 모델 초기화 성공")
        } catch {
            print("[VertexAI] 초기화 오류: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Public Methods
    /// 펫 응답 생성 함수 - 간단 버전
    /// - Parameters:
    ///   - prompt: 프롬프트 텍스트
    ///   - history: 대화 히스토리 (옵션)
    ///   - completion: 응답 콜백
    func generatePetResponse(prompt: String, history: [ChatMessage] = [], completion: @escaping (String?, Error?) -> Void) {
        guard let model = model else {
            let error = NSError(domain: "VertexAIService", code: 500,
                               userInfo: [NSLocalizedDescriptionKey: "AI 모델이 초기화되지 않았습니다."])
            completion(nil, error)
            return
        }
        
        // 사용자 입력 추출
        var userInput = ""
        if let lastUserMessage = history.last(where: { !$0.isFromPet }) {
            userInput = lastUserMessage.text
        }
        
        // 단순화된 프롬프트
        let simplePrompt = prompt + "\n\n사용자: " + userInput
        
        // 응답 생성
        Task {
            do {
                // 단일 요청으로 응답 생성
                let response = try await model.generateContent(simplePrompt)
                
                if let responseText = response.text {
                    DispatchQueue.main.async {
                        completion(responseText, nil)
                    }
                } else {
                    throw NSError(domain: "VertexAIService", code: 500,
                                 userInfo: [NSLocalizedDescriptionKey: "응답이 비어있습니다."])
                }
            } catch {
                print("[VertexAI] 응답 생성 오류: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
    }
}
