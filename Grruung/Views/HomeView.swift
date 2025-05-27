//
//  HomeView.swift
//  Grruung
//
//  Created by NoelMacMini on 5/1/25.
//

import SwiftUI

struct HomeView: View {
    // MARK: - Properties
    @EnvironmentObject private var authService: AuthService
    @StateObject private var viewModel = HomeViewModel()
    
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
                
                Spacer()
                
                // 액션 버튼 그리드
                actionButtonsGrid
            }
            .padding()
            .navigationTitle("나의 \(viewModel.character?.name ?? "캐릭터")")
            .onAppear {
                viewModel.loadCharacter()
            }
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
                Image(viewModel.character?.imageName ?? "CatLion")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                
                // 캐릭터가 자고 있을 때 "Z" 이모티콘 표시
                if viewModel.isSleeping {
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
                                .foregroundColor(stat.barColor)
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
            ForEach(viewModel.actionButtons.indices, id: \.self) { index in
                let action = viewModel.actionButtons[index]
                Button(action: {
                    performAction(at: index)
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
                                let iconName = (index == 3 && viewModel.isSleeping) ? "bed.double.fill" : action.icon
                                Image(systemName: iconName)
                                    .font(.system(size: 24))
                                    .foregroundColor(viewModel.isSleeping && index != 3 ? .gray : .primary)
                                
                                // 자고 있을 때 재우기 버튼의 텍스트 변경
                                let actionName = (index == 3 && viewModel.isSleeping) ? "깨우기" : action.name
                                Text(actionName)
                                    .font(.caption2)
                                    .foregroundColor(viewModel.isSleeping && index != 3 ? .gray : .primary)
                            }
                        }
                    }
                }
                .disabled(!action.unlocked || (viewModel.isSleeping && index != 3))
            }
        }
    }
    
    // 아이콘 버튼
    @ViewBuilder
    func iconButton(systemName: String, name: String, unlocked: Bool) -> some View {
        if systemName == "cart.fill" {
            NavigationLink(destination: StoreView()) {
                buttonContent(systemName: systemName, name: name, unlocked: unlocked)
            }
            .disabled(!unlocked)
        } else {
            Button(action: {
                handleSideButtonAction(systemName: systemName)
            }) {
                buttonContent(systemName: systemName, name: name, unlocked: unlocked)
            }
            .disabled(!unlocked || viewModel.isSleeping)
        }
    }
    
    // 버튼 내용 (재사용 가능한 부분)
    @ViewBuilder
    func buttonContent(systemName: String, name: String, unlocked: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .frame(width: 60, height: 60)
                .foregroundColor(unlocked ? Color.gray.opacity(0.2) : Color.gray.opacity(0.05))
            
            if unlocked {
                Image(systemName: systemName)
                    .font(.system(size: 24))
                    .foregroundColor(viewModel.isSleeping ? .gray : .primary)
            } else {
                Image(systemName: "lock.fill")
                    .foregroundColor(.gray)
            }
        }
    }
    
    // MARK: - 액션 처리 메서드
    
    // 액션 버튼 처리
    private func performAction(at index: Int) {
        switch index {
        case 0: // 밥주기
            viewModel.feedPet()
        case 1: // 놀아주기
            viewModel.playWithPet()
        case 2: // 씻기기
            viewModel.washPet()
        case 3: // 재우기/깨우기
            viewModel.putPetToSleep()
        default:
            break
        }
    }
    
    // 사이드 버튼 처리
    private func handleSideButtonAction(systemName: String) {
        switch systemName {
        case "backpack.fill": // 인벤토리
            print("인벤토리 버튼 클릭")
            // 인벤토리 화면으로 이동하는 로직 (나중에 추가)
        case "mountain.2.fill": // 동산
            print("동산 버튼 클릭")
            // 동산 화면으로 이동하는 로직 (나중에 추가)
        case "book.fill": // 일기
            print("일기 버튼 클릭")
            // 일기 화면으로 이동하는 로직 (나중에 추가)
        case "microphone.fill": // 채팅
            print("채팅 버튼 클릭")
            // 채팅 화면으로 이동하는 로직 (나중에 추가)
        case "gearshape.fill": // 설정
            print("설정 버튼 클릭")
            // 설정 화면으로 이동하는 로직 (나중에 추가)
        default:
            break
        }
    }
}

// MARK: - Preview
#Preview {
    HomeView()
}
