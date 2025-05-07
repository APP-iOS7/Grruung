//
//  ChatPetView.swift
//  Grruung
//
//  Created by KimJunsoo on 5/7/25.
//

import SwiftUI

struct ChatPetView: View {
    @StateObject private var viewModel: ChatPetViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showSettings = false
    @FocusState private var isInputFocused: Bool
    @State private var showVoiceChatLive = false
    
    // 캐릭터와 프롬프트 직접 저장
    let character: GRCharacter
    let prompt: String
    
    init(character: GRCharacter, prompt: String) {
        self.character = character
        self.prompt = prompt
        _viewModel = StateObject(wrappedValue: ChatPetViewModel(character: character, prompt: prompt))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    chatMessagesArea
                    
                    messageInputArea
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .background(Color.black.opacity(0.2))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("음성 대화")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("대화종료") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                voiceSettingsView
            }
            .alert(item: Binding<AlertItem?>(
                get: {
                    viewModel.errorMessage.map { message in
                        AlertItem(message: message)
                    }
                },
                set: { _ in
                    viewModel.errorMessage = nil
                }
            )) { alert in
                Alert(
                    title: Text("오류"),
                    message: Text(alert.message),
                    dismissButton: .default(Text("확인"))
                )
            }
            .sheet(isPresented: $showVoiceChatLive) {
                VoiceChatLiveView(
                    character: character,
                    prompt: prompt
                )
            }
        }
    }
    
    // MARK: - 대화 내역 영역
    private var chatMessagesArea: some View {
        ScrollViewReader { scrollView in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message, showSubtitle: viewModel.showSubtitle)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)
                // 새 메시지가 추가될 때마다 스크롤
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
    
    private var messageInputArea: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                if !viewModel.isListening {
                    TextField("메시지 입력", text: $viewModel.inputText)
                        .padding(10)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(20)
                        .focused($isInputFocused)
                } else {
                    Text("음성 변환 중...")
                        .foregroundStyle(.secondary)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(20)
                }
                
                // 음성 관련 옵션 메뉴
                Menu {
                    // 키보드 모드 (현재 화면)
                    Button("키보드로 대화") {
                        // 이미 키보드 모드이므로 아무 작업 안함
                        viewModel.stopListening()
                    }
                    
                    // 음성 대화 모드
                    Button("음성으로 대화") {
                        showVoiceChatLive = true
                    }
                } label: {
                    Image(systemName: viewModel.isListening ? "mic.fill" : "mic")
                        .font(.system(size: 20))
                        .foregroundStyle(viewModel.isListening ? .red : .primary)
                        .padding(8)
                        .background(Color(UIColor.systemGray5))
                        .clipShape(Circle())
                }
                
                // 메시지 전송 버튼 (텍스트가 있을 때만 표시)
                if !viewModel.inputText.isEmpty && !viewModel.isListening {
                    Button(action: {
                        viewModel.sendMessage()
                        isInputFocused = false
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.blue)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
    
    private var voiceSettingsView: some View {
        NavigationView {
            Form {
                Section(header: Text("음성 설정")) {
                    // 자막 온/오프
                    Toggle("자막", isOn: $viewModel.showSubtitle)
                        .toggleStyle(SwitchToggleStyle(tint: .green))
                    
                    Picker("음성", selection: $viewModel.voiceGender) {
                        Text("남성").tag(SpeechService.VoiceGender.male)
                        Text("여성").tag(SpeechService.VoiceGender.female)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Picker("음성 타입", selection: $viewModel.voiceType) {
                        Text("사람 목소리").tag(SpeechService.VoiceType.human)
                        Text("동물 소리").tag(SpeechService.VoiceType.animal)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .navigationTitle("설정")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        showSettings = false
                    }
                }
            }
        }
    }
}


struct MessageBubble: View {
    let message: ChatMessage
    let showSubtitle: Bool
    
    var body: some View {
        HStack {
            if message.isFromPet {
                // 펫 메시지 (왼쪽 정렬)
                HStack(alignment: .bottom, spacing: 8) {
                    // 펫 프로필 이미지
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "pawprint.fill")
                                .foregroundColor(.blue)
                        )
                    
                    // 메시지 버블
                    VStack(alignment: .leading, spacing: 4) {
                        // 메시지 내용
                        Text(message.text)
                            .padding(12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(16)
                        
                        // 시간 표시
                        Text(formatTime(message.timestamp))
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .padding(.leading, 8)
                    }
                    
                    Spacer()
                }
            } else {
                // 사용자 메시지 (오른쪽 정렬)
                HStack(alignment: .bottom, spacing: 8) {
                    Spacer()
                    
                    // 메시지 버블
                    VStack(alignment: .trailing, spacing: 4) {
                        // 메시지 내용
                        Text(message.text)
                            .padding(12)
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .cornerRadius(16)
                        
                        // 시간 표시
                        Text(formatTime(message.timestamp))
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .padding(.trailing, 8)
                    }
                    
                    // 사용자 프로필 이미지
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                        )
                }
            }
        }
    }
    
    // 시간 포맷팅 함수
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
