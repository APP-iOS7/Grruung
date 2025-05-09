//
//  CharacterDetailView.swift
//  Grruung
//
//  Created by NO SEONGGYEONG on 5/1/25.
//

import SwiftUI

// List의 높이를 콘텐츠에 맞게 조절하는 ViewModifier
struct ShrinkListHeightModifier: ViewModifier {
    let itemCount: Int
    let estimatedRowHeight: CGFloat
    
    private var totalHeight: CGFloat {
        if itemCount == 0 {
            return 0 // 아이템이 없으면 높이는 0
        }
        // 전체 높이 = 아이템 개수 * 각 행의 예상 높이
        // PlainListStyle의 경우, 구분선은 매우 얇거나 행 높이 내에 포함될 수 있습니다.
        // 정확한 계산을 위해서는 (itemCount - 1) * separatorHeight를 더할 수 있지만,
        // 보통은 itemCount * estimatedRowHeight로 충분합니다.
        return CGFloat(itemCount) * estimatedRowHeight
    }
    
    func body(content: Content) -> some View {
        content.frame(height: totalHeight)
    }
}

extension View {
    /// List의 높이를 콘텐츠 크기에 맞추어 동적으로 조절합니다.
    /// List가 다른 ScrollView 내부에 있을 때 이중 스크롤 문제를 방지하는 데 도움이 됩니다.
    ///
    /// - Parameters:
    ///   - itemCount: 리스트에 표시될 아이템의 총 개수입니다.
    ///   - estimatedRowHeight: 각 행의 예상 높이입니다. 행 내부의 패딩을 포함해야 합니다.
    func shrinkToFitListContent(itemCount: Int, estimatedRowHeight: CGFloat) -> some View {
        self.modifier(ShrinkListHeightModifier(itemCount: itemCount, estimatedRowHeight: estimatedRowHeight))
    }
}

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
        ("새로운 놀이", "2025.02.25", "gamecontroller.fill"),
        ("첫 번째 만남", "2025.02.01", "photo.fill"),
        ("장난감을 받은 날", "2025.02.10", "gift.fill"),
        ("첫 산책", "2025.02.15", "figure.walk"),
        ("친구를 만난 날", "2025.02.20", "person.2.fill"),
        ("새로운 놀이", "2025.02.25", "gamecontroller.fill"),
    ]
    // ------- 더미 데이터 끝 -------
    
    // 각 List 행의 예상 높이를 계산합니다.
    // Image: frame(height: 60) + padding(10) 상하 = 80pt
    // HStack (row content): padding(.vertical, 4) 상하 = 8pt
    // NavigationLink 내부 컨텐츠의 총 높이 = 80pt (이미지) + 8pt (HStack 패딩) = 88pt
    // listRowInsets(EdgeInsets())를 사용하므로 추가적인 기본 행 패딩은 없습니다.
    let estimatedRowHeight: CGFloat = 88.0
    
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
                .padding(.horizontal)
                .padding(.bottom, 20)
                
                // 성장 과정 영역
                VStack {
                    Text("성장 과정 🐾")
                        .frame(maxWidth: .infinity, alignment: .leading)
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
                .padding(.horizontal)
                .padding(.bottom, 20)
                
                HStack {
                    Button("<") {
                        print("이전 기록 버튼 클릭됨")
                    }
                    Text("2025년 2월")
                    Button(">") {
                        print("다음 기록 버튼 클릭됨")
                    }
                }
                .padding(.bottom, 10)
                
                // 성장 기록 영역
                VStack {
                    Text("성장 기록 📔")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 10)
                    
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
                .padding(.horizontal)
                .padding(.bottom, 20)
                
                // 들려준 이야기 영역
                VStack {
                    Text("들려준 이야기 📖")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 10) // VStack 내부 Text에 대한 패딩이므로 List 높이 계산과 무관
                    
                    
                    List {
                        ForEach(storyItems.indices, id: \.self) { index in
                            NavigationLink(destination: Text("\(storyItems[index].title)")) {
                                HStack {
                                    Image(systemName: storyItems[index].image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 60, height: 60)
                                        .padding(10) // 이 패딩이 행 높이에 기여
                                    
                                    VStack(alignment: .leading) {
                                        Text(storyItems[index].date)
                                            .font(.headline)
                                        Text(storyItems[index].title)
                                            .font(.subheadline)
                                        
                                    }
                                }
                                Spacer()
                            }
                            .listRowInsets(EdgeInsets()) // 기본 행 패딩 제거
                            .padding(.vertical, 4) // HStack 자체의 수직 패딩, 행 높이에 기여
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    print("삭제 버튼 클릭됨 \(storyItems[index].title )")
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    print("수정 버튼 클릭됨 \(storyItems[index].title )")
                                } label: {
                                    Image(systemName: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                        .listRowBackground(Color.white)
                        
                    }
                    .listStyle(PlainListStyle())
                    // .frame(height: 200) // 이전 고정 높이 대신 아래 modifier 사용
                    .padding(.horizontal) // List 좌우 패딩, 높이 계산과 무관
                    // 여기에 새로운 modifier를 적용합니다.
                    .shrinkToFitListContent(itemCount: storyItems.count, estimatedRowHeight: estimatedRowHeight)
                }
            }
            .padding(.bottom, 30)
            Spacer()
        } // end of ScrollView
        .navigationTitle("\(nameDummy)").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        print("이름 바꿔주기 버튼 클릭 됨")
                    }) {
                        Text("이름 바꿔주기")
                    }
                    Button(action: {
                        print("동산으로 보내기 버튼 클릭 됨")
                    }) {
                        Text("동산으로 보내기")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}



#Preview {
    NavigationView { // 네비게이션 바 테스트를 위해 NavigationView 추가
        CharacterDetailView()
    }
}

