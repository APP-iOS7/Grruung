//
//  HomeView.swift
//  Grruung
//
//  Created by NoelMacMini on 5/1/25.
//

import SwiftUI

/// 홈 화면 뷰
struct HomeTestView: View {
    // MARK: - 0. 프로퍼티
    @StateObject private var viewModel = HomeViewModel()
    @State private var showChatPet = false
    @State private var showPetSettings = false
    
    // MARK: - 1. 바디
    var body: some View {
        ZStack {
            // 배경
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            // 메인 콘텐츠
            VStack(spacing: 0) {
                // 상단 상태바 및 네비게이션
                homeHeader
                
                // 메인 펫 표시 영역
                petDisplayArea
                
                // 활동 탭 및 버튼 영역
                activityTabsArea
                
                // 하단 메뉴 버튼
                bottomMenuArea
            }
            .padding(.horizontal, 16)
            
            // 로딩 인디케이터
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .background(Color.black.opacity(0.2))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            // 테스트 캐릭터 생성 (실제 앱에서는 Firebase에서 로드)
            viewModel.createTestCharacter()
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
        .sheet(isPresented: $showChatPet) {
            if let character = viewModel.selectedCharacter,
               let prompt = viewModel.generateChatPetPrompt() {
                ChatPetView(
                    character: character,
                    prompt: prompt
                )
            } else {
                Text("캐릭터 정보를 불러오는 중 오류가 발생했습니다.")
            }
        }
        .sheet(isPresented: $showPetSettings) {
            petSettingsView
        }
    }
    
    // MARK: - 2. 홈 헤더 뷰
    private var homeHeader: some View {
        VStack(spacing: 8) {
            
            // 성장 수치 표시
            VStack(spacing: 8) {
                // 운동량
                HStack {
                    Text("운동량")
                        .font(.footnote)
                        .frame(width: 50, alignment: .leading)
                    
                    ProgressBar(value: viewModel.activityPercent, color: .green)
                }
                
                // 체력
                HStack {
                    Text("체력")
                        .font(.footnote)
                        .frame(width: 50, alignment: .leading)
                    
                    ProgressBar(value: viewModel.staminaPercent, color: .blue)
                }
                
                // 포만감
                HStack {
                    Text("포만감")
                        .font(.footnote)
                        .frame(width: 50, alignment: .leading)
                    
                    ProgressBar(value: viewModel.satietyPercent, color: .orange)
                }
                
                // 경험치
                HStack {
                    Text("Exp \(Int(viewModel.expPercent * 100))%")
                        .font(.footnote)
                        .frame(width: 70, alignment: .leading)
                    
                    ProgressBar(value: viewModel.expPercent, color: .purple)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - 3. 펫 표시 영역
    private var petDisplayArea: some View {
        VStack {
            ZStack {
                // 펫 이미지 (또는 빈 공간)
                if let character = viewModel.selectedCharacter {
                    Image(character.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                        .padding(.vertical, 20)
                        .overlay(
                            // 펫 상태 메시지
                            Text(viewModel.getStatusMessage())
                                .font(.system(size: 14, weight: .medium))
                                .padding(8)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(8)
                                .shadow(radius: 2)
                                .padding(16),
                            alignment: .top
                        )
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .foregroundColor(Color.gray.opacity(0.2))
                        .frame(height: 200)
                        .overlay(
                            VStack {
                                Image(systemName: "plus.circle")
                                    .font(.largeTitle)
                                
                                Text("펫 추가하기")
                                    .font(.headline)
                                    .padding(.top, 8)
                            }
                        )
                }
                
                // 테스트 모드 설정 버튼 (디버그용)
                if viewModel.testMode {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                showPetSettings = true
                            }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .padding(16)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - 4. 활동 탭 영역
    private var activityTabsArea: some View {
        VStack(spacing: 16) {
            // 활동 탭 헤더
            HStack {
                Text("활동 탭")
                    .font(.headline)
                
                Spacer()
            }
            
            // 활동 버튼 그리드
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                // 쓰다듬기
                ActivityButton(title: "쓰다듬기", icon: "hand.tap.fill") {
                    // 쓰다듬기 액션
                    viewModel.updateSelectedCharacter(affection: 5)
                    viewModel.addExperience(1)
                }
                
                // 닦아주기
                ActivityButton(title: "닦아주기", icon: "shower.fill") {
                    // 닦아주기 액션
                    viewModel.updateSelectedCharacter(clean: 10)
                    viewModel.addExperience(2)
                }
                
                // 훈련시키기
                ActivityButton(title: "훈련시키기", icon: "figure.walk") {
                    // 훈련시키기 액션
                    viewModel.updateSelectedCharacter(stamina: -5, activity: 10)
                    viewModel.addExperience(3)
                }
                
                // 먹이주기
                ActivityButton(title: "먹이주기", icon: "fork.knife") {
                    // 먹이주기 액션
                    viewModel.updateSelectedCharacter(satiety: 15, stamina: 5)
                    viewModel.addExperience(1)
                }
                
                // 놀아주기
                ActivityButton(title: "놀아주기", icon: "gamecontroller.fill") {
                    // 놀아주기 액션
                    viewModel.updateSelectedCharacter(stamina: -10, activity: 5, affection: 10)
                    viewModel.addExperience(2)
                }
                
                // 목욕하기
                ActivityButton(title: "목욕하기", icon: "drop.fill") {
                    // 목욕하기 액션
                    viewModel.updateSelectedCharacter(stamina: -5, clean: 20)
                    viewModel.addExperience(2)
                }
            }
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - 5. 하단 메뉴 영역
    private var bottomMenuArea: some View {
        HStack(spacing: 20) {
            // 들려준 이야기
            BottomMenuItem(icon: "book.fill", title: "들려준 이야기") {
                // 들려준 이야기 액션
            }
            
            // 인벤토리
            BottomMenuItem(icon: "bag.fill", title: "인벤토리") {
                // 인벤토리 액션
            }
            
            // BM 아이템
            BottomMenuItem(icon: "cart.fill", title: "BM 아이템") {
                // BM 아이템 액션
            }
            
            // 동산
            BottomMenuItem(icon: "leaf.fill", title: "동산") {
                // 동산 액션
            }
            
            // 음성 대화
            BottomMenuItem(icon: "bubble.left.fill", title: "음성 대화") {
                // 음성 대화 액션
                showChatPet = true
            }
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - 6. 펫 설정 뷰 (테스트용)
    private var petSettingsView: some View {
        NavigationView {
            Form {
                Section(header: Text("테스트 설정")) {
                    // 펫 종류 선택
                    Picker("펫 종류", selection: $viewModel.testSpecies) {
                        ForEach(PetSpecies.allCases, id: \.self) { species in
                            Text(species.rawValue).tag(species)
                        }
                    }
                    
                    // 성장 단계 선택
                    Picker("성장 단계", selection: $viewModel.testPhase) {
                        ForEach([
                            CharacterPhase.infant,
                            CharacterPhase.child,
                            CharacterPhase.adolescent,
                            CharacterPhase.adult,
                            CharacterPhase.elder
                        ], id: \.self) { phase in
                            Text(phase.rawValue).tag(phase)
                        }
                    }
                }
                
                Section {
                    Button("테스트 캐릭터 생성") {
                        viewModel.createTestCharacter()
                        showPetSettings = false
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("펫 설정")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        showPetSettings = false
                    }
                }
            }
        }
    }
}

// MARK: - 7. 보조 구조체 (UI 컴포넌트)

/// 프로그레스 바 컴포넌트
struct ProgressBar: View {
    let value: CGFloat
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 배경
                Rectangle()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .opacity(0.2)
                    .foregroundColor(color)
                
                // 진행 바
                Rectangle()
                    .frame(width: min(CGFloat(value) * geometry.size.width, geometry.size.width), height: geometry.size.height)
                    .foregroundColor(color)
                    .animation(.linear, value: value)
            }
            .cornerRadius(10)
        }
        .frame(height: 10)
    }
}

/// 활동 버튼 컴포넌트
struct ActivityButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.blue)
            .cornerRadius(10)
        }
    }
}

/// 하단 메뉴 아이템 컴포넌트
struct BottomMenuItem: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
    }
}

/// 알림 아이템 (오류 표시용)
struct AlertItem: Identifiable {
    let id = UUID()
    let message: String
}

#Preview {
    HomeTestView()
}
