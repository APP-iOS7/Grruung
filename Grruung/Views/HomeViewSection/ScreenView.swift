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
    @StateObject private var eggControl = EggControl()
    
    var body: some View {
        ZStack {
            Color.clear
            
            // 캐릭터 애니메이션 영역
            // 캐릭터 상태에 따라 다른 애니메이션 표시
            if let character = character {
                if character.status.phase == .egg {
                    // 운석 단계일 때 - EggControl 사용
                    eggAnimationView
                } else {
                    // 다른 단계일 때 - 기존 방식 (나중에 다른 Control로 교체 예정)
                    regularCharacterView
                }
            } else {
                // 캐릭터가 없을 때 기본 이미지
                defaultView
            }
            
            // 캐릭터가 자고 있을 때 "Z" 이모티콘 표시
            if isSleeping {
                sleepingIndicator
            }
        }
        .frame(height: 200)
        .onAppear {
            // 뷰가 나타날 때 애니메이션 시작
            startAppropriateAnimation()
        }
        .onDisappear {
            // 뷰가 사라질 때 애니메이션 정리
            eggControl.cleanup()
        }
        .onTapGesture {
            handleTap()
        }
    }
    
    // MARK: - 상태별 뷰
    
    // 운석 애니메이션 뷰
     @ViewBuilder
     private var eggAnimationView: some View {
         if let currentFrame = eggControl.currentFrame {
             Image(uiImage: currentFrame)
                 .resizable()
                 .aspectRatio(contentMode: .fit)
                 .frame(height: 180) // 배경보다 작게
         } else {
             // EggControl이 로드되지 않았을 때 기본 이미지
             Image("egg_normal_1")
                 .resizable()
                 .aspectRatio(contentMode: .fit)
                 .frame(height: 180)
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
                .scaleEffect(isSleeping ? 0.95 : 1.0)
                .animation(
                    isSleeping ?
                    Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true) :
                            .default,
                    value: isSleeping
                )
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
//        Image(character?.imageName ?? "CatLion")
//            .resizable()
//            .aspectRatio(contentMode: .fit)
//            .frame(height: 150) // 배경보다 작게
//            .scaleEffect(isSleeping ? 0.95 : 1.0)
//            .animation(
//                isSleeping ?
//                Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true) :
//                        .default,
//                value: isSleeping
//            )
    }
    
    // 🎯 잠자는 표시
    @ViewBuilder
    private var sleepingIndicator: some View {
        VStack {
            Text("💤")
                .font(.largeTitle)
                .offset(x: 50, y: -50)
        }
    }
    
    // MARK: - 헬퍼 메서드
    
    // 적절한 애니메이션 시작
    private func startAppropriateAnimation() {
        if character?.status.phase == .egg || character == nil {
            eggControl.startAnimation()
            print("운석 애니메이션 시작")
        }
    }
    
    // 탭 처리
    private func handleTap() {
        if character?.status.phase == .egg || character == nil {
            eggControl.toggleAnimation()
            print("운석 애니메이션 토글: \(eggControl.isAnimating ? "재생" : "정지")")
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
        isSleeping: false
    )
    .padding()
}
