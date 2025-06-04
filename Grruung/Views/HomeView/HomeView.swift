//
//  HomeView.swift
//  Grruung
//
//  Created by NoelMacMini on 5/1/25.
//
// TODO: 10. 만들어 놓은거 전부 연결
// 활동 액션 별로 골드 획득 / 수면시 일정 골드 획득 / 레벨업 할때 일정 골드 획득
//

import SwiftUI

struct HomeView: View {
    // MARK: - Properties
    @EnvironmentObject private var authService: AuthService
    @StateObject private var viewModel = HomeViewModel()
    
    @State private var showInventory = false
    @State private var showPetGarden = false
    @State private var isShowingWriteStory = false
    @State private var isShowingChatPet = false
    @State private var isShowingSettings = false
    @State private var isShowingOnboarding = false

    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                
                // 레벨 프로그레스 바
                levelProgressBar
                
                // 메인 캐릭터 섹션
                characterSection
                
                Spacer()
                
                // 상태 바 섹션
                statsSection
                
                // 캐릭터 상태 메시지
                Text(viewModel.statusMessage)
                    .font(viewModel.character?.status.phase == .egg ? .system(.headline, design: .monospaced) : .headline)
                    .italic(viewModel.character?.status.phase == .egg) // 운석 상태일 때는 이탤릭체로 표시
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 5)
                    .foregroundColor(getMessageColor())
                
                Spacer()
                
                // 액션 버튼 그리드
                actionButtonsGrid
            }
            .padding()
//            .navigationTitle("나의 \(viewModel.character?.name ?? "캐릭터")")
            .navigationBarBackButtonHidden(true)
            .onAppear {
                viewModel.loadCharacter()
            }
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
        .sheet(isPresented: $isShowingOnboarding) {
            OnboardingView()
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
        HStack {
            // 왼쪽 버튼들
            VStack(spacing: 15) {
                ForEach(0..<3) { index in
                    let button = viewModel.sideButtons[index]
                    iconButton(systemName: button.icon, name: button.name, unlocked: button.unlocked)
                }
            }
            
            Spacer()
            
            // 캐릭터 이미지
            ZStack {
                if let character = viewModel.character {
                    // 조건부 로직을 직접 Image 생성에 적용
                    Group {
                        if character.status.phase == .egg {
                            // 운석 단계일 경우 이미지 사용
                            Image("egg")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 200)
                        } else {
                            // 그 외 단계에서는 species에 따라 이미지 결정
                            if character.species == .quokka {
                                Image("quokka")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 200)
                            } else {
                                Image("CatLion")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 200)
                            }
                        }
                    }
                    .scaleEffect(viewModel.isSleeping ? 0.95 : 1.0)
                    .animation(
                        viewModel.isSleeping ?
                        Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true) :
                                .default,
                        value: viewModel.isSleeping
                    )
                } else {
                    // 캐릭터가 없는 경우 플러스 아이콘 표시
                    Button(action: {
                        isShowingOnboarding = true
                    }) {
                        Image(systemName: "plus.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 100)
                            .foregroundColor(.gray)
                    }
                }
                
                // 캐릭터가 자고 있을 때 "Z" 이모티콘 표시
                if viewModel.isSleeping, viewModel.character != nil {
                    VStack {
                        Text("💤")
                            .font(.largeTitle)
                            .offset(x: 50, y: -50)
                    }
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
                        RoundedRectangle(cornerRadius: 10)
                            .frame(width: 75, height: 75)
                            .foregroundColor(action.unlocked ? Color.gray.opacity(0.1) : Color.gray.opacity(0.05))
                        
                        if !action.unlocked {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                        } else {
                            VStack(spacing: 5) {
                                Image(systemName: action.icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(viewModel.isSleeping && action.icon != "bed.double" && action.icon != "plus.circle" ? .gray : .primary)
                                
                                Text(action.name)
                                    .font(.caption2)
                                    .foregroundColor(viewModel.isSleeping && action.icon != "bed.double" && action.icon != "plus.circle" ? .gray : .primary)
                            }
                        }
                    }
                }
                .disabled(!action.unlocked || (viewModel.isSleeping && action.icon != "bed.double" && action.icon != "plus.circle"))
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
                    .frame(width: 60, height: 60)
                    .foregroundColor(Color.gray.opacity(0.05))
                
                Image(systemName: "lock.fill")
                    .foregroundColor(.gray)
            }
        } else {
            if systemName == "cart.fill" {
                NavigationLink(destination: StoreView()) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .frame(width: 60, height: 60)
                            .foregroundColor(Color.gray.opacity(0.2))
                        Image(systemName: systemName)
                            .font(.system(size: 24))
                            .foregroundColor(.black) // 회색에서 검은색으로 변경
                    }
                }
            } else if systemName == "backpack.fill" {
                NavigationLink(destination: UserInventoryView()) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .frame(width: 60, height: 60)
                            .foregroundColor(Color.gray.opacity(0.2))
                        Image(systemName: systemName)
                            .font(.system(size: 24))
                            .foregroundColor(.black) // 회색에서 검은색으로 변경
                    }
                }
            } else if systemName == "mountain.2.fill" {
                NavigationLink(destination: CharDexView()) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .frame(width: 60, height: 60)
                            .foregroundColor(Color.gray.opacity(0.2))
                        Image(systemName: systemName)
                            .font(.system(size: 24))
                            .foregroundColor(.black) // 회색에서 검은색으로 변경
                    }
                }
            } else {
                Button(action: {
                    handleSideButtonAction(systemName: systemName)
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .frame(width: 60, height: 60)
                            .foregroundColor(viewModel.isSleeping ? Color.gray.opacity(0.05) : Color.gray.opacity(0.2))
                        
                        Image(systemName: systemName)
                            .font(.system(size: 24))
                            .foregroundColor(viewModel.isSleeping ? .gray : .black) // .primary에서 .black으로 변경
                    }
                }
                .disabled(viewModel.isSleeping)
            }
        }
    }
    
    // 버튼 내용 (재사용 가능한 부분)
    private func handleSideButtonAction(systemName: String) {
        switch systemName {
        case "backpack.fill": // 인벤토리
            showInventory.toggle()
        case "cart.fill": // 상점
            // NavigationLink는 이미 처리됨
            break
        case "mountain.2.fill": // 동산
            showPetGarden.toggle()
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
        case "gearshape.fill": // 설정
            // 설정 시트 표시
            isShowingSettings.toggle()
        default:
            break
        }
    }
    
}

// MARK: - Preview
#Preview {
    HomeView()
}
