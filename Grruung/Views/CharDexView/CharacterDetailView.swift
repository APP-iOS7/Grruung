//
//  CharacterDetailView.swift
//  Grruung
//
//  Created by NO SEONGGYEONG on 5/1/25.
//

import SwiftUI
import FirebaseFirestore

struct CharacterDetailView: View {
    // MARK: - Properties
    @StateObject private var viewModel: CharacterDetailViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var authService: AuthService
    
    // MARK: - State Variables
    @State private var searchDate: Date = Date()
    @State private var selectedPostForEdit: PostIdentifier?
    @State private var isShowingNameChangeAlert = false
    @State private var newName: String = ""
    
    // MARK: - Character Actions State
    @State private var isShowingSpaceConfirmation = false
    @State private var isShowingSetMainAlert = false
    @State private var isShowingParadiseConfirmation = false
    @State private var isProcessing = false
    
    // MARK: - Constants
    private let estimatedRowHeight: CGFloat = 88.0
    private let deviceModel: String = UIDevice.current.model
    
    // MARK: - Computed Properties
    
    // 현재 캐릭터의 주소
    private var characterAddress: String {
        viewModel.character.status.address
    }
    
    // 현재 성장 단계 인덱스
    private var currentStageIndex: Int {
        let phaseString = viewModel.character.status.phase.rawValue
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
    
    // MARK: - Initialization
    
    var characterUUID: String
    
    init(characterUUID: String) {
        self.characterUUID = characterUUID
        self._viewModel = StateObject(wrappedValue: CharacterDetailViewModel(characterUUID: characterUUID))
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: UIConstants.verticalPadding) {
                // 캐릭터 정보 영역
                characterInfoSection
                
                VStack(spacing: 20) {
                    // 성장 과정 영역
                    growthProgressSection
                }
                .background(
                    RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                        .fill(GRColor.mainColor2_1)
                )
                .padding(.horizontal ,UIConstants.horizontalPadding)
                
                VStack(spacing: 20) {
                    // 날짜 탐색 버튼
                    dateNavigationSection
                    
                    // 활동 기록 영역
                    activitySection
                    
                    // 들려준 이야기 영역
                    storyListSection
                }
                .padding(.vertical, UIConstants.verticalPadding)
                .background(
                    RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                        .fill(GRColor.mainColor2_1)
                )
                .padding(.horizontal ,UIConstants.horizontalPadding)
            }
        }
        .padding(.bottom, 55)
        .scrollContentBackground(.hidden)
        .background(
            LinearGradient(colors: [
                Color(GRColor.mainColor1_1),
                Color(GRColor.mainColor1_2)
            ],
                           startPoint: .top, endPoint: .bottom)
        )
        .navigationTitle(viewModel.character.name.isEmpty ? "캐릭터" : viewModel.character.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                characterActionsMenu
            }
        }
        .onAppear {
            print("📱 CharacterDetailView 표시됨 - 캐릭터: \(characterUUID)")
            print("✅✅✅✅✅ CharacterDetailView - 캐릭터 주소 로드 성공: \(viewModel.character.status.address)")
            viewModel.loadPost(characterUUID: characterUUID, searchDate: searchDate)
        }
        .navigationDestination(item: $selectedPostForEdit) { post in
            WriteStoryView(
                currentMode: .edit,
                characterUUID: post.characterUUID,
                postID: post.postID
            )
        }
        // MARK: - Alerts
        .alert("이름 바꾸기", isPresented: $isShowingNameChangeAlert) {
            TextField("새로운 이름", text: $newName)
                .autocorrectionDisabled()
            
            Button("취소", role: .cancel) {
                newName = ""
            }
            
            Button("변경") {
                if !newName.isEmpty && newName != viewModel.character.name {
                    viewModel.updateCharacterName(characterUUID: characterUUID, newName: newName)
                }
                newName = ""
            }
            .disabled(newName.isEmpty || newName == viewModel.character.name)
        } message: {
            Text("\(viewModel.character.name)의 새로운 이름을 입력해주세요.")
        }
        .alert("메인 캐릭터로 설정하시겠습니까?", isPresented: $isShowingSetMainAlert) {
            Button("취소", role: .cancel) { }
            
            Button("설정") {
                setAsMainCharacter()
            }
        } message: {
            Text("이 캐릭터를 메인 캐릭터로 설정하고 홈 화면에 표시합니다.")
        }
        .alert("캐릭터를 동산으로 보내시겠습니까?", isPresented: $isShowingParadiseConfirmation) {
            Button("취소", role: .cancel) { }
            
            Button("보내기") {
                moveCharacterToParadise()
            }
        } message: {
            Text("이 캐릭터를 동산으로 보냅니다. 홈 화면에서는 사라집니다.")
        }
        .alert("캐릭터를 우주로 보내시겠습니까?", isPresented: $isShowingSpaceConfirmation) {
            Button("취소", role: .cancel) { }
            
            Button("보내기", role: .destructive) {
                deleteCharacter()
            }
        } message: {
            Text("캐릭터를 우주로 보내면 더 이상 접근할 수 없습니다.")
        }
        .overlay {
            if viewModel.isLoading || isProcessing {
                LoadingOverlay()
            }
        }
    }
    
    // MARK: - UI Components
    
    // 캐릭터 메뉴 버튼
    private var characterActionsMenu: some View {
        Menu {
            // 이름 변경
            Button(action: {
                newName = viewModel.character.name
                isShowingNameChangeAlert = true
            }) {
                Label("이름 바꿔주기", systemImage: "pencil")
            }
            
            Divider()
            
            // 주소에 따른 작업 버튼들
            ForEach(getAddressMenuItems(), id: \.id) { item in
                if item.title == "우주로 보내기" {
                    Button(role: .destructive, action: item.action) {
                        Label(item.title, systemImage: "trash")
                    }
                } else {
                    Button(action: item.action) {
                        Label(item.title, systemImage: getSystemImageForAction(item.title))
                    }
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title2)
        }
    }
    
    // MARK: - Character Info Section
    
    private var characterInfoSection: some View {
        HStack(alignment: .top, spacing: UIConstants.horizontalPadding) {
            // 캐릭터 이미지
            CharacterImageView(character: viewModel.character)
                .frame(width: UIConstants.imageViewHeight, height: UIConstants.imageViewHeight)
            
            // 캐릭터 정보
            VStack(alignment: .leading, spacing: UIConstants.verticalPadding / 2) {
                InfoRow(title: "떨어진 날", value: formatDate(viewModel.character.createdAt))
                InfoRow(title: "태어난 날", value: formatDate(viewModel.character.birthDate))
                InfoRow(title: "종", value: viewModel.character.species.rawValue)
                InfoRow(title: "사는 곳", value: getDisplayAddress())
                InfoRow(title: "생 후", value: "\(getDaysOld())일")
                InfoRow(title: "현재 단계", value: viewModel.character.status.phase.rawValue)
            }
            
            Spacer()
        }
        .padding(.horizontal, UIConstants.horizontalPadding)
        .padding(.vertical, UIConstants.verticalPadding / 1.6)
        .background(
            RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                .fill(Color.background)
        )
        .padding(.horizontal, UIConstants.horizontalPadding)
    }
    
    // MARK: - Growth Progress Section
    
    private var growthProgressSection: some View {
        VStack(alignment: .leading, spacing: UIConstants.verticalPadding / 4) {
            HStack {
                Image(systemName: "pawprint.fill")
                    .foregroundColor(GRColor.pointColor)
                Text("성장 과정")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: UIConstants.horizontalPadding / 4) {
                    ForEach(0...currentStageIndex, id: \.self) { index in
                        VStack {
                            // 성장 단계 이미지
                            let imageName = getGrowthStageImageName(for: index)
                            
                            Image(imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100 , height: 100)
                            
                            // 단계 이름
                            Text(getPhaseNameFor(index: index))
                                .font(.caption)
                                .fontWeight(index == currentStageIndex ? .semibold : .regular)
                                .foregroundColor(index == currentStageIndex ? GRColor.pointColor : .textSecondary)
                        }
                        
                        // 화살표 (마지막이 아닌 경우)
                        if index != currentStageIndex {
                            Image(systemName: "arrow.right")
                                .foregroundColor(GRColor.gray400)
                                .font(.caption)
                        }
                    }
                    Spacer(minLength: 8)
                }
            }
        }
        .padding(.vertical, UIConstants.verticalPadding)
        .background(
            RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                .fill(Color.background)
        )
        .padding(.horizontal, UIConstants.horizontalPadding)
    }
    
    // MARK: - Date Navigation Section
    
    private var dateNavigationSection: some View {
        HStack {
            Button(action: {
                searchDate = Calendar.current.date(byAdding: .month, value: -1, to: searchDate) ?? searchDate
                viewModel.loadPost(characterUUID: characterUUID, searchDate: searchDate)
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(GRColor.pointColor)
            }
            
            Spacer()
            
            Text(searchDateString(date: searchDate))
                .font(.headline)
                .fontWeight(.medium)
            
            Spacer()
            
            Button(action: {
                searchDate = Calendar.current.date(byAdding: .month, value: 1, to: searchDate) ?? searchDate
                viewModel.loadPost(characterUUID: characterUUID, searchDate: searchDate)
            }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(GRColor.pointColor)
            }
        }
        .padding(.horizontal, UIConstants.horizontalPadding)
        .padding(.vertical, UIConstants.verticalPadding / 1.6)
    }
    
    // MARK: - Activity Section
    
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: UIConstants.verticalPadding) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(GRColor.grColorRed)
                Text("함께 했던 순간")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack(spacing: UIConstants.horizontalPadding) {
                // 활동 아이콘
                VStack {
                    Image(systemName: "pawprint.circle.fill")
                        .font(.system(size: UIIconSize.large))
                        .foregroundColor(GRColor.grColorOrange)
                    
                    Text("총 활동량")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                
                Divider()
                    .frame(height: 60)
                
                // 스탯 정보
                VStack(alignment: .leading, spacing: 5) {
                    StatRow(title: "활동량", value: viewModel.character.status.activity, color: .orange)
                    StatRow(title: "포만감", value: viewModel.character.status.satiety, color: .green)
                    StatRow(title: "체력", value: viewModel.character.status.stamina, color: .blue)
                    StatRow(title: "레벨", value: viewModel.character.status.level, maxValue: 99, color: .purple)
                }
                
                Spacer()
            }
        }
        .padding(UIConstants.horizontalPadding)
        .background(
            RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                .fill(Color.background)
        )
        .padding(.horizontal, UIConstants.horizontalPadding)
    }
    
    // MARK: - Story List Section
    
    private var storyListSection: some View {
        VStack(alignment: .leading, spacing: UIConstants.verticalPadding) {
            HStack {
                Image(systemName: "book.fill")
                    .foregroundColor(GRColor.grColorBrown)
                Text("들려준 이야기")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                
                if !viewModel.posts.isEmpty {
                    Text("\(viewModel.posts.count)개")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(.horizontal, UIConstants.horizontalPadding)
            
            if viewModel.posts.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "book.closed")
                        .font(.system(size: UIIconSize.large))
                        .foregroundColor(GRColor.gray400)
                    
                    Text("이번 달에 기록된 이야기가 없습니다")
                        .foregroundColor(GRColor.gray500)
                        .font(.subheadline)
                }
                .frame(height: 100)
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.posts.indices, id: \.self) { index in
                        StoryRowView(
                            post: viewModel.posts[index],
                            onEdit: {
                                selectedPostForEdit = PostIdentifier(
                                    characterUUID: characterUUID,
                                    postID: viewModel.posts[index].postID
                                )
                            },
                            onDelete: {
                                viewModel.deletePost(postID: viewModel.posts[index].postID)
                            },
                            formatDate: formatDate
                        )
                        
                        if index < viewModel.posts.count - 1 {
                            Divider()
                                .padding(.leading, 80)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Methods
    
    // 표시용 주소 문자열 반환
    private func getDisplayAddress() -> String {
        if characterAddress == "userHome" {
            return "\(viewModel.user.userName)의 \(deviceModel)"
        } else if characterAddress == "paradise" {
            return "동산"
        } else {
            return characterAddress
        }
    }
    
    // 태어난 후 경과 일수 계산
    private func getDaysOld() -> Int {
        Calendar.current.dateComponents([.day], from: viewModel.character.birthDate, to: Date()).day ?? 0
    }
    
    // 성장 단계 이미지 URL 반환
    // 성장 단계 이미지 이름 반환 (Assets에서)
    private func getGrowthStageImageName(for index: Int) -> String {
        let characterStillImages: [String] = [
            "egg",
            "quokka_infant_still",
            "quokka_child_still",
            "quokka_adolescent_still",
            "quokka_adult_still",
            "quokka"
        ]
        
        guard index < characterStillImages.count else {
            return "egg" // 기본값
        }
        
        return characterStillImages[index]
    }
    
    // 단계 인덱스에 따른 이름 반환
    private func getPhaseNameFor(index: Int) -> String {
        switch index {
        case 0: return "운석"
        case 1: return "유아기"
        case 2: return "소아기"
        case 3: return "청년기"
        case 4: return "성년기"
        case 5: return "노년기"
        default: return "운석"
        }
    }
    
    // 날짜를 월 형식으로 포맷
    private func searchDateString(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월"
        return formatter.string(from: date)
    }
    
    // 날짜를 기본 형식으로 포맷
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
    
    // 액션에 따른 시스템 이미지 반환
    private func getSystemImageForAction(_ title: String) -> String {
        switch title {
        case "메인으로 설정": return "house"
        case "동산으로 보내기": return "mountain.2"
        case "우주로 보내기": return "trash"
        default: return "questionmark"
        }
    }
    
    // 주소 메뉴 아이템 생성
    private func getAddressMenuItems() -> [MenuItem] {
        var items: [MenuItem] = []
        
        // 현재 위치에 따라 다른 메뉴 항목 표시
        switch characterAddress {
        case "userHome":
            // 메인에 있는 경우 -> 동산으로 보내기, 우주로 보내기
            items.append(MenuItem(
                title: "동산으로 보내기",
                action: { isShowingParadiseConfirmation = true }
            ))
            items.append(MenuItem(
                title: "우주로 보내기",
                action: { isShowingSpaceConfirmation = true }
            ))
        case "paradise":
            // 동산에 있는 경우 -> 메인으로 설정, 우주로 보내기
            items.append(MenuItem(
                title: "메인으로 설정",
                action: { isShowingSetMainAlert = true }
            ))
            items.append(MenuItem(
                title: "우주로 보내기",
                action: { isShowingSpaceConfirmation = true }
            ))
        default:
            // 다른 위치에 있는 경우 (필요하다면 추가)
            items.append(MenuItem(
                title: "메인으로 설정",
                action: { isShowingSetMainAlert = true }
            ))
        }
        
        return items
    }
    
    // MARK: - Character Action Methods
    
    /// 캐릭터를 메인으로 설정
    private func setAsMainCharacter() {
        isProcessing = true
        
        // 1단계: 먼저 메인 캐릭터로 설정
        viewModel.setAsMainCharacter(characterUUID: characterUUID)
        
        // 2단계: 주소 변경은 메인 설정 완료 후 실행
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            viewModel.updateAddress(characterUUID: characterUUID, newAddress: .userHome)
        }
        
        // 3단계: UI 업데이트를 위한 알림 발송
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            NotificationCenter.default.post(
                name: NSNotification.Name("CharacterSetAsMain"),
                object: nil,
                userInfo: ["characterUUID": characterUUID]
            )
            
            // 4단계: 뷰 닫기
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isProcessing = false
                dismiss()
            }
        }
    }
    
    /// 캐릭터를 동산으로 이동
    private func moveCharacterToParadise() {
        isProcessing = true
        
        // 주소 변경
        viewModel.updateAddress(characterUUID: characterUUID, newAddress: .paradise)
        
        // UI 업데이트를 위한 알림 발송
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NotificationCenter.default.post(
                name: NSNotification.Name("CharacterAddressChanged"),
                object: nil,
                userInfo: ["characterUUID": characterUUID, "address": "paradise"]
            )
            
            // 뷰 닫기
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isProcessing = false
                dismiss()
            }
        }
    }
    
    /// 캐릭터 삭제 (우주로 보내기)
    private func deleteCharacter() {
        isProcessing = true
        
        // 캐릭터 삭제
        FirebaseService.shared.deleteCharacter(id: characterUUID) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ 캐릭터 삭제 실패: \(error.localizedDescription)")
                    isProcessing = false
                } else {
                    print("✅ 캐릭터를 우주로 보냈습니다")
                    
                    // UI 업데이트를 위한 알림 발송
                    NotificationCenter.default.post(
                        name: NSNotification.Name("CharacterAddressChanged"),
                        object: nil,
                        userInfo: ["characterUUID": characterUUID, "address": "space"]
                    )
                    
                    // 뷰 닫기
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isProcessing = false
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Helper Views

struct CharacterImageView: View {
    let character: GRCharacter
    
    var body: some View {
        Group {
            if character.status.phase == .egg {
                Image("egg")
                    .resizable()
                    .scaledToFit()
            } else if character.species == .quokka {
                switch character.status.phase {
                    //                case egg = "운석"
                    //                case infant = "유아기"
                    //                case child = "소아기"
                    //                case adolescent = "청년기"
                    //                case adult = "성년기"
                    //                case elder = "노년기"
                case .egg:
                    Image("egg")
                        .resizable()
                        .scaledToFit()
                case .infant:
                    Image("quokka_infant_profile")
                        .resizable()
                        .scaledToFit()
                case .child:
                    Image("quokka_child_profile")
                        .resizable()
                        .scaledToFit()
                case .adolescent:
                    Image("quokka_adolescent_profile")
                        .resizable()
                        .scaledToFit()
                case .adult:
                    Image("quokka_adult_profile")
                        .resizable()
                        .scaledToFit()
                case .elder:
                    Image("quokka")
                        .resizable()
                        .scaledToFit()
                }
            } else {
                Image("CatLion")
                    .resizable()
                    .scaledToFit()
            }
        }
        .background(
            RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                .fill(GRColor.gray200Line)
        )
        .overlay(
            RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                .stroke(GRColor.gray300Disable, lineWidth: 1)
        )
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title + ":")
                .font(.caption)
                .foregroundColor(.textSecondary)
                .frame(width: 60, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.textPrimary)
            
            Spacer()
        }
    }
}

struct StatRow: View {
    let title: String
    let value: Int
    var maxValue: Int = 100
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.textSecondary)
                .frame(width: 50, alignment: .leading)
            
            Text("\(value)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
                .frame(width: 30, alignment: .trailing)
            
            Text("/ \(maxValue)")
                .font(.caption)
                .foregroundColor(.textSecondary)
            
            Spacer()
        }
    }
}

struct StoryRowView: View {
    let post: GRPost
    let onEdit: () -> Void
    let onDelete: () -> Void
    let formatDate: (Date) -> String
    
    var body: some View {
        NavigationLink(destination: WriteStoryView(currentMode: .read, characterUUID: post.characterUUID, postID: post.postID)) {
            HStack(spacing: UIConstants.horizontalPadding) {
                // 이미지 로드중일 시 로딩 인디케이터 표시, 성공 시 이미지 표시, 실패 시 기본 이미지 표시
                if let imageURL = URL(string: post.postImage), !post.postImage.isEmpty {
                    AsyncImage(url: URL(string: post.postImage)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: UIIconSize.avatar / 1.06, height: UIIconSize.avatar / 1.06)
                                .background(
                                    RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                                        .fill(GRColor.gray200Line)
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: UIIconSize.avatar / 1.06, height: UIIconSize.avatar / 1.06)
                                .clipShape(RoundedRectangle(cornerRadius: UIConstants.cornerRadius))
                            
                        case .failure:
                            RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                                .fill(GRColor.gray200Line)
                                .frame(width: UIIconSize.avatar / 1.06, height: UIIconSize.avatar / 1.06)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(GRColor.gray500)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                        .fill(GRColor.gray200Line)
                        .frame(width: UIIconSize.avatar / 1.06, height: UIIconSize.avatar / 1.06)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(GRColor.gray500)
                        )
                }
                
                // 텍스트 정보
                VStack(alignment: .leading, spacing: UIConstants.verticalPadding / 4) {
                    Text(post.postTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundColor(.textPrimary)
                    
                    Text(formatDate(post.createdAt))
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(GRColor.gray400)
            }
            .padding(.vertical, UIConstants.verticalPadding / 2)
            .padding(.horizontal, UIConstants.horizontalPadding)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label("삭제", systemImage: "trash")
            }
            .tint(GRColor.redError)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button(action: onEdit) {
                Label("편집", systemImage: "pencil")
            }
            .tint(GRColor.pointColor)
        }
    }
}

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: UIConstants.verticalPadding) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("로딩 중...")
                    .foregroundColor(.white)
                    .font(.subheadline)
            }
            .padding(UIConstants.horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                    .fill(Color.black.opacity(0.8))
            )
        }
    }
}

// MARK: - Supporting Types

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

// MARK: - Preview
#Preview {
    NavigationStack {
        CharacterDetailView(characterUUID: "2DADAC52-1E6D-4934-9F82-E5610E8C9492")
    }
}
