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
    
    var body: some View {
        ZStack {
            // 캐릭터 애니메이션 영역
            characterAnimationView
        }
        .frame(height: 200)
        .cornerRadius(10) // 모서리 둥글게
    }
    
    // 캐릭터 애니메이션을 처리하는 부분
    @ViewBuilder
    private var characterAnimationView: some View {
        // 일단 기본 이미지로 표시 (다음 단계에서 애니메이션 추가)
        Image(character?.imageName ?? "CatLion")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 150) // 배경보다 작게
            .scaleEffect(isSleeping ? 0.95 : 1.0)
            .animation(
                isSleeping ?
                Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true) :
                        .default,
                value: isSleeping
            )
        
        // 캐릭터가 자고 있을 때 "Z" 이모티콘 표시
        if isSleeping {
            VStack {
                Text("💤")
                    .font(.largeTitle)
                    .offset(x: 50, y: -50)
            }
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
