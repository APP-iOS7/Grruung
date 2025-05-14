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
    
    // 응답 캐싱 (같은 프롬프트에 대한 중복 요청 방지)
    private var responseCache: [String: String] = [:]
    
    // MARK: - Initialization
    private init() {
        setupModel()
    }
    
    // MARK: - Setup
    // Vertex AI 모델 설정
    private func setupModel() {
        do {
            // Firebase Vertex AI 초기화
            let vertex = VertexAI.vertexAI()
            
            // 가장 가벼운 Gemini 모델 사용
            model = vertex.generativeModel(modelName: "gemini-2.0-flash")
            
            print("[VertexAI] 모델 초기화 성공")
        } catch {
            print("[VertexAI] 초기화 오류: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Public Methods
    
    // 펫 응답 생성 함수
    /// - Parameters:
    ///   - prompt: 프롬프트 텍스트
    ///   - completion: 응답 콜백
    func generatePetResponse(
        prompt: String,
        completion: @escaping (String?, Error?) -> Void
    ) {
        // 캐싱된 응답이 있는지 확인
        if let cachedResponse = responseCache[prompt] {
            completion(cachedResponse, nil)
            return
        }
        
        guard let model = model else {
            let error = NSError(
                domain: "VertexAIService",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "AI 모델이 초기화되지 않았습니다."]
            )
            completion(nil, error)
            return
        }
        
        // 응답 생성
        Task {
            do {
                let requestStartTime = Date()
                
                // 응답 생성
                let response = try await model.generateContent(prompt)
                
                // 응답 처리
                if let responseText = response.text {
                    let requestTime = Date().timeIntervalSince(requestStartTime)
                    print("[VertexAI] 응답 생성 시간: \(String(format: "%.2f", requestTime))초")
                    
                    // 응답 캐싱 (메모리 효율성을 위해 최대 10개만 캐시)
                    if self.responseCache.count >= 10 {
                        if let firstKey = self.responseCache.keys.first {
                                self.responseCache.removeValue(forKey: firstKey)
                            }
                    }
                    self.responseCache[prompt] = responseText
                    
                    DispatchQueue.main.async {
                        completion(responseText, nil)
                    }
                } else {
                    throw NSError(
                        domain: "VertexAIService",
                        code: 500,
                        userInfo: [NSLocalizedDescriptionKey: "응답이 비어있습니다."]
                    )
                }
            } catch {
                print("[VertexAI] 응답 생성 오류: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
    }
    
    // 캐시를 지웁니다.
    func clearCache() {
        responseCache.removeAll()
    }
}
