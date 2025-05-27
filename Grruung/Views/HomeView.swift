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
//
/*
 식사 관련 액션
 1. 밥주기
 * 포만감 +15
 * 에너지 +5
 * 체력 -3
 2. 간식주기
 * 포만감 +8
 * 행복도 +10
 * 건강 -3
 3. 영양제 주기 (추가 가능)
 * 건강 +10
 * 포만감 +3
 * 경험치 +2
 놀이/교감 관련 액션
 1. 놀아주기
 * 애정도 +12
 * 행복도 +10
 * 에너지 -8
 * 포만감 -5
 2. 쓰다듬기
 * 애정도 +8
 * 행복도 +5
 * 에너지 소모 없음
 3. 장난감 가지고 놀기 (추가 가능)
 * 행복도 +15
 * 경험치 +5
 * 에너지 -10
 * 포만감 -6
 건강/위생 관련 액션
 1. 씻기기
 * 청결도 +15
 * 건강 +5
 * 에너지 -3
 2. 산책하기
 * 건강 +12
 * 에너지 -10
 * 행복도 +8
 * 포만감 -8
 3. 털 빗어주기 (추가 가능)
 * 청결도 +10
 * 애정도 +5
 * 에너지 -2
 교육/성장 관련 액션
 1. 훈련하기
 * 훈련도/경험치 +15
 * 건강 +8
 * 에너지 -12
 * 포만감 -10
 2. 책 읽어주기 (추가 가능)
 * 경험치 +10
 * 애정도 +5
 * 에너지 -4
 휴식 관련 액션
 1. 재우기
 * 에너지 +20
 * 체력 +10
 * 시간 경과
 2. 낮잠 재우기 (추가 가능)
 * 에너지 +10
 * 체력 +5
 * 시간 약간 경과
 특별 액션 (성장 단계 또는 이벤트에 따라 해금)
 1. 특별 훈련
 * 훈련도/경험치 +20
 * 에너지 -15
 * 체력 +5
 * 포만감 -12
 2. 파티 열어주기
 * 행복도 +20
 * 사회성 +10
 * 에너지 -15
 * 포만감 -10
 3. 온천 데려가기
 * 건강 +15
 * 행복도 +10
 * 청결도 +15
 * 에너지 +5*/
//
//
// 0~8 작업 완료 후 → 테스트 시에는 모든 수치 증가 5~10배 적용(스텟들 수치 까지는것, 버튼 누르면 차는것 다 포함) + (디버그 모드에서만 작동)
// TODO: 9. 0~8번 테스트 완료 및 작업 완료되면 Firebase Firestore 연동
// TODO: 10. 만들어 놓은거 전부 연결
//
// 활동 액션들은 추후 추가 및 구현하기 편하게 //TODO: 추후 활동 액션 및 이벤트 액션 추가 이런식으로 주석처리로 해두기.
// 현재 추후 업데이트들을 위해 항상 재사용 하기 쉽게, 활동액션이 총 50개 넘어가도 관리하기 쉽도록 PetAction.swift랑 ActionManager.swift 파일을 구현해뒀으니 확인해서 맞춰서 소스 코드 작업하기.
//
// 골드 (인게임 재화)
// 활동 액션 별로 골드 획득 / 수면시 일정 골드 획득 / 레벨업 할때 일정 골드 획득
//
// HomeView의 UI 구조는 안바꿨으면 좋겠어. 단 기능을 추가할 때 마다 HomeView를 수정해야하니 각 기능 수정에 맞게 HomeView도 바로바로 맞춰서 수정하기.
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
                        // TODO: TODO 0. 애니메이션 작업
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
                    .scaleEffect(viewModel.isSleeping ? 0.95 : 1.0)
                // TODO: TODO 0 애니메이션 및 디플리케이티드 수정
                    .animation(
                        viewModel.isSleeping ?
                        Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true) :
                                .default,
                        value: viewModel.isSleeping
                    )
                
                
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
                            .foregroundColor(stat.color)
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
                                // TODO: TODO 0 애니메이션
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
/*
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
                .disabled(!action.unlocked || (viewModel.isSleeping && index != 3))*/
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
    
    // MARK: - 액션 처리 메서드
    
    // 액션 버튼 처리
    private func performAction(at index: Int) {
        switch index {
            /*
        case 0: // 밥주기
            viewModel.feedPet()
        case 1: // 놀아주기
            viewModel.playWithPet()
        case 2: // 씻기기
            viewModel.washPet()*/
        case 3: // 재우기/깨우기
            viewModel.putPetToSleep()
        default:
            break
        }
    }
}

// MARK: - Preview
#Preview {
    HomeView()
}
