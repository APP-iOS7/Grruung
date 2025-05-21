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
    
    // 캐릭터 정보
    let character: GRCharacter
    let prompt: String
    
    // 애니메이션 관련
    @State private var animationScale: CGFloat = 1.0
    @State private var showSettings = false
    
    @State private var testSubtitle = "안녕하세요! 반가워요. 오늘은 어떻게 지내고 계세요?"
    
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
            
            VStack(spacing: 0) {
                
                Spacer()
                
                // 펫 영역
                VStack(spacing: 10) {
                    // 펫 이미지 (점으로 된 원 이미지)
                    ZStack {
                        // 점으로 된 원 이미지
                        Circle()
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
                            .frame(width: 300, height: 300)
                            .foregroundStyle(.gray.opacity(0.5))
                        
                        // 실제 펫 이미지
                        if !character.imageName.isEmpty {
                            Image.characterImage(character.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                        } else {
                            // 기본 이미지
                            Image(systemName: character.species == .CatLion ? "cat.fill" : "hare.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundStyle(.blue)
                        }
                    }
                    .scaleEffect(animationScale)
                    
                    // 펫 이름과 테스트 버튼
                    HStack {
                        Text(character.name)
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Button(action: {
                            testJamak()
                        }) {
                            Text("테스트")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.top, 10)
                    
                    // 말풍선 (자막)
                    if viewModel.showSpeechBubble && viewModel.subtitleEnabled {
                        Text(viewModel.currentSpeech)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(20)
                            .padding(.horizontal, 30)
                            .padding(.top, 20)
                            .transition(.opacity)
                    }
                }
                .padding(.vertical)
                
                Spacer()
                
                // 음성 인식 중인 경우 텍스트 표시
                if viewModel.isListening {
                    Text(viewModel.userSpeech.isEmpty ? "듣고 있어요..." : viewModel.userSpeech)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(20)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                        .transition(.opacity)
                }
                
                // 하단 제어 버튼 - 이미지 스타일로 변경
                HStack {
                    // 왼쪽: 나가기 버튼
                    Button(action: {
                        endSession()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 70, height: 70)
                            
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundStyle(.primary)
                        }
                    }
                    
                    Spacer()
                    
                    // 중앙: 음성 인식 버튼
                    Button(action: {
                        toggleListening()
                    }) {
                        ZStack {
                            Circle()
                                .fill(viewModel.isListening ? Color.red.opacity(0.2) : Color.blue.opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: viewModel.isListening ? "mic.fill" : "mic")
                                .font(.title)
                                .foregroundStyle(viewModel.isListening ? .red : .blue)
                        }
                    }
                    .disabled(!viewModel.micEnabled)
                    .opacity(viewModel.micEnabled ? 1.0 : 0.5)
                    
                    Spacer()
                    
                    // 오른쪽: 마이크 켜기/끄기 버튼
                    Button(action: {
                        viewModel.toggleMic()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 70, height: 70)
                            
                            Image(systemName: viewModel.micEnabled ? "mic.fill" : "mic.slash.fill")
                                .font(.title2)
                                .foregroundStyle(viewModel.micEnabled ? .blue : .gray)
                        }
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .onChange(of: viewModel.isSpeaking) { _, newValue in
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
        .overlay {
            if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("잠시만 기다려달라냥...")
                            .foregroundStyle(.white)
                    }
                    .padding(30)
                    .background(Color(UIColor.systemGray6).opacity(0.8))
                    .cornerRadius(10)
                }
            }
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
    }
    
    // MARK: - 컴포넌트 뷰
    
    
    // 캐릭터 이미지 뷰
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
    
    // 말풍선 뷰
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
    
    // 로딩 오버레이
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
    
    // 음성 인식 상태를 토글합니다.
    private func toggleListening() {
        if viewModel.isListening {
            viewModel.stopListening()
        } else {
            viewModel.startListening()
        }
    }
    
    // 세션을 종료하고 화면을 닫습니다.
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
    
    // 자막 테스트를 위한 메서드
    private func testJamak() {
        // 말풍선 보여주기
        withAnimation {
            viewModel.currentSpeech = testSubtitle
            viewModel.showSpeechBubble = true
        }
        
        // 음성 재생
        viewModel.speakAndStore(text: testSubtitle, isFromPet: true)
    }
}

// MARK: - Preview
#Preview {
    // 테스트용 캐릭터와 프롬프트 생성
    let testCharacter = GRCharacter(
        species: .CatLion,
        name: "냥냥이",
        imageName: "cat.fill",
        birthDate: Date(),
        status: GRCharacterStatus(phase: .child)
    )
    
    let testPrompt = "당신은 '냥냥이'라는 이름의 소아기 고양이사자 다마고치입니다."
    
    return VoiceChatView(character: testCharacter, prompt: testPrompt)
}
