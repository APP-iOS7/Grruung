//
//  ScreenView.swift
//  Grruung
//
//  Created by NoelMacMini on 6/2/25.
//

import SwiftUI

// 캐릭터 스크린 뷰
struct ScreenView: View {
    // HomeView에서 필요한 데이터를 받아옴
    let character: GRCharacter?
    let isSleeping: Bool
    
    // 애니메이션 컨트롤러 추가
    @StateObject private var eggController = EggController()
    @StateObject private var quokkaController = QuokkaController()
    
    @Environment(\.modelContext) private var modelContext
    
    // 이펙트 제어 상태
    @State private var currentEffect: EffectType = .none
    
    let onCreateCharacterTapped: (() -> Void)? //온보딩 콜백
    
    var body: some View {
        ZStack {
            Color.clear
            
            // 캐릭터 애니메이션 영역
            if let character = character {
                if shouldShowEggAnimation(evolutionStatus: character.status.evolutionStatus) {
                    // 운석 단계일 때 - EggController 사용
                    eggAnimationView
                } else {
                    // 다른 단계일 때 - QuokkaController 사용
                    quokkaAnimationView
                }
            } else {
                //// 캐릭터가 없을 때 기본 이미지
                //defaultView
                // 캐릭터가 없을 때 플러스 아이콘 표시
                defaultViewWithCreateButton
            }
            
            // 탭 이펙트 레이어
            // tapEffectLayer
            
            // 캐릭터가 자고 있을 때 "Z" 이모티콘 표시
            sleepingIndicator
        }
        .frame(height: 200)
        .onAppear {
            // 뷰가 나타날 때 애니메이션 시작
            setupControllers()
            startAppropriateAnimation()
        }
        .onDisappear {
            // 뷰가 사라질 때 애니메이션 정리
            cleanupControllers()
        }
        .onChange(of: character?.status.evolutionStatus) { _, _ in
            print("🔄 진화 상태 변경 감지! -> 뷰를 새로고침하고 애니메이션을 다시 시작합니다.")
            setupControllers()
            startAppropriateAnimation()
        }
        .onChange(of: isSleeping) { _, isNowSleeping in
            // 잠자기 상태가 변경될 때 애니메이션 전환
            handleSleepStateChange(isSleeping: isNowSleeping)
        }
        .onTapGesture {
            handleTap()
            // handleTapWithEffect() // 이펙트 탭
        }
    }
    
    // MARK: - 상태별 뷰
    
    // 현재 진화 상태에 따라 '보여줘야 할 모습'의 단계를 결정하는 변수
    private var visualPhase: CharacterPhase? {
        guard let character = character else { return nil }
        
        // 진화가 완료되지 않은 'to' 상태에서는 이전 단계를 보여준다.
        switch character.status.evolutionStatus {
        case .toInfant: return .egg
        case .toChild: return .infant
        case .toAdolescent: return .child
        case .toAdult: return .adolescent
        case .toElder: return .adult
        default:
            // 그 외 모든 경우(egg, completeInfant, completeChild 등)에는 현재 phase를 그대로 따름
            return character.status.phase
        }
    }
    
    // 캐릭터 생성 버튼이 포함된 기본 뷰
    @ViewBuilder
    private var defaultViewWithCreateButton: some View {
        Button(action: {
            onCreateCharacterTapped?() // 콜백 호출
        }) {
            VStack(spacing: 10) {
                Image(systemName: "plus.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 80)
                    .foregroundColor(.gray)
                
                Text("캐릭터 생성")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    
    // 운석 애니메이션 뷰
     @ViewBuilder
     private var eggAnimationView: some View {
         ZStack {
             // 받침대 (뒤쪽에 표시)
             Image("eggPedestal1")
                 .resizable()
                 .aspectRatio(contentMode: .fit)
                 .frame(height: 90) // 받침대 크기 조절
                 .offset(x: 0, y: 45) // 운석 아래쪽에 위치하도록 조정
             
             // 운석
             if let currentFrame = eggController.currentFrame {
                 Image(uiImage: currentFrame)
                     .resizable()
                     .aspectRatio(contentMode: .fit)
                     .frame(height: 180) // 배경보다 작게
                     .offset(x: 0, y: -40)
             } else {
                 // EggController가 로드되지 않았을 때 기본 이미지
                 Image("egg_normal_1")
                     .resizable()
                     .aspectRatio(contentMode: .fit)
                     .frame(height: 180)
                     .offset(x: 0, y: -40)
             }
         }
     }
    
    // 쿼카 애니메이션 뷰
    @ViewBuilder
    private var quokkaAnimationView: some View {
        if let currentFrame = quokkaController.currentFrame {
            let imageView = Image(uiImage: currentFrame)
                .resizable()
                .aspectRatio(contentMode: .fit)
            
            // evolutionStatus에 따라 다른 프레임과 오프셋을 적용
            switch character?.status.evolutionStatus {
            case .completeInfant, .toChild:
                // 소아기(완료) 이후 단계에서는 크기 키우기.
                imageView
                    .frame(height: 160) // 예시: 프레임 높이를 220으로 설정
                    .offset(y: 0)     // 예시: Y축 위치를 0만큼 이동
            case .completeChild, .toAdolescent, .completeAdolescent, .toAdult, .completeAdult, .toElder, .completeElder:
                // 소아기(완료) 이후 단계에서는 크기 키우기.
                imageView
                    .frame(height: 240) // 예시: 프레임 높이를 220으로 설정
                    .offset(y: 0)     // 예시: Y축 위치를 0만큼 이동
            default:
                // 그 외 모든 상태(.egg)일 때
                imageView
                    .frame(height: 180) // 기본 프레임 높이 180
            }
        } else {
            // 컨트롤러가 로드되지 않았을 때 기본 이미지 (e.g. 첫 프레임)
            // loadFirstFrame을 통해 초기 프레임을 설정해주는 것이 좋음
            ProgressView()
        }
    }
    
    // 기본 뷰 (캐릭터가 없을 때 & 로딩 중)
    // TODO: 로딩 중 뷰랑 캐릭터 없을 때 표시 분리하기
    @ViewBuilder
    private var defaultView: some View {
        ProgressView()
             .progressViewStyle(CircularProgressViewStyle()) // 보류
             .scaleEffect(1.5) // 보류
             .padding()
    }
    
    // 🎯 잠자는 표시
    @ViewBuilder
    private var sleepingIndicator: some View {
        VStack {
            Text("💤")
                .font(.largeTitle)
                .offset(x: 50, y: -50)
                .scaleEffect(isSleeping ? 1.3 : 0.7)
                .opacity(isSleeping ? 1.0 : 0.0) // 투명도로 보이기/숨기기 제어
                .animation(
                    isSleeping ?
                    Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true) :
                    .default,
                    value: isSleeping
                )
        }
    }
    
    // 이펙트 레이어
    @ViewBuilder
    private var tapEffectLayer: some View {
        ZStack {
            // 현재 이펙트에 따라 다른 이펙트 표시
            switch currentEffect {
            case .none:
                EmptyView()
            case .cleaning:
                CleaningEffect(isActive: .constant(true))
            case .sparkle:
                SparkleEffect.magical(isActive: .constant(true))
            case .pulse:
                PulseEffect.healing(isActive: .constant(true))
            case .healing:
                // 여러 이펙트 조합도 가능
                ZStack {
                    CleaningEffect(isActive: .constant(true))
                    SparkleEffect.golden(isActive: .constant(true))
                }
            }
        }
        .onChange(of: currentEffect) { oldValue, newValue in
            if newValue != .none {
                // 이펙트가 끝나면 자동으로 .none으로 리셋
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    currentEffect = .none
                }
            }
        }
    }
    
    // 이펙트 탭 처리
    private func handleTapWithEffect() {
        // 기존 로직
        if character?.status.phase == .egg || character == nil {
            eggController.toggleAnimation()
            print("🥚 운석 애니메이션 토글: \(eggController.isAnimating ? "재생" : "정지")")
        }
        
        // 🎯 이펙트 타입 설정 (다양한 이펙트 선택 가능)
        currentEffect = .cleaning
        
        // 또는 랜덤 이펙트
        // currentEffect = [.cleaning, .sparkle, .pulse].randomElement() ?? .cleaning
        
        print("✨ \(currentEffect) 이펙트 실행!")
    }
    
    // MARK: - 헬퍼 메서드
    
    // 컨트롤러들 설정
    private func setupControllers() {
        // QuokkaController에 SwiftData 컨텍스트 설정
        quokkaController.setModelContext(modelContext)
        
        // 캐릭터가 있고 egg가 아닌 경우 애니메이션 프레임 로드
        if let character = character, !shouldShowEggAnimation(evolutionStatus: character.status.evolutionStatus), let phase = visualPhase {
            quokkaController.loadFirstFrame(phase: phase, animationType: "normal")
        }
    }
    
    // 적절한 애니메이션 시작
    private func startAppropriateAnimation() {
        guard let character = character else {
            stopAllAnimations()
            return
        }
        
        // 먼저 모든 애니메이션 정지
        stopAllAnimations()
        
        if shouldShowEggAnimation(evolutionStatus: character.status.evolutionStatus) {
            eggController.startAnimation()
            print("운석 애니메이션 시작")
        } else if character.species == .quokka {
            // isSleeping 상태를 확인하여 초기 애니메이션 결정
            handleSleepStateChange(isSleeping: self.isSleeping)
        }
    }
    
    // isSleeping 상태 변화에 따른 애니메이션 처리
    private func handleSleepStateChange(isSleeping: Bool) {
        guard let character = character, character.species == .quokka else { return }
        
        guard let currentVisualPhase = self.visualPhase else { return }
        
        // 현재는 infant 단계만 특별한 수면/기상 애니메이션을 가짐
        if currentVisualPhase == .infant {
            if isSleeping {
                // 재우기: sleep1Start (once) -> sleep2Pingpong (pingPong)
                print("😴 재우기 애니메이션 시퀀스 시작")
                quokkaController.playAnimation(type: "sleep1Start", phase: .infant, mode: .once) {
                    // sleep1Start가 끝나면 실행됨
                    print(" transitioning to sleep2Pingpong")
                    quokkaController.playAnimation(type: "sleep2Pingpong", phase: .infant, mode: .pingPong)
                }
            } else {
                // 깨우기: sleep4WakeUp (once) -> normal (pingPong)
                print("☀️ 깨우기 애니메이션 시퀀스 시작")
                quokkaController.playAnimation(type: "sleep4WakeUp", phase: .infant, mode: .once) {
                    // sleep4WakeUp이 끝나면 실행
                    print(" --> normal 애니메이션으로 전환")
                    self.quokkaController.playAnimation(type: "normal", phase: .infant, mode: .pingPong)
                }
            }
        } else {
            // 일단 child 단계 이상에서는 isSleeping 상태와 관계없이 항상 normal 애니메이션 재생
            // 추후 애니메이션이 추가되는대로 업데이트 예정
             print("▶️ \(currentVisualPhase) 단계의 normal 애니메이션 재생")
            quokkaController.playAnimation(type: "normal", phase: currentVisualPhase, mode: .pingPong)
        }
    }
    
    // 모든 애니메이션 정지 메서드 추가
    private func stopAllAnimations() {
        eggController.stopAnimation()
        quokkaController.stopAnimation()
        print("⏹️ 모든 애니메이션 정지")
    }
    
    // 컨트롤러들 정리
    private func cleanupControllers() {
        stopAllAnimations() // 정지 먼저 하고
        
        eggController.cleanup()
        quokkaController.cleanup()
        print("모든 컨트롤러 정리 완료")
    }
    
    // 탭 처리
    private func handleTap() {
        guard let character = character else { return }
        
        if shouldShowEggAnimation(evolutionStatus: character.status.evolutionStatus) {
            // 운석 단계 - EggController 토글
            eggController.isAnimating ? eggController.stopAnimation() : eggController.startAnimation()
            print("운석 애니메이션 토글: \(eggController.isAnimating ? "재생" : "정지")")
        } else if character.species == .quokka {
            if quokkaController.isAnimating {
                quokkaController.stopAnimation()
                print("⏹️ 탭으로 애니메이션 정지")
            } else {
                print("▶️ 탭으로 애니메이션 재시작")
                startAppropriateAnimation()
            }
        }
    }
    
    // MARK: - 어떤 애니메이션을 보여줄지 결정하는 헬퍼 메서드
    // 운석 애니메이션을 보여줄지 결정하는 헬퍼 메서드
    private func shouldShowEggAnimation(evolutionStatus: EvolutionStatus) -> Bool {
        switch evolutionStatus {
        case .eggComplete, .toInfant:
            return true  // 운석 애니메이션 계속 표시
        default:
            return false // 진화 완료된 애니메이션 표시
        }
    }
}

#Preview {
    ScreenView(
        character: GRCharacter(
            species: .CatLion,
            name: "테스트",
            imageName: "CatLion",
            birthDate: Date()
        ),
        isSleeping: false,
        onCreateCharacterTapped: {
            print("프리뷰에서 캐릭터 생성 버튼이 눌렸습니다!")
        }
    )
    .padding()
}



