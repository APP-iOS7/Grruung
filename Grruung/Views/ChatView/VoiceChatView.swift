//
//  VoiceChatLiveView.swift
//  Grruung
//
//  Created by KimJunsoo on 5/7/25.
//

import SwiftUI

struct VoiceChatView: View {
    // MARK: - 프로퍼티
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: VoiceChatViewModel
    @State private var showSettingsPopup = false
    
    // 캐릭터 정보
    private let character: GRCharacter
    private let prompt: String
    
    // 애니메이션 관련
    @State private var animationScale: CGFloat = 1.0
    
    // MARK: - 초기화
    init(character: GRCharacter, prompt: String) {
        self.character = character
        self.prompt = prompt
        
        _viewModel = StateObject(wrappedValue: VoiceChatViewModel(character: character, prompt: prompt))
    }
    
    // MARK: - 바디
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack {
                // 상단 네비게이션 영역
                HStack {
                    // 뒤로 가기 버튼
                    Button(action: {
                        endSession()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    // 제목
                    Text("음성 대화")
                        .font(.headline)
                    
                    Spacer()
                    
                    // 설정 버튼
                    Button(action: {
                        showSettingsPopup = true
                    }) {
                        Image(systemName: "gearshape")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                Spacer()
                
                // 펫 이미지 및 대화 영역
                VStack(spacing: 10) {
                    // 펫 이미지
                    characterImage
                        .scaleEffect(animationScale)
                        .animation(.spring(response: 0.3), value: viewModel.isSpeaking)
                    
                    // 펫 이름
                    Text(character.name)
                        .font(.headline)
                        .padding(.top, 4)
                    
                    Spacer()
                    
                    // 말풍선 (자막)
                    speechBubble
                }
                .padding(.top, 20)
                
                Spacer()
                
                // 음성 입력 상태 표시
                if viewModel.isListening {
                    Text(viewModel.userSpeech.isEmpty ? "듣고 있어요..." : viewModel.userSpeech)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(20)
                        .padding(.horizontal)
                        .transition(.opacity)
                }
                
                // 하단 컨트롤 영역
                HStack(spacing: 30) {
                    // 마이크 켜기/끄기 버튼
                    Button(action: {
                        viewModel.toggleMic()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: viewModel.micEnabled ? "mic.fill" : "mic.slash.fill")
                                .font(.system(size: 24))
                            Text(viewModel.micEnabled ? "마이크 켜짐" : "마이크 꺼짐")
                                .font(.caption)
                        }
                        .foregroundColor(viewModel.micEnabled ? .blue : .gray)
                        .frame(width: 80)
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
                    .disabled(!viewModel.micEnabled)
                    .opacity(viewModel.micEnabled ? 1.0 : 0.5)
                    
                    // 말하기 중지 버튼
                    Button(action: {
                        viewModel.stopSpeaking()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "speaker.slash.fill")
                                .font(.system(size: 24))
                            Text("말하기 중지")
                                .font(.caption)
                        }
                        .foregroundColor(viewModel.isSpeaking ? .primary : .gray)
                        .frame(width: 80)
                    }
                    .disabled(!viewModel.isSpeaking)
                }
                .padding(.bottom, 40)
            }
        }
        .onChange(of: viewModel.isSpeaking) { oldValue, newValue in
            if newValue {
                // 말하기 시작: 애니메이션 시작
                withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    animationScale = 1.05
                }
            } else {
                // 말하기 종료: 애니메이션 중지
                withAnimation {
                    animationScale = 1.0
                }
            }
        }
        .overlay(
            Group {
                if showSettingsPopup {
                    settingsOverlay
                }
                
                if viewModel.isLoading {
                    loadingOverlay
                }
            }
        )
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
    }
    
    // MARK: - 컴포넌트 뷰
    
    /// 캐릭터 이미지 뷰
    private var characterImage: some View {
        ZStack {
            // 배경 원형
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 200, height: 200)
            
            // 이미지가 있는 경우
            if !character.imageName.isEmpty {
                Image.characterImage(character.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
            } else {
                // 기본 이미지
                if character.species == .CatLion {
                    Image(systemName: "cat.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "hare.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    /// 말풍선 뷰
    private var speechBubble: some View {
        Group {
            if viewModel.showSpeechBubble && viewModel.subtitleEnabled {
                HStack {
                    Spacer()
                    
                    Text(viewModel.currentSpeech)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                        .transition(.opacity)
                    
                    Spacer()
                }
                .transition(.opacity)
            }
        }
    }
    
    /// 설정 팝업 오버레이
    private var settingsOverlay: some View {
        ZStack {
            // 배경 dimming
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .onTapGesture {
                    showSettingsPopup = false
                }
            
            // 설정 팝업 창
            VStack(spacing: 0) {
                // 팝업 제목
                Text("설정")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.systemGray5))
                
                // 설정 목록
                List {
                    // 자막 설정
                    Toggle("자막 표시", isOn: $viewModel.subtitleEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                    
                    // 음성 성별 설정
                    Section(header: Text("음성 선택")) {
                        Button(action: {
                            viewModel.voiceGender = .male
                        }) {
                            HStack {
                                Text("남성")
                                Spacer()
                                if viewModel.voiceGender == .male {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                        
                        Button(action: {
                            viewModel.voiceGender = .female
                        }) {
                            HStack {
                                Text("여성")
                                Spacer()
                                if viewModel.voiceGender == .female {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
                .listStyle(InsetGroupedListStyle())
                
                // 닫기 버튼
                Button(action: {
                    showSettingsPopup = false
                }) {
                    Text("닫기")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .padding(.bottom)
            }
            .background(Color(UIColor.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding(.horizontal, 40)
            .frame(maxWidth: 400)
        }
    }
    
    /// 로딩 오버레이
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                
                Text("잠시만 기다려주세요...")
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(Color(UIColor.systemGray6).opacity(0.8))
            .cornerRadius(10)
        }
    }
    
    // MARK: - 메서드
    
    /// 음성 인식 상태를 토글합니다.
    private func toggleListening() {
        if viewModel.isListening {
            viewModel.stopListening()
        } else {
            viewModel.startListening()
        }
    }
    
    /// 세션을 종료하고 화면을 닫습니다.
    private func endSession() {
        // 현재 진행 중인 음성 중지
        viewModel.stopSpeaking()
        viewModel.stopListening()
        
        // 세션 종료
        viewModel.endCurrentSession { _ in
            // 화면 닫기
            presentationMode.wrappedValue.dismiss()
        }
    }
}
