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
    let meetDateDummy: String = "2025년 02월 14일"
    let addressDummy: String = "〇〇의 아이폰"
    let ageDummy: Int = 45
    var characterUUID: String = "1234"
    
    // 성장 단계 더미 데이터
    let growthStages: [(stage: String, image: String)] = [
        ("애기", "lizard.fill"),
        ("유아기", "hare.fill"),
        ("소아기", "ant.fill"),
        ("청년기", "tortoise.fill"),
        ("성년기", "dog.fill"),
        ("노년기", "bird.fill")
    ]
    
    // 현재 성장 단계 (인덱스 기준)
    let currentStageIndex: Int = 5
    
    // 각 List 행의 예상 높이를 계산합니다.
    let estimatedRowHeight: CGFloat = 88.0
    
    @StateObject private var viewModel: CharacterDetailViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var searchDate: Date = Date()
    //var characterUUID: String
    
    // 초기화 메서드를 수정하여 characterUUID를 전달
    init(characterUUID: String) {
        self.characterUUID = characterUUID
        self._viewModel = StateObject(wrappedValue: CharacterDetailViewModel(characterUUID: characterUUID))
    }
    
    var body: some View {
        ScrollView {
            VStack {
                // 캐릭터 정보 영역
                HStack {
                    if !viewModel.character.imageName.isEmpty {
                        AsyncImage(url: URL(string: viewModel.character.imageName)) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                        } placeholder: {
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                        }
                        .padding()
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .padding()
                    }
                    
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
                        searchDate = searchDate.addingTimeInterval(-30 * 24 * 60 * 60)
                        viewModel.loadPost(characterUUID: characterUUID, searchDate: searchDate)
                        print("이전 기록 버튼 클릭됨")
                    }
                    Text("\(searchDateString(date: searchDate))")
                        
                    Button(">") {
                        searchDate = searchDate.addingTimeInterval(30 * 24 * 60 * 60)
                        viewModel.loadPost(characterUUID: characterUUID, searchDate: searchDate)
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
                
                // 들려준 이야기 영역 - Firebase 데이터 사용하도록 수정
                VStack {
                    Text("들려준 이야기 📖")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 10)
                    
                    if viewModel.posts.isEmpty {
                        Text("이번 달에 기록된 이야기가 없습니다.")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        List {
                            ForEach(viewModel.posts.indices, id: \.self) { index in
                                NavigationLink(destination: Text("\(viewModel.posts[index].postBody)")) {
                                    HStack {
                                        if !viewModel.posts[index].postImage.isEmpty {
                                            AsyncImage(url: URL(string: viewModel.posts[index].postImage)) { image in
                                                image
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 60, height: 60)
                                                    .padding(10)
                                            } placeholder: {
                                                Image(systemName: "photo")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 60, height: 60)
                                                    .padding(10)
                                            }
                                        } else {
                                            Image(systemName: "photo")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 60, height: 60)
                                                .padding(10)
                                        }
                                        
                                        VStack(alignment: .leading) {
                                            Text(formatDate(viewModel.posts[index].createdAt))
                                                .font(.headline)
                                            Text(viewModel.posts[index].postBody)
                                                .font(.subheadline)
                                                .lineLimit(2)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                .listRowInsets(EdgeInsets())
                                .padding(.vertical, 4)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        print("삭제 버튼 클릭됨 \(viewModel.posts[index].postBody)")
                                        viewModel.deletePost(postID: viewModel.posts[index].postID)
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    Button {
                                        print("수정 버튼 클릭됨 \(viewModel.posts[index].postBody)")
                                    } label: {
                                        Image(systemName: "pencil")
                                    }
                                    .tint(.blue)
                                }
                            }
                            .listRowBackground(Color.white)
                        }
                        .listStyle(PlainListStyle())
                        .padding(.horizontal)
                        .shrinkToFitListContent(itemCount: viewModel.posts.count, estimatedRowHeight: estimatedRowHeight)
                    }
                }
            }
            .padding(.bottom, 30)
            
            Spacer()
            
        } // end of ScrollView
        
        .navigationTitle("\(viewModel.character.name.isEmpty ? "캐릭터" : viewModel.character.name)")
        .navigationBarTitleDisplayMode(.inline)
        
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
    
    func searchDateString(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월"
        return formatter.string(from: date)
    }
    
    // 포스트 날짜 포맷팅을 위한 새로운 함수
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
}



#Preview {
    NavigationView { // 네비게이션 바 테스트를 위해 NavigationView 추가
        CharacterDetailView(characterUUID: "CF6NXxcH5HgGjzVE0nVE")
    }
}
