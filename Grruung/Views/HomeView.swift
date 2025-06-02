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
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 레벨 프로그레스 바
                levelProgressBar
                
                // 메인 캐릭터 섹션
                characterSection
                
                Spacer()
                
                // 상태 바 섹션
                statsSection
                
                // 캐릭터 상태 메시지
                Text(viewModel.statusMessage)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 5)
                    .foregroundColor(getMessageColor()) // 이것만 추가
                
                Spacer()
                
                // 액션 버튼 그리드
                actionButtonsGrid
            }
            .padding()
            .scrollContentBackground(.hidden) // 기본 배경 숨기기
            .background(
                // 배경 이미지 설정
                Image("forest1")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .scaleEffect(1.1) // 줌인 줌아웃
                    .offset(x: -10, y: -145) // 위치 조정

                    // .clipped() // 넘치는 부분 잘라내기
                    //.ignoresSafeArea(.all)
            )
            .navigationTitle("나의 \(viewModel.character?.name ?? "캐릭터")")
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
            ScreenView(
                character: viewModel.character,
                isSleeping: viewModel.isSleeping
            )
            
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
            // FIXME: ForEach에서 RandomAccessCollection 에러 해결
            ForEach(Array(viewModel.actionButtons.enumerated()), id: \.offset) { index, action in
                Button(action: {
                    viewModel.performAction(at: index)
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
                                // 자고 있을 때 재우기 버튼의 아이콘 변경
                                
                                Image(systemName: action.icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(viewModel.isSleeping && action.icon != "bed.double" ? .gray : .primary)
                                
                                Text(action.name)
                                    .font(.caption2)
                                    .foregroundColor(viewModel.isSleeping && action.icon != "bed.double" ? .gray : .primary)
                            }
                        }
                    }
                }
                .disabled(!action.unlocked || (viewModel.isSleeping && action.icon != "bed.double"))
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
                    .foregroundColor(Color.gray.opacity(0.6))
                
                Image(systemName: "lock.fill")
                    .foregroundColor(.white)
            }
        } else {
            if systemName == "cart.fill" {
                NavigationLink(destination: StoreView()) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .frame(width: 60, height: 60)
                            .foregroundColor(Color.gray.opacity(0.6))
                        Image(systemName: systemName)
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                }
            } else if systemName == "backpack.fill" {
                NavigationLink(destination: UserInventoryView()) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .frame(width: 60, height: 60)
                                .foregroundColor(Color.gray.opacity(0.6))
                            Image(systemName: systemName)
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                    }
            } else if systemName == "mountain.2.fill" {
                NavigationLink(destination: CharDexView()) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .frame(width: 60, height: 60)
                            .foregroundColor(Color.gray.opacity(0.6))
                        Image(systemName: systemName)
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                }
            } else {
                Button(action: {
                    handleSideButtonAction(systemName: systemName)
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .frame(width: 60, height: 60)
                            .foregroundColor(viewModel.isSleeping ? Color.gray.opacity(0.1) : Color.gray.opacity(0.6))
                        
                        Image(systemName: systemName)
                            .font(.system(size: 24))
                            .foregroundColor(viewModel.isSleeping ? .black : .white)
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
