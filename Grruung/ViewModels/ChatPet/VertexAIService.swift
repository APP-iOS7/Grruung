//
//  VertexAIService.swift
//  Grruung
//
//  Created by KimJunsoo on 5/7/25.
//

import Foundation
import FirebaseVertexAI

// Vertex AI 관련 작업을 처리하는 서비스 클래스
class VertexAIService {
    static let shared = VertexAIService()
    
    // Vertex AI 서비스 초기화
    private let vertex = VertexAI.vertexAI()
    
    // Gemini 모델 초기화
    private let model: GenerativeModel
    
    private init() {
        model = vertex.generativeModel(modelName: "gemini-2.0-flash")
    }
    
    func generatePetResponse(prompt: String, history: [ChatMessage] = [], completion: @escaping (String?, Error?) -> Void) {
        Task {
            do {
                // 응답 생성
                let response = try await model.generateContent(prompt)
                
                // 응답 텍스트 가져오기
                if let responseText = response.text {
                    // 메인 스레드에서 콜백 호출
                    DispatchQueue.main.async {
                        completion(responseText, nil)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(nil, NSError(domain: "VertexAIService", code: 500, userInfo: [NSLocalizedDescriptionKey: "응답 생성에 실패했습니다."]))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
    }
}
