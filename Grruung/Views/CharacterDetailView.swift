//
//  CharacterDetailView.swift
//  Grruung
//
//  Created by NO SEONGGYEONG on 5/1/25.
//

import SwiftUI

struct CharacterDetailView: View {
    // 더미 데이터: 모델 구현 후 삭제 예정
    let nameDummy: String = "구르릉 사자"
    let meetDateDummy: String = "2025년 02월 14일"
    let addressDummy: String = "〇〇의 아이폰"
    let ageDummy: Int = 45
    let imageDummy: String = "cat.fill"
    
    // 성장 단계 더미 데이터
    let growthStages: [(stage: String, image: String)] = [
        ("애기", "lizard.fill"),
        ("유아기", "hare.fill"),
        ("소아기", "ant.fill"),
        ("청년기", "tortoise.fill"),
        ("성년기", "dog.fill"),
        ("노년기", "bird.fill")
    ]
    
    // 현재 성장 단계 (인덱스 기준) - 예시로 청년기(3)으로 설정
    let currentStageIndex: Int = 5
    
    // CharacterDetailView 구조체 내에 추가할 더미 데이터
    let storyItems: [(title: String, date: String, image: String)] = [
        ("첫 번째 만남", "2025.02.01", "photo.fill"),
        ("장난감을 받은 날", "2025.02.10", "gift.fill"),
        ("첫 산책", "2025.02.15", "figure.walk"),
        ("친구를 만난 날", "2025.02.20", "person.2.fill"),
        ("새로운 놀이", "2025.02.25", "gamecontroller.fill")
    ]
    // ------- 더미 데이터 끝 -------
    
    var body: some View {
        ScrollView {
        VStack {
            // 캐릭터 정보 영역
            HStack {
                Image(systemName: "\(imageDummy)")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .padding()
                VStack(alignment: .leading) {
                    Text("떨어진 날: \(meetDateDummy)")
                    Text("사는 곳: \(addressDummy)")
                    Text("생 후: \(ageDummy)일")
                }
                .padding(.trailing, 20)
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.bottom, 20)
            
            // 성장 과정 영역
            VStack {
                Text("성장 과정 🐾")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 10)
                    .padding(.top, 10)
                
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
                }
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.bottom, 20)
            
            // 성장 기록 영역
            VStack {
                Text("성장 기록 📔")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 10)
                    .padding(.top, 10)
                
                HStack {
                    Button("<") {
                        // TODO: 이전 기록 보기 (이전 데이터 없으면 비활성화)
                        print("이전 기록 버튼 클릭됨")
                    }
                    Text("2025년 2월")
                    Button(">") {
                        // TODO: 다음 기록 보기 구현 필요 (현재 해당 월과 동일하면 비활성화)
                        print("다음 기록 버튼 클릭됨")
                    }
                }.padding(.bottom, 10)
                
                HStack {
                    VStack {
                        Text("총 활동량")
                            .frame(alignment: .leading)
                            .padding(.leading, 40)
                        
                        Image(systemName: "pawprint.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .cornerRadius(10)
                            .frame(alignment: .leading)
                            .padding(.leading, 46)
                    }
                    
                    Divider()
                        .frame(height: 70)
                        .background(Color.gray)
                        .padding(.horizontal, 10)
                    
                    VStack(alignment: .leading) {
                        Text("놀이 : 10회")
                        Text("산책 : 5회")
                        Text("같이 걷기: 20.5 km")
                    }
                    .padding(.trailing, 20)
                    
                    Spacer()
                }
                .padding(.bottom, 30)
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.bottom, 20)
            
            // 들려준 이야기 영역
            VStack {
                Text("들려준 이야기 📖")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 10)
                    .padding(.top, 10)
                
       
                    LazyVStack {
                        ForEach(storyItems.indices, id: \.self) { index in
                            NavigationLink(destination: Text("\(storyItems[index].title)")) {
                                HStack {
                                    Image(systemName: storyItems[index].image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 60, height: 60)
                                        .padding(10)
                                    
                                    VStack(alignment: .leading) {
                                        Text(storyItems[index].date)
                                            .font(.headline)
                                        Text(storyItems[index].title)
                                            .font(.subheadline)
                                        
                                    }
                                }
                                Spacer()
                            }
                            .background(Color(.white))
                            .cornerRadius(8)
                            .padding(.horizontal)
                         
                        }
                    }
                    .padding(.bottom, 15)
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.bottom, 30)
            
            Spacer()
        } // end of VStack
        .navigationTitle("\(nameDummy)").navigationBarTitleDisplayMode(.inline)
    }
}
}

#Preview {
    NavigationStack {
        CharacterDetailView()
    }
}

