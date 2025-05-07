//
//  VoiceChatLiveView.swift
//  Grruung
//
//  Created by KimJunsoo on 5/7/25.
//

import SwiftUI

struct VoiceChatLiveView: View {
    // MARK: - 프로퍼티
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: ChatPetViewModel
    @State private var showSettings = false
    @State private var showSpeechBubble = false
    @State private var currentSpeech = ""
    
    // 캐릭터 정보 직접 저장
    private let character: GRCharacter
    private let prompt: String
    
    // MARK: - 초기화
    init(character: GRCharacter, prompt: String) {
        self.character = character
        self.prompt = prompt
        _viewModel = StateObject(wrappedValue: ChatPetViewModel(character: character, prompt: prompt))
    }
    
    // MARK: - 바디
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack {
                // 펫 이미지 및 대화 영역
                ZStack {
                    // 펫 이미지
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 200, height: 200)
                        .overlay(
                            Image(systemName: "pawprint.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                                .foregroundColor(.blue)
                                // 말할 때 바운스 애니메이션
                                .scaleEffect(viewModel.isSpeaking ? 1.1 : 1.0)
                                .animation(.spring(response: 0.3), value: viewModel.isSpeaking)
                        )
                    
                    // 말풍선 (실시간으로 나타났다 사라짐)
                    if showSpeechBubble && viewModel.showSubtitle {
                        VStack {
                            Spacer()
                            
                            Text(currentSpeech)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(16)
                                .transition(.opacity)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 32)
                        }
                    }
                }
                .padding(.top, 40)
                
                // 펫 이름
                Text(character.name)
                    .font(.headline)
                    .padding(.top, 8)
                
                Spacer()
                
                // 하단 컨트롤 영역
                HStack(spacing: 40) {
                    // 키보드 대화 모드 버튼
                    Button(action: {
                        // 키보드 대화 모드로 전환
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "keyboard")
                                .font(.system(size: 24))
                            Text("키보드로 대화")
                                .font(.caption)
                        }
                        .padding()
                        .foregroundColor(.primary)
                    }
                    
                    // 음성 인식 버튼 (중앙)
                    Button(action: {
                        toggleListening()
                    }) {
                        ZStack {
                            Circle()
                                .fill(viewModel.isListening ? Color.red.opacity(0.2) : Color.blue.opacity(0.2))
                                .frame(width: 70, height: 70)
                            
                            Image(systemName: viewModel.isListening ? "mic.fill" : "mic")
                                .font(.title)
                                .foregroundColor(viewModel.isListening ? .red : .blue)
                        }
                    }
                    
                    // 대화 종료 버튼
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 24))
                            Text("대화 종료")
                                .font(.caption)
                        }
                        .padding()
                        .foregroundColor(.primary)
                    }
                }
                .padding(.bottom, 40)
            }
            
            // 설정 버튼 (우측 상단)
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.primary)
                            .padding()
                    }
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showSettings) {
            settingsView
        }
        .onAppear {
            // 초기 인사 메시지 생성
            if !viewModel.messages.isEmpty, let firstMessage = viewModel.messages.first {
                showSpeechWithAnimation(firstMessage.text)
            } else {
                let greeting = "그르릉... 안녕하세요! 무엇을 도와드릴까요?"
                showSpeechWithAnimation(greeting)
            }
        }
    }
    
    // MARK: - 메서드
    
    /// 음성 인식 토글
    private func toggleListening() {
        viewModel.isListening.toggle()
        
        if viewModel.isListening {
            // 음성 인식 시작
            viewModel.startListening()
            
            // "듣고 있어요..." 메시지 표시
            showSpeechWithAnimation("듣고 있어요...")
        } else {
            // 음성 인식 중지
            viewModel.stopListening()
            
            // 사용자 입력에 대한 응답 생성
            if !viewModel.inputText.isEmpty {
                // 사용자 메시지 보내기
                viewModel.sendMessage()
                
                // 응답 대기 메시지
                showSpeechWithAnimation("생각 중이에요...")
                
                // 실제 앱에서는 응답이 오면 처리
                // 지금은 임시로 지연 후 응답 표시
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    if let lastMessage = viewModel.messages.last, lastMessage.isFromPet {
                        showSpeechWithAnimation(lastMessage.text)
                    }
                }
            }
        }
    }
    
    /// 말풍선에 텍스트를 표시하고 애니메이션 적용
    private func showSpeechWithAnimation(_ text: String) {
        // 현재 말풍선 숨기기
        withAnimation {
            showSpeechBubble = false
        }
        
        // 텍스트 업데이트 후 말풍선 표시
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentSpeech = text
            
            withAnimation {
                showSpeechBubble = true
            }
            
            // 말하는 애니메이션 처리
            viewModel.isSpeaking = true
            
            // 텍스트 길이에 비례해 음성 발화 시간 계산 (실제로는 AVSpeechSynthesizer의 delegate로 처리)
            let speakingDuration = Double(text.count) * 0.05 + 2.0
            
            // n초 후에 말풍선 숨기기
            DispatchQueue.main.asyncAfter(deadline: .now() + speakingDuration) {
                withAnimation {
                    showSpeechBubble = false
                    viewModel.isSpeaking = false
                }
            }
        }
    }
    
    // MARK: - 설정 뷰
    private var settingsView: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 설정 컨테이너
                VStack(spacing: 0) {
                    // 자막 설정
                    HStack {
                        Text("자막")
                            .font(.headline)
                        
                        Spacer()
                        
                        Toggle("", isOn: $viewModel.showSubtitle)
                            .toggleStyle(SwitchToggleStyle(tint: .green))
                            .labelsHidden()
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    
                    Divider()
                    
                    // 음성 설정
                    VStack(alignment: .leading, spacing: 12) {
                        Text("음성")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.top, 12)
                        
                        HStack {
                            // 남성 음성 선택
                            Button(action: {
                                viewModel.voiceGender = .male
                            }) {
                                HStack {
                                    Text("남성")
                                        .foregroundColor(viewModel.voiceGender == .male ? .primary : .secondary)
                                    
                                    Spacer()
                                    
                                    if viewModel.voiceGender == .male {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(viewModel.voiceGender == .male ? Color.white : Color.clear)
                                .cornerRadius(8)
                            }
                            
                            // 여성 음성 선택
                            Button(action: {
                                viewModel.voiceGender = .female
                            }) {
                                HStack {
                                    Text("여성")
                                        .foregroundColor(viewModel.voiceGender == .female ? .primary : .secondary)
                                    
                                    Spacer()
                                    
                                    if viewModel.voiceGender == .female {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(viewModel.voiceGender == .female ? Color.white : Color.clear)
                                .cornerRadius(8)
                            }
                        }
                        .padding(.bottom, 12)
                    }
                    .background(Color(UIColor.systemGray6))
                }
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
                
                // 자막 설명
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("자막")
                            .font(.headline)
                        
                        Spacer()
                    }
                    
                    Text("펫이 말한 음성을 나타났다가 사라지게")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
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
