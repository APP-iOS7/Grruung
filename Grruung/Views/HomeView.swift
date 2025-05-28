//
//  HomeView.swift
//  Grruung
//
//  Created by NoelMacMini on 5/1/25.
//
// TODO: 0. 경험치바, 상태바 애니메이션 부드럽게 상승되게 변경
// TODO: 1. 6분마다 체력(피로도) 1씩 회복됨 + 수면중 누르면 2~5배(밸런스 조정)
// TODO: 2. 각 시기(운석(알): 50, 유아기: 100, 소아기: 150, 청년기: 200, 성년기: 300, 노년기: 500 별로 레벨업하는 경험치 요구량 고정 - 완
// TODO: 3. 운석(알)때는 튜토리얼 개념으로 경험치 빨리 획득하게 해서 최대한 빨리 유아기로 갈 수 있게 설정 (기본 획득량이 3이면 운석(알)에서만 5배 빨리 획득 이런식) - 완
// TODO: 4. 상태바 프로그레스 스텟 80이상 파란색 / 21~79 녹색 / 20이하 빨간색 으로 나오게 하기
// TODO: 5. 보이는 스텟 (포만감, 운동량)은 일정시간 마다 -1씩 깎이고 / 히든 스텟 (건강, 청결)도 보이는 스텟보다는 긴 일정 시간이후로 -되고 / 애정도는 매일 06시 기준 활동 한번도 안했으면 -(깎이게) 되게
// TODO: 6. 활동버튼은 액션마다 추가 해놓고 랜덤으로 나오게 하기. / 22:00 ~ 06:00 은 잠자기 무조건 나오게 -> 이건 추후 마이페이지 설정에서 변경하거나 워치 연결 시 수면 시간에 맞춰서 나오게 변경 - 완
// TODO: 7. 동산 버튼이 누르면 현재 키우던 펫을 캐릭터뷰에 마지막 상태, 스텟, 대화내용, 들어준이야기 내용들 저장 후 홈뷰는 빈상태 -> 펫추가(처음부터 새로 키울 수 있게) 뷰로 변경
// TODO: 8. 사이드 버튼 중 잠겨 있는 버튼 - 유아기~노년기 각 성장 시기마다 특정 조건을 달성하면 히든 활동(또는 스토리) 등장. → 지용님 확인하고 답변좀 - 사이드 버튼만 완료 / 특수 이벤트 처리 아직 X
// 운석 상태 활동 : 사이드 버튼 6개 다 잠겨있고, 쓰다듬기, 닦아주기 2개만 나오게 설정. 상태바는 전부 100에서 마이너스, 플러스 없음. 잠겨있는것 처럼 고정. 경험치만 증가함
// 유아기 부터 : 상태바 전부 Max(100), 건강,청결도 100으로 시작. 애정도만 0으로 시작. 사이드 버튼 다 열리고, 활동 버튼 전부 사용 가능.
// 레벨업으로 인해 시기가 바뀐다고 각 현재 상태바들을 다시 MAX로 만들어주지않고 현재 스텟 그대로에서 최대스텟만 일정 상승 (건강,청결은 무조건 100이 최대치)
// 추후 파이어베이스 연결할 곳들은 //TODO: Firestore에서 ~~ 구현 으로 주석처리로 적어두기.
// 0~8 작업 완료 후 → 테스트 시에는 모든 수치 증가 5~10배 적용(스텟들 수치 까지는것, 버튼 누르면 차는것 다 포함) + (디버그 모드에서만 작동)
// TODO: 9. 0~8번 테스트 완료 및 작업 완료되면 Firebase Firestore 연동
// TODO: 10. 만들어 놓은거 전부 연결
// 활동 액션 별로 골드 획득 / 수면시 일정 골드 획득 / 레벨업 할때 일정 골드 획득


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
                    .foregroundColor(getMessageColor())
                
                Spacer()
                
                // 액션 버튼 그리드
                actionButtonsGrid
            }
            .padding()
            .navigationTitle("나의 \(viewModel.character?.name ?? "캐릭터")") // 추후 삭제
            .onAppear {
                viewModel.loadCharacter()
            }
        }
    }
    
    // MARK: - UI Components
    
    // 레벨 프로그레스 바
    // FIXME: - 일단 한번 변경해보고 마음에 안들면 다시 이전 코드로 롤백 예정
    private var levelProgressBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("레벨 \(viewModel.level)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 현재 성장 단계 표시
                if let character = viewModel.character {
                    Text(character.status.phase.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                        .foregroundColor(.blue)
                }
            }
            
            // 경험치 프로그레스 바
            ZStack(alignment: .leading) {
                // 배경 바
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 30)
                
                // 진행 바
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 15)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "6159A0"), Color(hex: "8B7ED8")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * viewModel.expPercent, height: 30)
                        .animation(.easeInOut(duration: 0.8), value: viewModel.expPercent)
                }
                .frame(height: 30)
                
                // 경험치 텍스트
                HStack {
                    Spacer()
                    Text("\(viewModel.expValue) / \(viewModel.expMaxValue)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    Spacer()
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
                // 캐릭터 배경 원
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.blue.opacity(0.1),
                                Color.blue.opacity(0.05)
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 120
                        )
                    )
                    .frame(width: 220, height: 220)
                
                // 캐릭터 이미지
                Image(viewModel.character?.imageName ?? "CatLion")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 180)
                    .scaleEffect(viewModel.isSleeping ? 0.95 : 1.0)
                    .opacity(viewModel.isSleeping ? 0.8 : 1.0)
                    .animation(
                        viewModel.isSleeping ?
                        Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true) :
                                .easeInOut(duration: 0.3),
                        value: viewModel.isSleeping
                    )
                
                // 수면 상태 표시 개선
                if viewModel.isSleeping {
                    VStack {
                        HStack {
                            Spacer()
                            VStack(spacing: 5) {
                                Text("💤")
                                    .font(.title)
                                    .opacity(0.8)
                                Text("💤")
                                    .font(.title2)
                                    .opacity(0.6)
                                Text("💤")
                                    .font(.body)
                                    .opacity(0.4)
                            }
                            .offset(x: -20, y: -60)
                            .animation(
                                Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: false),
                                value: viewModel.isSleeping
                            )
                        }
                        Spacer()
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
    
    // 상태 바 섹션(3개의 보이는 스탯만 표시)
    // 마음에 안들면 롤백
    private var statsSection: some View {
        VStack(spacing: 15) {
            // 스탯 제목
            HStack {
                Text("펫 상태")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            
            // 3개의 보이는 스탯만 표시
            VStack(spacing: 12) {
                ForEach(viewModel.stats, id: \.icon) { stat in
                    HStack(spacing: 15) {
                        // 아이콘
                        Image(systemName: stat.icon)
                            .foregroundColor(stat.iconColor)
                            .frame(width: 25)
                        
                        // 스탯 이름
                        Text(getStatName(for: stat.icon))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(width: 60, alignment: .leading)
                        
                        // 상태 바
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // 배경 바
                                RoundedRectangle(cornerRadius: 6)
                                    .frame(height: 12)
                                    .foregroundColor(Color.gray.opacity(0.2))
                                
                                // 진행 바
                                RoundedRectangle(cornerRadius: 6)
                                    .frame(width: geometry.size.width * stat.value, height: 12)
                                    .foregroundColor(stat.color)
                                    .animation(.easeInOut(duration: 0.6), value: stat.value)
                            }
                        }
                        .frame(height: 12)
                        
                        // 수치 표시
                        Text(getStatValue(for: stat.icon))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 5)
    }
    
    // 상태 메시지에 따른 색상을 반환
    // 마음에 안들면 삭제
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
    
    // 스탯 아이콘에 따른 한글 이름을 반환
    // 마음에 안들면 삭제
    private func getStatName(for icon: String) -> String {
        switch icon {
        case "fork.knife":
            return "포만감"
        case "figure.run":
            return "운동량"
        case "bolt.fill":
            return "활동량"
        default:
            return "알 수 없음"
        }
    }
    
    // 스탯 아이콘에 따른 현재 수치를 반환
    // 마음에 안들면 삭제
    private func getStatValue(for icon: String) -> String {
        switch icon {
        case "fork.knife":
            return "\(viewModel.satietyValue)"
        case "figure.run":
            return "\(viewModel.staminaValue)"
        case "bolt.fill":
            return "\(viewModel.activityValue)"
        default:
            return "0"
        }
    }
    
    // 액션 버튼 그리드
    // 마음에 안들면 롤백
    private var actionButtonsGrid: some View {
        VStack(spacing: 15) {
            // 액션 버튼 제목
            HStack {
                Text("활동")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                
                // 활동량 표시
                HStack(spacing: 5) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text("\(viewModel.activityValue)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(viewModel.activityValue < 20 ? .red : .primary)
                }
            }
            
            // 액션 버튼들
            HStack(spacing: 15) {
                ForEach(Array(viewModel.actionButtons.enumerated()), id: \.offset) { index, action in
                    Button(action: {
                        viewModel.performAction(at: index)
                    }) {
                        VStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .frame(width: 75, height: 75)
                                    .foregroundColor(getActionButtonBackgroundColor(action: action))
                                
                                if !action.unlocked {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 24))
                                } else {
                                    // 수면 상태에 따른 아이콘 변경
                                    let iconName = getActionIcon(action: action, index: index)
                                    Image(systemName: iconName)
                                        .font(.system(size: 24))
                                        .foregroundColor(getActionIconColor(action: action, index: index))
                                }
                            }
                            
                            // 액션 이름
                            Text(getActionName(action: action, index: index))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(getActionTextColor(action: action, index: index))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .disabled(!action.unlocked || isActionDisabled(action: action, index: index))
                    .scaleEffect(action.unlocked && !isActionDisabled(action: action, index: index) ? 1.0 : 0.95)
                    .animation(.easeInOut(duration: 0.2), value: action.unlocked)
                }
            }
        }
    }
    
    // 액션 버튼 배경색을 반환합니다.
    private func getActionButtonBackgroundColor(action: (icon: String, unlocked: Bool, name: String)) -> Color {
        if !action.unlocked {
            return Color.gray.opacity(0.1)
        } else if viewModel.isSleeping && action.icon != "bed.double" {
            return Color.gray.opacity(0.05)
        } else {
            return Color.gray.opacity(0.15)
        }
    }
    
    // 수면 상태에 따른 액션 아이콘을 반환합니다.
    private func getActionIcon(action: (icon: String, unlocked: Bool, name: String), index: Int) -> String {
        if action.icon == "bed.double" && viewModel.isSleeping {
            return "bed.double.fill"
        }
        return action.icon
    }
    
    // 액션 아이콘 색상을 반환합니다.
    private func getActionIconColor(action: (icon: String, unlocked: Bool, name: String), index: Int) -> Color {
        if viewModel.isSleeping && action.icon != "bed.double" {
            return .gray
        } else if action.icon == "bed.double" {
            return viewModel.isSleeping ? .blue : .purple
        } else {
            return .primary
        }
    }
    
    // 수면 상태에 따른 액션 이름을 반환합니다.
    private func getActionName(action: (icon: String, unlocked: Bool, name: String), index: Int) -> String {
        if action.icon == "bed.double" && viewModel.isSleeping {
            return "깨우기"
        }
        return action.name
    }
    
    // 액션 텍스트 색상을 반환합니다.
    private func getActionTextColor(action: (icon: String, unlocked: Bool, name: String), index: Int) -> Color {
        if viewModel.isSleeping && action.icon != "bed.double" {
            return .gray
        } else {
            return .primary
        }
    }
    
    // 액션이 비활성화되어야 하는지 확인합니다.
    private func isActionDisabled(action: (icon: String, unlocked: Bool, name: String), index: Int) -> Bool {
        return viewModel.isSleeping && action.icon != "bed.double"
    }
    
    // 아이콘 버튼
    @ViewBuilder
    func iconButton(systemName: String, name: String, unlocked: Bool) -> some View {
        if systemName == "cart.fill" {
            // 상점 버튼은 NavigationLink로 처리
            NavigationLink(destination: StoreView()) {
                sideButtonContent(systemName: systemName, name: name, unlocked: unlocked)
            }
            .disabled(!unlocked || viewModel.isSleeping)
        } else {
            // 다른 사이드 버튼들
            Button(action: {
                handleSideButtonAction(systemName: systemName)
            }) {
                sideButtonContent(systemName: systemName, name: name, unlocked: unlocked)
            }
            .disabled(!unlocked || viewModel.isSleeping)
        }
    }
    
    // 버튼 내용 (재사용 가능한 부분)
    @ViewBuilder
    private func sideButtonContent(systemName: String, name: String, unlocked: Bool) -> some View {
        VStack(spacing: 5) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .frame(width: 60, height: 60)
                    .foregroundColor(getSideButtonBackgroundColor(unlocked: unlocked))
                
                if unlocked {
                    Image(systemName: systemName)
                        .font(.system(size: 24))
                        .foregroundColor(viewModel.isSleeping ? .gray : .primary)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                }
            }
            
            // 버튼 이름 (작은 텍스트)
            Text(name)
                .font(.caption2)
                .foregroundColor(unlocked ? (viewModel.isSleeping ? .gray : .secondary) : .gray)
                .multilineTextAlignment(.center)
        }
    }
    
    // 사이드 버튼 배경색을 반환합니다.
    private func getSideButtonBackgroundColor(unlocked: Bool) -> Color {
        if unlocked {
            return viewModel.isSleeping ? Color.gray.opacity(0.1) : Color.gray.opacity(0.2)
        } else {
            return Color.gray.opacity(0.05)
        }
    }
    
    // MARK: - 액션 처리 메서드
    
    // 사이드 버튼 처리
    private func handleSideButtonAction(systemName: String) {
        switch systemName {
        case "backpack.fill": // 인벤토리
            print("인벤토리 버튼 클릭")
            // TODO: 인벤토리 화면으로 이동하는 로직
        case "mountain.2.fill": // 동산
            print("동산 버튼 클릭")
            // TODO: 동산 화면으로 이동하는 로직
        case "book.fill": // 일기
            print("일기 버튼 클릭")
            // TODO: 일기 화면으로 이동하는 로직
        case "microphone.fill": // 채팅
            print("채팅 버튼 클릭")
            // TODO: 채팅 화면으로 이동하는 로직
        case "gearshape.fill": // 설정
            print("설정 버튼 클릭")
            // TODO: 설정 화면으로 이동하는 로직
        default:
            break
        }
    }
}

// MARK: - Preview
#Preview {
    HomeView()
}
