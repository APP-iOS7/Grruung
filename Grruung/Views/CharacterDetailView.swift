//
//  CharacterDetailView.swift
//  Grruung
//
//  Created by NO SEONGGYEONG on 5/1/25.
//

import SwiftUI


struct CharacterDetailView: View {
    @StateObject private var viewModel: CharacterDetailViewModel
    
    @Environment(\.dismiss) var dismiss
    
    @State private var searchDate: Date = Date()
    @State private var selectedPostForEdit: PostIdentifier? // (characterUUID, postID)
    @State private var isShowingNameChangeAlert = false // 이름 변경 시 사용하는 플래그
    @State private var newName: String = "" // 이름 변경 시 사용할 새로운 이름
    
    // 캐릭터 이동 버튼 클릭 시 사용
    @State private var goToHome = false // 홈으로 보내기 버튼 클릭 시 사용
    @State private var goToParadise = false // 동산으로 보내기 버튼 클릭 시 사용
    @State private var goToSpace = false // 우주로 보내기 버튼 클릭 시 사용
    @State private var isShowingSpaceConfirmation = false
    
    private let estimatedRowHeight: CGFloat = 88.0 // 각 List 행의 예상 높이를 계산합니다. (리스트 크기 조정 시 필요)
    private let deviceModel: String = UIDevice.modelName() // 현재 기기 모델을 가져옵니다.
    
    private var characterAddress: Address {
        if let address = Address(rawValue: viewModel.characterStatus.address) {
            return address
        }
        return .userHome // 기본값
    }
    
    // 외부에서 전달받은 characterUUID
    var characterUUID: String
    
    private var currentStageIndex: Int {
        let phaseString = viewModel.characterStatus.phase.rawValue
        switch phaseString {
        case "운석": return 0
        case "유아기": return 1
        case "소아기": return 2
        case "청년기": return 3
        case "성년기": return 4
        case "노년기": return 5
        default: return 0
        }
    }
    // 초기화 메서드를 수정하여 characterUUID를 전달
    init(characterUUID: String) {
        self.characterUUID = characterUUID
        self._viewModel = StateObject(wrappedValue: CharacterDetailViewModel(characterUUID: characterUUID))
    }
    
    var body: some View {
        ScrollView {
            VStack {
                // 캐릭터 정보 영역
                characterInfoSection
                // 성장 과정 영역
                growthProgressSection
                // 날짜 탐색 버튼
                dateNavigationSection
                // 활동 기록 영역
                activitySection
                // 들려준 이야기 영역
                storyListSection
            }
            Spacer()
        } // end of ScrollView
        .onAppear {
            print("CharacterDetailView appeared. Refreshing data for character: \(characterUUID) and date: \(searchDateString(date: searchDate))")
            viewModel.loadPost(characterUUID: self.characterUUID, searchDate: self.searchDate)
        }
        .navigationDestination(item: $selectedPostForEdit) { post in
            WriteStoryView(
                currentMode: .edit,
                characterUUID: post.characterUUID,
                postID: post.postID
            )
        }
        .navigationTitle("\(viewModel.character.name.isEmpty ? "캐릭터" : viewModel.character.name)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        newName = viewModel.character.name
                        isShowingNameChangeAlert = true
                    }) {
                        Text("이름 바꿔주기")
                    }
                    
                    // 위치 이동 버튼들을 동적으로 생성
                    ForEach(getAddressMenuItems(), id: \.id) { item in
                        if item.title == "우주로 보내기" {
                            Button(role: .destructive, action: item.action) {
                                Text(item.title)
                            }
                        } else {
                            Button(action: item.action) {
                                Text(item.title)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("이름 바꾸기", isPresented: $isShowingNameChangeAlert) {
            TextField("새로운 이름", text: $newName)
                .autocorrectionDisabled()
            
            Button("취소", role: .cancel) {
                newName = ""
            }
            
            Button("변경") {
                if !newName.isEmpty {
                    viewModel.updateCharacterName(characterUUID: characterUUID, newName: newName)
                }
            }
        } message: {
            Text("\(viewModel.character.name)의 새로운 이름을 입력해주세요.")
        }
        .alert("캐릭터를 우주로 보내시겠습니까?", isPresented: $isShowingSpaceConfirmation) {
            Button("취소", role: .cancel) { }
            
            Button("보내기", role: .destructive) {
                // 캐릭터 상태를 '접근 불가'로 변경
                viewModel.updateAddress(characterUUID: characterUUID, newAddress: .space)
                // 목록 화면으로 돌아가기
                dismiss()
            }
        } message: {
            Text("캐릭터를 우주로 보내면 더 이상 접근할 수 없습니다.")
        }
    }
    
    // MARK: - 캐릭터 정보 영역
    private var characterInfoSection: some View {
        HStack {
            if !viewModel.character.imageName.isEmpty {
                AsyncImage(url: URL(string: viewModel.character.imageName)) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .padding()
                } placeholder: {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .padding()
                }
                .padding()
            }
            
            VStack(alignment: .leading) {
                Text("떨어진 날: \(formatDate(viewModel.character.createdAt))")
                    .font(.subheadline)
                Text("태어난 날: \(formatDate(viewModel.character.birthDate))")
                    .font(.subheadline)
                Text("종: \(viewModel.character.species.rawValue)")
                    .font(.subheadline)
                Text("현재 성장 상태: \(viewModel.characterStatus.phase.rawValue) + \(currentStageIndex)")
                    .font(.subheadline)
                if viewModel.characterStatus.address == Address.userHome.rawValue {
                    Text("사는 곳: \(viewModel.user.userName)의 \(deviceModel)")
                        .font(.subheadline)
                } else {
                    Text("사는 곳: \(getAddressDisplayName(characterAddress))")
                        .font(.subheadline)
                }
                Text("생 후: + \(Calendar.current.dateComponents([.day], from: viewModel.character.birthDate, to: Date()).day ?? -404)일")
                    .font(.subheadline)
            }
            .padding(.trailing, 20)
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
    
    // MARK: - 성장 과정 영역
    private var growthProgressSection: some View {
        VStack {
            Text("성장 과정 🐾")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 10)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(0...currentStageIndex, id: \.self) { index in
                        VStack {
                            if index < viewModel.growthStages.count, let url = viewModel.growthStages[index].imageURL {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 60, height: 60)
                                } placeholder: {
                                    Image(systemName: "photo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 60, height: 60)
                                }
                            } else {
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                            }
                        }
                        .padding()
                        if index != currentStageIndex  {
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
    }
    
    // MARK: - 날짜 탐색 버튼
    private var dateNavigationSection: some View {
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
    }
    
    // MARK: - 활동 기록 영역
    private var activitySection: some View {
        VStack {
            Text("함께 했던 순간 🐾")
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
                    Text("활동량 : \(viewModel.characterStatus.activity)")
                    
                }
                .padding(.trailing, 20)
                Spacer()
            }
            .padding(.bottom, 30)
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
    
    // MARK: - 들려준 이야기 영역
    private var storyListSection: some View {
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
                        NavigationLink(destination: WriteStoryView(currentMode: .read, characterUUID: characterUUID, postID: viewModel.posts[index].postID)) {
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
                                }
                                VStack(alignment: .leading) {
                                    Text(viewModel.posts[index].postTitle)
                                        .font(.headline)
                                        .lineLimit(1)
                                    Text(formatDate(viewModel.posts[index].createdAt))
                                        .font(.subheadline)
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
                                
                                selectedPostForEdit = PostIdentifier(
                                    characterUUID: characterUUID,
                                    postID: viewModel.posts[index].postID
                                )
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
                .shrinkToFitListContent(
                    itemCount: viewModel.posts.count,
                    estimatedRowHeight: estimatedRowHeight
                )
            }
        }
        .padding(.bottom, 30)
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
    
    func getAvailableDestinations(from currentLocation: Address) -> [Address] {
        switch currentLocation {
        case .userHome:
            return [.paradise, .space]
        case .paradise:
            return [.userHome, .space]
        case .space:
            return [.userHome, .paradise]
        }
    }
    
    func getAddressMenuItems() -> [MenuItem] {
        guard let currentAddress = Address(rawValue: viewModel.characterStatus.address) else {
            return []
        }
        
        let destinations = getAvailableDestinations(from: currentAddress)
        
        return destinations.map { destination in
            let titleText: String
            switch destination {
            case .userHome:
                titleText = "기기로 불러오기"
            case .paradise:
                titleText = "동산으로 보내기"
            case .space:
                titleText =  "우주로 보내기"
            }
            
            return MenuItem(
                title: titleText,
                action: {
                    if destination == .space {
                        isShowingSpaceConfirmation = true
                    } else {
                        viewModel.updateAddress(characterUUID: characterUUID, newAddress: destination)
                    }
                },
            )
        }
    }
    
    func getAddressDisplayName(_ address: Address) -> String {
        switch address {
        case .userHome:
            return "메인"
        case .paradise:
            return "동산"
        case .space:
            return "우주"
        }
    }
    
} // end of CharacterDetailView

// 포스트 식별자 구조체
struct PostIdentifier: Hashable, Identifiable {
    let characterUUID: String
    let postID: String
    var id: String { "\(characterUUID)-\(postID)" }
    
}

struct MenuItem: Identifiable {
    let id = UUID()
    let title: String
    let action: () -> Void
}

// 리스트 의 높이를 콘텐츠 크기에 맞추어 조절하는 View Extension
extension View {
    /// List의 높이를 콘텐츠 크기에 맞추어 동적으로 조절합니다.
    /// List가 다른 ScrollView 내부에 있을 때 이중 스크롤 문제를 방지하는 데 도움이 됩니다.
    /// - Parameters:
    ///   - itemCount: 리스트에 표시될 아이템의 총 개수입니다.
    ///   - estimatedRowHeight: 각 행의 예상 높이입니다. 행 내부의 패딩을 포함해야 합니다.
    func shrinkToFitListContent(itemCount: Int, estimatedRowHeight: CGFloat) -> some View {
        self.modifier(ShrinkListHeightModifier(itemCount: itemCount, estimatedRowHeight: estimatedRowHeight))
    }
}

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

// MARK: NavigationView 사용 시 수정 뷰로 이동 안되므로 꼭 상위 뷰에서 NavigationStack을 사용해야 함
#Preview {
    NavigationStack {
        CharacterDetailView(characterUUID: "CF6NXxcH5HgGjzVE0nVE")
    }
}
