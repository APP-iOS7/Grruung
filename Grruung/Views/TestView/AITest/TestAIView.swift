//
//  TestAIView.swift
//  Grruung
//
//  Created by NoelMacMini on 5/2/25.
//
import SwiftUI

struct TestAIView: View {
    // ViewModel 인스턴스 생성. @StateObject로 선언하여 View의 생명주기와 함께 관리
    @StateObject private var viewModel = TestAIViewModel()

    // 메시지 목록의 마지막 메시지로 스크롤하기 위한 도구
    @State private var scrollProxy: ScrollViewProxy?

    var body: some View {
        VStack {
            // 채팅 메시지 목록 (스크롤 가능)
            ScrollView {
                ScrollViewReader { proxy in // 스크롤 위치 제어를 위해 ScrollViewReader 사용
                    LazyVStack { // 효율적인 목록 표시를 위해 LazyVStack 사용
                        ForEach(viewModel.messages) { message in
                            // 각 메시지 버블 뷰 호출
                            MessageBubble(message: message)
                                .id(message.id) // ScrollViewReader가 메시지를 식별할 수 있도록 ID 부여
                        }
                    }
                    .onAppear { // 뷰가 나타날 때 ScrollViewReader 프록시 저장
                        self.scrollProxy = proxy
                    }
                    .onChange(of: viewModel.messages.count) { oldValue, newValue in // 메시지 개수 변경 감지
                        // 메시지 목록이 업데이트되면 가장 아래로 스크롤
                        if let lastMessage = viewModel.messages.last {
                            withAnimation { // 애니메이션 적용
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }

            // 로딩 인디케이터와 오류 메시지
            if viewModel.isLoading {
                ProgressView("AI 응답 생성 중...")
                    .padding(.vertical)
            } else if let error = viewModel.errorMessage {
                Text("오류: \(error)")
                    .foregroundColor(.red)
                    .padding(.vertical)
            }

            // 메시지 입력 필드 및 전송 버튼
            HStack {
                TextField("메시지 입력...", text: $viewModel.currentMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(viewModel.isLoading) // 로딩 중일 때 입력 비활성화

                Button {
                    viewModel.sendMessage() // 전송 버튼 클릭 시 ViewModel의 sendMessage 호출
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                .disabled(viewModel.currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading) // 입력이 비었거나 로딩 중이면 버튼 비활성화
            }
            .padding() // 입력 영역에 패딩 추가
            .background(Color(uiColor: .systemGray6)) // 배경색 추가
        }
        .navigationTitle("AI 챗봇") // 네비게이션 바 제목
    }
}

// 각 메시지를 시각적으로 표현하는 헬퍼 뷰
struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            // 사용자가 보낸 메시지는 오른쪽에, AI 메시지는 왼쪽에 정렬
            if message.isUser {
                Spacer() // 사용자 메시지를 오른쪽으로 밀기
            }

            Text(message.content)
                .padding(10)
                .background(message.isUser ? Color.blue : Color(uiColor: .systemGray5)) // 배경색 구분
                .foregroundColor(message.isUser ? .white : .primary) // 글자색 구분
                .cornerRadius(10)
                .fixedSize(horizontal: false, vertical: true)
            if !message.isUser {
                Spacer() // AI 메시지를 왼쪽으로 밀기 (사용자 메시지처럼 정렬하기 위함)
            }
        }
        // 메시지 버블이 너무 넓어지지 않도록 최대 너비 설정 (선택 사항이지만 유용)
        .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: message.isUser ? .trailing : .leading)
        .padding(.horizontal, 10) // 화면 좌우 가장자리와 메시지 사이의 간격
    }
}
