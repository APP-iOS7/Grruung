//
//  CharacterDetailView.swift
//  Grruung
//
//  Created by NO SEONGGYEONG on 5/1/25.
//

import SwiftUI

struct CharacterDetailView: View {
    // 더미 데이터
    let nameDummy: String = "구르릉 사자"
    let meetDateDummy: String = "2025년 02월 14일"
    let addressDummy: String = "〇〇의 아이폰"
    let ageDummy: Int = 45
    let imageDummy: String = "cat.fill"
    
    // 성장 단계 더미 데이터
    let growthStages: [(stage: String, image: String)] = [
        ("애기", "pawprint.fill"),
        ("유아기", "hare.fill"),
        ("소아기", "tortoise.fill"),
        ("청년기", "cat.fill"),
        ("성년기", "cat.fill"),
        ("노년기", "cat.fill")
    ]
    
    // 현재 성장 단계 (인덱스 기준) - 예시로 청년기(3)으로 설정
    let currentStageIndex: Int = 3
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "\(imageDummy)")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 130, height: 130)
                    .cornerRadius(10)
                    .padding(.trailing, 10)
                VStack(alignment: .leading) {
                    Text("떨어진 날: \(meetDateDummy)")
                    Text("사는 곳: \(addressDummy)")
                    Text("생 후: \(ageDummy)일")
                }
            }
            .padding(.bottom, 30)
            
            Text("성장 과정 🐾")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(0..<currentStageIndex, id: \.self) { index in
                        VStack {
                            Image(systemName: growthStages[index].image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                        }
                        .padding()
                        if index != currentStageIndex - 1 {
                            HStack {
                                Text("→")
                            }
                        }
                    }
                }
                .frame(width: currentStageIndex <= 3 ? UIScreen.main.bounds.width : nil)
            }
            .padding(.bottom, 20)
            
            Text("성장 기록 📔")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 30)
                .padding(.bottom, 10)
            
            Text("< \(meetDateDummy)>")
            
            
        } // end of VStack
        .navigationTitle("\(nameDummy)").navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        CharacterDetailView()
    }
}
