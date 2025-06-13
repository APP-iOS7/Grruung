//
//  HomeView.swift
//  Grruung
//
//  Created by NoelMacMini on 5/1/25.
//
//

import SwiftUI

struct HomeView: View {
    // MARK: - Properties
    @EnvironmentObject private var authService: AuthService
    @StateObject private var viewModel = HomeViewModel()
    @Environment(\.modelContext) private var modelContext // SwiftData 컨텍스트
    
    @State private var showInventory = false
    @State private var showPetGarden = false
    @State private var isShowingWriteStory = false
    @State private var isShowingChatPet = false
    @State private var isShowingSettings = false
    @State private var showEvolutionScreen = false // 진화 화면 표시 여부
    @State private var isShowingOnboarding = false
    @State private var showUpdateAlert = false // 업데이트 예정 알림창 표시 여부
    @State private var showSpecialEvent = false // 특수 이벤트 표시 여부
    @State private var showHealthCare = false // 건강관리 화면 표시 여부
    @State private var showUpdateScreen = false // 업데이트 화면 표시 상태

    // MARK: - Body
    var body: some View {
            NavigationStack {
                ZStack {
                    // FIXME: - Start 배경 이미지 전체 화면에 적용
                    // 배경 이미지 설정
                    GeometryReader { geometry in
                        Image("roomBasic1Big")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .edgesIgnoringSafeArea(.all)
                    }
                    .edgesIgnoringSafeArea(.all)
                    // FIXME: - END
                    
                    // 원래 콘텐츠는 그대로 유지
                    if viewModel.isLoadingFromFirebase || !viewModel.isDataReady {
                        // 로딩 중 표시
                        LoadingView()
                    } else {
                        VStack(spacing: 20) {
                            Spacer()
                            
                            // 레벨 프로그레스 바
                            levelProgressBar
                            
                            Spacer()
                            
                            // 메인 캐릭터 섹션
                            characterSection
                            
                            // 액션 버튼 그리드
                            actionButtonsGrid
                            
                            // 상태 바 섹션
                            statsSection
                            

                            Spacer()
                            
                            // 커스텀 탭바를 위한 여백
                            Color.clear
                                .frame(height: 40)
                        }
                        .padding()
                    }
                }
                .scrollContentBackground(.hidden) // 기본 배경 숨기기
                .navigationBarBackButtonHidden(true)
            .onAppear {
                viewModel.loadCharacter()
            }
        }
        .alert("안내", isPresented: $showUpdateAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("추후 업데이트 예정입니다.")
        }
        .sheet(isPresented: $showInventory) {
            //            InventoryView(character: viewModel.character)
        }
        .sheet(isPresented: $showPetGarden) {
            //            PetGardenView(character: viewModel.character)
        }
        .sheet(isPresented: $isShowingWriteStory) {
            if let character = viewModel.character {
                NavigationStack {
                    WriteStoryView(
                        currentMode: .create,
                        characterUUID: character.id
                    )
                    .environmentObject(authService)
                }
            }
        }
        .sheet(isPresented: $isShowingChatPet) {
            if let character = viewModel.character {
                let prompt = PetPrompt(
                    petType: character.species,
                    phase: character.status.phase,
                    name: character.name
                ).generatePrompt(status: character.status)
                
                ChatPetView(character: character, prompt: prompt)
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            //            SettingsSheetView()
        }
        
        // 진화 화면 시트
        .sheet(isPresented: $showEvolutionScreen) {
            if let character = viewModel.character {
                EvolutionView(
                    character: character,
                    homeViewModel: viewModel,
                    isUpdateMode: false  // 진화 모드
                )
            }
        }
        
        // 업데이트 화면 시트
        .sheet(isPresented: $showUpdateScreen) {
            if let character = viewModel.character {
                EvolutionView(
                    character: character,
                    homeViewModel: viewModel,
                    isUpdateMode: true  // 업데이트 모드
                )
            }
        }
        
        // 온보딩 화면 시트
        .sheet(isPresented: $isShowingOnboarding) {
            OnboardingView()
        }
        // 부화 팝업 오버레이
        .overlay {
            if viewModel.showEvolutionPopup {
                EvolutionPopupView(
                    isPresented: $viewModel.showEvolutionPopup,
                    onEvolutionStart: {
                        // 부화 버튼을 눌렀을 때 진화 화면 표시
                        showEvolutionScreen = true
                        print("🥚 부화 시작 - 진화 화면으로 이동")
                    },
                    onEvolutionDelay: {
                        // 보류 버튼을 눌렀을 때는 아무것도 하지 않음
                        print("⏸️ 부화 보류 - 나중에 다시 시도 가능")
                    }
                )
            }
            
            // 특수이벤트
            if showSpecialEvent {
                SpecialEventView(viewModel: viewModel, isPresented: $showSpecialEvent)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: showSpecialEvent)
            }
            
            // 헬스케어
            if showHealthCare {
                    HealthCareView(
                        viewModel: viewModel,
                        isPresented: $showHealthCare
                    )
                }
        }
    }
    
    // 부화 진행 버튼
    private var evolutionButton: some View {
        Button(action: {
            showEvolutionScreen = true
        }) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                
                // 진화 상태에 따라 버튼 텍스트 변경
                Text(getEvolutionButtonText())
                    .font(.body)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [Color.orange, Color.red],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
        }
    }
    
    // 업데이트 버튼
    private var updateButton: some View {
        Button(action: {
            showUpdateScreen = true
        }) {
            HStack {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 16))
                
                Text("데이터 업데이트")
                    .font(.body)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
        }
    }
    
    // 진화 상태에 따른 버튼 텍스트 반환
    private func getEvolutionButtonText() -> String {
        guard let character = viewModel.character else { return "부화 진행" }
        
        switch character.status.evolutionStatus {
        case .toInfant:
            return "부화 진행"
        case .toChild:
            return "소아기 진화"
        case .toAdolescent:
            return "청년기 진화"
        case .toAdult:
            return "성년기 진화"
        case .toElder:
            return "노년기 진화"
        default:
            return "진화 진행"
        }
    }
    
    // 상태 메시지에 따른 색상을 반환합니다.
    private func getMessageColor() -> Color {
        let message = viewModel.statusMessage.lowercased()
        
        if message.contains("배고파") || message.contains("아파") || message.contains("지쳐") {
            return .red
        } else if message.contains("피곤") || message.contains("더러워") || message.contains("외로워") {
         
            return .orange
        } else if message.contains("행복") || message.contains("좋은") || message.contains("감사") {
            return .green
        } else if message.contains("잠을") {
            return .blue
        } else {
            return .primary
        }
    }
    
    // MARK: - UI Components
    
    // 레벨 프로그레스 바
    private var levelProgressBar: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("레벨 \(viewModel.level)")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                ZStack(alignment: .leading) {
                    // 배경 바 (전체 너비)
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 30)
                    
                    // 진행 바
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(hex: "6159A0"))
                            .frame(width: geometry.size.width * viewModel.expPercent, height: 30)
                            .animation(.easeInOut(duration: 0.8), value: viewModel.expPercent)
                        
                    }
                    .frame(height: 30)
                }
            }
        }
        .padding(.top, 10)
    }
    
    // 캐릭터 섹션
    private var characterSection: some View {
        ZStack {
            // 캐릭터 이미지
            VStack {
                Spacer()
                
                ZStack {
                    ScreenView(
                        character: viewModel.character,
                        isSleeping: viewModel.isSleeping,
                        onCreateCharacterTapped: {
                            // 캐릭터 생성 버튼이 눌렸을 때 온보딩 표시
                            isShowingOnboarding = true
                        }
                    )
                    
                    // 상태 메시지 말풍선 (비어있지 않을 때만 표시)Add commentMore actions
                    if !viewModel.statusMessage.isEmpty && !viewModel.isSleeping {
                        SpeechBubbleView(message: viewModel.statusMessage, color: getMessageColor())
                            .offset(y: -140) // 말풍선 위치 조정
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .animation(.easeInOut(duration: 0.5), value: viewModel.statusMessage)
                    }
                }
            }
            
            HStack {
                // 왼쪽 버튼들
                VStack(spacing: 15) {
                    ForEach(0..<3) { index in
                        let button = viewModel.sideButtons[index]
                        iconButton(systemName: button.icon, name: button.name, unlocked: button.unlocked)
                    }
                }
                
                Spacer()
                
                // 오른쪽 버튼들
                VStack(spacing: 15) {
                    ForEach(3..<6) { index in
                        let button = viewModel.sideButtons[index]
                        iconButton(systemName: button.icon, name: button.name, unlocked: button.unlocked)
                    }
                }
            }
            
            VStack {
                Spacer()
                
                // 부화&진화 진행 버튼 (진화가 필요한 경우에만 표시)
                if let character = viewModel.character,
                   character.status.evolutionStatus.needsEvolution {
                    evolutionButton
                }
                
                // 업데이트 버튼 (업데이트가 필요한 경우에만 표시)
                if viewModel.needsAnimationUpdate {
                    updateButton
                }
            }
        }
    }
    
    // 상태 바 섹션
    private var statsSection: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.stats, id: \.icon) { stat in
                HStack(spacing: 15) {
                    // 아이콘
                    Image(systemName: stat.icon)
                        .foregroundColor(stat.iconColor)
                        .frame(width: 30)
                    
                    // 상태 바
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // 배경 바 (전체 너비)
                            RoundedRectangle(cornerRadius: 10)
                                .frame(height: 12)
                                .foregroundColor(Color.gray.opacity(0.1))
                            
                            // 진행 바
                            RoundedRectangle(cornerRadius: 10)
                                .frame(width: geometry.size.width * stat.value, height: 12)
                                .foregroundColor(stat.color)
                                .animation(.easeInOut(duration: 0.6), value: stat.value)
                        }
                    }
                    .frame(height: 12)
                }
            }
        }
        .padding(.vertical)
    }
    
    // 액션 버튼 그리드
    private var actionButtonsGrid: some View {
        HStack(spacing: 15) {
            ForEach(Array(viewModel.actionButtons.enumerated()), id: \.offset) { index, action in
                Button(action: {
                    if action.icon == "plus.circle" {
                        // 캐릭터 생성 버튼인 경우 온보딩 화면으로 이동
                        isShowingOnboarding = true
                    } else {
                        viewModel.performAction(at: index)
                    }
                }) {
                    ZStack {
                        // 배경 블러 효과와 불투명도 증가
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(action.unlocked ? 0.25 : 0.15))
                            .frame(width: 75, height: 75)
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        
                        if !action.unlocked {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                        } else {
                            VStack(spacing: 5) {
                                // 아이콘 크기 증가 및 그림자 추가
                                Image(systemName: action.icon)
                                    .font(.system(size: 28))
                                    .foregroundColor(viewModel.isSleeping && action.icon != "bed.double" && action.icon != "plus.circle" ?
                                        .gray : GRColor.buttonColor_2)
                                    .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                                
                                // 텍스트에 그림자 추가
                                Text(action.name)
                                    .font(.caption)
                                    .bold()
                                    .foregroundColor(.white)
                                    .shadow(color: Color.black.opacity(0.7), radius: 2, x: 0, y: 1)
                            }
                            .padding(8)
                        }
                    }
                    // 버튼에 테두리 추가
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                }
                .disabled(viewModel.isAnimationRunning || (viewModel.isSleeping && action.icon != "bed.double" && action.icon != "plus.circle"))
            }
        }
    }
    
    // 아이콘 버튼
    @ViewBuilder
    func iconButton(systemName: String, name: String, unlocked: Bool) -> some View {
        if !unlocked {
            // 잠긴 버튼
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 60, height: 60)
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                
                Image(systemName: "lock.fill")
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
        } else {
            if systemName == "cart.fill" {
                NavigationLink(destination: StoreView()) {
                    ZStack {
                        // 배경 블러 효과와 불투명도 증가
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 60, height: 60)
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        
                        VStack(spacing: 3) {
                            // 아이콘 크기 증가 및 그림자 추가
                            Image(systemName: systemName)
                                .font(.system(size: 28))
                                .foregroundColor(GRColor.buttonColor_2)
                                .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                            
                            // 텍스트 추가
                            Text(name)
                                .font(.system(size: 9))
                                .bold()
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.7), radius: 2, x: 0, y: 1)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                }
            } else if systemName == "backpack.fill" {
                NavigationLink(destination: UserInventoryView()) {
                    ZStack {
                        // 배경 블러 효과와 불투명도 증가
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 60, height: 60)
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        
                        VStack(spacing: 3) {
                            // 아이콘 크기 증가 및 그림자 추가
                            Image(systemName: systemName)
                                .font(.system(size: 28))
                                .foregroundColor(GRColor.buttonColor_2)
                                .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                            
                            // 텍스트 추가
                            Text(name)
                                .font(.system(size: 9))
                                .bold()
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.7), radius: 2, x: 0, y: 1)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                }
            } else {
                Button(action: {
                    handleButtonAction(systemName: systemName)
                }) {
                    ZStack {
                        // 배경 블러 효과와 불투명도 증가
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 60, height: 60)
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        
                        VStack(spacing: 3) {
                            // 아이콘 크기 증가 및 그림자 추가
                            Image(systemName: systemName)
                                .font(.system(size: 28))
                                .foregroundColor(GRColor.buttonColor_2)
                                .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                            
                            // 텍스트 추가
                            Text(name)
                                .font(.system(size: 9))
                                .bold()
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.7), radius: 2, x: 0, y: 1)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
    }
    
    private func handleButtonAction(systemName: String) {
        // 애니메이션 실행 중일 때는 액션 처리하지 않음
        guard !viewModel.isAnimationRunning else {
            return
        }
        
        switch systemName {
        case "backpack.fill": // 인벤토리
            showInventory.toggle()
        case "heart.text.square.fill": // 헬스케ㅇ
            if let character = viewModel.character {
                showHealthCare = true
            } else {
                // 캐릭터가 없는 경우 경고 표시
                viewModel.statusMessage = "먼저 캐릭터를 생성해주세요."
            }
        case "fireworks": // 특수 이벤트 (아이콘 변경)
            withAnimation {
                showSpecialEvent = true
            }
        case "book.fill": // 일기
            if let character = viewModel.character {
                // 스토리 작성 시트 표시
                isShowingWriteStory = true
            } else {
                // 캐릭터가 없는 경우 경고 표시
                viewModel.statusMessage = "먼저 캐릭터를 생성해주세요."
            }
        case "microphone.fill": // 채팅
            if let character = viewModel.character {
                // 챗펫 시트 표시
                isShowingChatPet = true
            } else {
                // 캐릭터가 없는 경우 경고 표시
                viewModel.statusMessage = "먼저 캐릭터를 생성해주세요."
            }
        case "lock.fill": // 설정
            // 설정 시트 표시
            showUpdateAlert = true
        default:
            break
        }
    }
    
    // 버튼 내용 (재사용 가능한 부분)
    private func handleSideButtonAction(systemName: String) {
        switch systemName {
        case "backpack.fill": // 인벤토리
            showInventory.toggle()
        case "heart.text.square.fill": // 헬스케어
            if let character = viewModel.character {
                showHealthCare = true
            } else {
                // 캐릭터가 없는 경우 경고 표시
                viewModel.statusMessage = "먼저 캐릭터를 생성해주세요."
            }
        case "fireworks": // 동산
            showSpecialEvent.toggle() // 특수 이벤트 표시
        case "book.fill": // 일기
            if let character = viewModel.character {
                // 스토리 작성 시트 표시
                isShowingWriteStory = true
            } else {
                // 캐릭터가 없는 경우 경고 표시
                viewModel.statusMessage = "먼저 캐릭터를 생성해주세요."
            }
        case "microphone.fill": // 채팅
            if let character = viewModel.character {
                // 챗펫 시트 표시
                isShowingChatPet = true
            } else {
                // 캐릭터가 없는 경우 경고 표시
                viewModel.statusMessage = "먼저 캐릭터를 생성해주세요."
            }
        case "lock.fill": // 설정
            // 설정 시트 표시
            showUpdateAlert = true
        default:
            break
        }
    }
    
}

// MARK: - Preview
#Preview {
    HomeView()
}
