//
//  TestAIViewModel.swift
//  Grruung
//
//  Created by NoelMacMini on 5/2/25.
//
import SwiftUI
import FirebaseVertexAI // Firebase Vertex AI SDK import
import Combine // @Published 사용을 위해 필요

class TestAIViewModel: ObservableObject {
    // View에서 관찰할 수 있는 속성들
    @Published var messages: [ChatMessage] = [] // 채팅 메시지 목록
    @Published var currentMessage: String = "" // 사용자가 현재 입력 중인 메시지
    @Published var isLoading: Bool = false // AI 응답 대기 중인지 여부
    @Published var errorMessage: String? // 오류 발생 시 메시지
    
    // Initialize the Vertex AI service
    let vertex = VertexAI.vertexAI()
    
    // 사용자가 메시지를 보내는 함수
    func sendMessage() {
        let model = vertex.generativeModel(modelName: "gemini-2.0-flash")
        
        // 입력된 메시지가 비어있지 않은지 확인
        guard !currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return // 비어있으면 아무것도 하지 않음
        }
        
        // 사용자가 보낸 메시지 복사 및 입력 필드 초기화
        let userMessage = currentMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        currentMessage = "" // 입력 필드 비우기
        
        // 메시지 목록에 사용자 메시지 추가
        messages.append(ChatMessage(content: userMessage, isUser: true))
        
        // AI 응답 대기 상태로 변경 및 오류 메시지 초기화
        isLoading = true
        errorMessage = nil
        
        // 비동기 작업 시작 (Task)
        Task {
            do {
                // Vertex AI 모델에 메시지 전송 및 응답 대기
                let response = try await model.generateContent(userMessage)
                print(response.text ?? "No text in response.")
                
                // 응답에서 텍스트 내용 추출
                if let text = response.text {
                    // UI 업데이트는 메인 스레드에서 수행해야 합니다.
                    // @Published 속성 변경은 자동으로 메인 스레드에서 이루어지지만,
                    // 혹시 다른 비동기 로직이 있다면 MainActor를 명시해주는 것이 안전합니다.
                    await MainActor.run {
                        messages.append(ChatMessage(content: text, isUser: false)) // AI 응답 메시지 추가
                        isLoading = false // 로딩 상태 해제
                    }
                } else {
                    // 응답은 왔지만 텍스트 내용이 없을 경우
                    await MainActor.run {
                        errorMessage = "AI가 텍스트 응답을 생성하지 못했습니다."
                        isLoading = false // 로딩 상태 해제
                    }
                }
                
            } catch {
                // 응답 요청 중 오류 발생 시 처리
                await MainActor.run {
                    errorMessage = "AI 응답 요청 중 오류 발생: \(error.localizedDescription)"
                    isLoading = false // 로딩 상태 해제
                    print("Vertex AI Error: \(error)") // 디버깅을 위해 콘솔에 출력
                }
            }
        }
    }
    
    // 오류 메시지를 지우는 함수 (필요에 따라 사용)
    func clearError() {
        errorMessage = nil
    }
}
