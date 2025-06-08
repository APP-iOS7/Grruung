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
    let quokkaController: QuokkaController? // (기존 @StateObject 제거하고 전달받은 것 사용)
    
    @Environment(\.modelContext) private var modelContext
    
    // 이펙트 제어 상태
    @State private var currentEffect: EffectType = .none
    
    let onCreateCharacterTapped: (() -> Void)? //온보딩 콜백
    
    var body: some View {
        ZStack {
            Color.clear
            
            // 캐릭터 애니메이션 영역
            // 캐릭터 상태에 따라 다른 애니메이션 표시
            if let character = character {
                if shouldShowEggAnimation(evolutionStatus: character.status.evolutionStatus) {
                    // 운석 단계일 때 - EggController 사용
                    eggAnimationView
                } else {
                    // 다른 단계일 때 - QuokkaController 사용
                    // regularCharacterView
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
        .onChange(of: character?.status.evolutionStatus) { oldValue, newValue in
            print("🔄 진화 상태 변경: \(oldValue?.rawValue ?? "nil") → \(newValue?.rawValue ?? "nil")")
            // 진화 상태가 변경되면 애니메이션 다시 설정
            setupControllers()
            startAppropriateAnimation()
        }
        // 수면 상태 변경 감지 추가
        .onChange(of: isSleeping) { oldValue, newValue in
            guard oldValue != newValue else { return }
            
            print("😴 수면 상태 변경: \(oldValue) → \(newValue)")
            // 직접 애니메이션 제어 (startAppropriateAnimation 호출하지 않음)
            guard let character = character, character.species == .quokka, character.status.phase == .infant else { return }
            
            if newValue {
                // 잠들기
                quokkaController?.startSleepAnimation()
            } else {
                // 깨어나기
                quokkaController?.stopSleepAnimation()
            }
        }
        .onTapGesture {
            handleTap()
            // handleTapWithEffect() // 이펙트 탭
        }
    }
    
    // MARK: - 상태별 뷰
    
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
                 .offset(x: 0, y: 67) // 운석 아래쪽에 위치하도록 조정
             
             // 운석
             if let currentFrame = eggController.currentFrame {
                 Image(uiImage: currentFrame)
                     .resizable()
                     .aspectRatio(contentMode: .fit)
                     .frame(height: 180) // 배경보다 작게
             } else {
                 // EggController가 로드되지 않았을 때 기본 이미지
                 Image("egg_normal_1")
                     .resizable()
                     .aspectRatio(contentMode: .fit)
                     .frame(height: 180)
             }
         }
     }
    
    // 일반 캐릭터 뷰 (운석이 아닌 단계)
    @ViewBuilder
    private var regularCharacterView: some View {
        if let character = character {
            Image(character.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 180)
        }
    }
    
    // 쿼카 애니메이션 뷰
    @ViewBuilder
    private var quokkaAnimationView: some View {
        if let currentFrame = quokkaController?.currentFrame {
            Image(uiImage: currentFrame)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 180)
        } else {
            // QuokkaController가 로드되지 않았을 때 기본 이미지
            Image("quokka")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 180)
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
        // QuokkaController는 HomeViewModel에서 전달받으므로 별도 설정 불필요
        // 캐릭터가 있고 egg가 아닌 경우 애니메이션 프레임 로드
        if let character = character, character.status.phase != .egg {
            loadCharacterAnimationFrames(character: character)
        }
    }
    
    // 캐릭터 애니메이션 프레임 로드
    private func loadCharacterAnimationFrames(character: GRCharacter) {
        switch character.species {
        case .quokka:
            // 수면 상태에 따라 다른 애니메이션 로드
            if isSleeping {
                // 수면 중이면 수면 애니메이션 시작
                quokkaController?.startSleepAnimation()
            } else {
                // 깨어있으면 normal 애니메이션 로드
                quokkaController?.loadAnimationFrames(animationType: "normal")
            }
            print("🐨 쿼카 \(character.status.phase.rawValue) 애니메이션 프레임 로드")
            
        case .CatLion:
            // CatLion은 아직 구현되지 않음
            print("🦁 CatLion 애니메이션은 아직 지원되지 않습니다")
            
        case .Undefined:
            print("❓ 정의되지 않은 캐릭터 종류")
        }
    }
    
    // 적절한 애니메이션 시작
    private func startAppropriateAnimation() {
        guard let character = character else { return }
        
        // 먼저 모든 애니메이션 정지
        stopAllAnimations()
        
        if character.status.phase == .egg {
            // 운석 단계 - EggController 애니메이션 시작
            eggController.startAnimation()
            print("운석 애니메이션 시작")
        } else {
            // 다른 단계 - QuokkaController 애니메이션 시작
            if character.species == .quokka {
                if isSleeping {
                    // 수면 중이면 수면 애니메이션
                    quokkaController?.startSleepAnimation()
                    print("쿼카 수면 애니메이션 시작")
                } else {
                    // 깨어있으면 일반 핑퐁 애니메이션
                    quokkaController?.startPingPongAnimation()
                    print("쿼카 핑퐁 애니메이션 시작")
                }
            }
        }
    }
    
    // 모든 애니메이션 정지 메서드 추가
    private func stopAllAnimations() {
        eggController.stopAnimation()
        quokkaController?.stopAnimation()
        print("⏹️ 모든 애니메이션 정지")
    }
    
    // 컨트롤러들 정리
    private func cleanupControllers() {
        stopAllAnimations() // 정지 먼저 하고
        
        eggController.cleanup()
        quokkaController?.cleanup()
        print("모든 컨트롤러 정리 완료")
    }
    
    // 탭 처리
    private func handleTap() {
        guard let character = character else { return }
        
        if character.status.phase == .egg {
            // 운석 단계 - EggController 토글
            eggController.toggleAnimation()
            print("운석 애니메이션 토글: \(eggController.isAnimating ? "재생" : "정지")")
        } else {
            // 다른 단계 - QuokkaController 토글
            if character.species == .quokka {
                quokkaController?.toggleAnimation()
                print("쿼카 애니메이션 토글: \(quokkaController?.isAnimating ?? false ? "재생" : "정지")")
            }
        }
    }
    
    // MARK: - 어떤 애니메이션을 보여줄지 결정하는 헬퍼 메서드
    // 운석 애니메이션을 보여줄지 결정하는 헬퍼 메서드
    private func shouldShowEggAnimation(evolutionStatus: EvolutionStatus) -> Bool {
        switch evolutionStatus {
        case .eggComplete, .toInfant:
            return true  // 운석 애니메이션 계속 표시
        case .completeInfant, .toChild, .completeChild, .toAdolescent, .completeAdolescent, .toAdult, .completeAdult, .toElder, .completeElder:
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
        quokkaController: nil,
        onCreateCharacterTapped: {
            print("프리뷰에서 캐릭터 생성 버튼이 눌렸습니다!")
        }
    )
    .padding()
}



