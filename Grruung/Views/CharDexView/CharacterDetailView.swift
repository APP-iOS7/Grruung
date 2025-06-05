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
    
    // MARK: - State Variables
    @State private var searchDate: Date = Date()
    @State private var selectedPostForEdit: PostIdentifier?
    @State private var isShowingNameChangeAlert = false
    @State private var newName: String = ""
    
    // MARK: - Character Actions State
    @State private var isShowingSpaceConfirmation = false
    @State private var isShowingSetMainAlert = false
    
    // MARK: - Constants
    private let estimatedRowHeight: CGFloat = 88.0
    private let deviceModel: String = UIDevice.modelName()
    
    // MARK: - Computed Properties
    
    // 현재 캐릭터의 주소
    private var characterAddress: Address {
        if let address = Address(rawValue: viewModel.characterStatus.address) {
            return address
        }
        return .userHome
    }
    
    // 현재 성장 단계 인덱스
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
    
    // MARK: - Initialization
    
    var characterUUID: String
    
    init(characterUUID: String) {
        self.characterUUID = characterUUID
        self._viewModel = StateObject(wrappedValue: CharacterDetailViewModel(characterUUID: characterUUID))
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: UIConstants.verticalPadding) { // UIConstants 사용
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
            .padding(.bottom, 30)
        }
        .scrollContentBackground(.hidden) // 기본 배경을 숨기고
        .background(
            LinearGradient(colors: [
                Color(GRColor.mainColor1_1),
                Color(GRColor.mainColor1_2)
            ],
                           startPoint: .top, endPoint: .bottom)
        ) // 원하는 색상 지정
        .navigationTitle(viewModel.character.name.isEmpty ? "캐릭터" : viewModel.character.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    // 이름 변경
                    Button(action: {
                        newName = viewModel.character.name
                        isShowingNameChangeAlert = true
                    }) {
                        Label("이름 바꿔주기", systemImage: "pencil")
                    }
                    
                    // 메인으로 설정 (현재 위치가 userHome이 아닐 때만 표시)
                    if characterAddress != .userHome {
                        Button(action: {
                            isShowingSetMainAlert = true
                        }) {
                            Label("메인으로 설정", systemImage: "house")
                        }
                    }
                    
                    Divider()
                    
                    // 위치 이동 버튼들
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
                        .font(.title2) // TODO: UIIconSize 또는 별도 폰트 스타일 가이드 확인 필요
                }
            }
        }
        .onAppear {
            print("📱 CharacterDetailView 표시됨 - 캐릭터: \(characterUUID)")
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
                // 먼저 userHome으로 이동 후 메인으로 설정
                viewModel.updateAddress(characterUUID: characterUUID, newAddress: .userHome)
                viewModel.setAsMainCharacter(characterUUID: characterUUID)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    dismiss()
                }
            }
        } message: {
            Text("이 캐릭터를 메인 캐릭터로 설정하고 홈 화면에 표시합니다.")
        }
        .alert("캐릭터를 우주로 보내시겠습니까?", isPresented: $isShowingSpaceConfirmation) {
            Button("취소", role: .cancel) { }
            
            Button("보내기", role: .destructive) {
                // 우주로 보내기 (완전히 삭제)
                FirebaseService.shared.deleteCharacter(id: characterUUID) { error in
                    if let error = error {
                        print("❌ 캐릭터 삭제 실패: \(error.localizedDescription)")
                    } else {
                        print("✅ 캐릭터를 우주로 보냈습니다")
                        
                        // 알림 보내기
                        NotificationCenter.default.post(
                            name: NSNotification.Name("CharacterAddressChanged"),
                            object: nil,
                            userInfo: ["characterUUID": characterUUID, "address": "space"]
                        )
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            dismiss()
                        }
                    }
                }
            }
        } message: {
            Text("캐릭터를 우주로 보내면 더 이상 접근할 수 없습니다.")
        }
        .overlay {
            if viewModel.isLoading {
                LoadingOverlay()
            }
        }
    }
    
    // MARK: - Character Info Section
    
    private var characterInfoSection: some View {
        HStack(alignment: .top, spacing: UIConstants.horizontalPadding) { // UIConstants 사용
            // 캐릭터 이미지
            CharacterImageView(character: viewModel.character)
                .frame(width: UIConstants.imageViewHeight, height: UIConstants.imageViewHeight) // UIConstants 사용
            
            // 캐릭터 정보
            VStack(alignment: .leading, spacing: UIConstants.verticalPadding / 2) { // UIConstants 사용
                InfoRow(title: "떨어진 날", value: formatDate(viewModel.character.createdAt))
                InfoRow(title: "태어난 날", value: formatDate(viewModel.character.birthDate))
                InfoRow(title: "종", value: viewModel.character.species.rawValue)
                InfoRow(title: "사는 곳", value: getDisplayAddress())
                InfoRow(title: "생 후", value: "\(getDaysOld())일")
                InfoRow(title: "현재 단계", value: viewModel.characterStatus.phase.rawValue)
            }
            
            Spacer()
        }
        .padding(.horizontal, UIConstants.horizontalPadding) // UIConstants 사용
        .padding(.vertical, UIConstants.verticalPadding / 1.6) // UIConstants 사용 (적절한 값으로 조정)
        .background(
            RoundedRectangle(cornerRadius: UIConstants.cornerRadius) // UIConstants 사용
                .fill(Color.background) // Color extension 사용
        )
        .padding(.horizontal, UIConstants.horizontalPadding) // UIConstants 사용
    }
    
    // MARK: - Growth Progress Section
    
    private var growthProgressSection: some View {
        VStack(alignment: .leading, spacing: UIConstants.verticalPadding) { // UIConstants 사용
            HStack {
                Image(systemName: "pawprint.fill")
                    .foregroundColor(GRColor.pointColor) // GRColor 사용
                Text("성장 과정")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: UIConstants.horizontalPadding) { // UIConstants 사용
                    ForEach(0...currentStageIndex, id: \.self) { index in
                        VStack(spacing: UIConstants.verticalPadding / 2) { // UIConstants 사용 (적절한 값으로 조정)
                            // 성장 단계 이미지
                            AsyncImage(
                                url: getGrowthStageImageURL(for: index)
                            ) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: UIIconSize.avatar / 1.06, height: UIIconSize.avatar / 1.06) // UIIconSize 사용 (적절한 값으로 조정)
                            } placeholder: {
                                RoundedRectangle(cornerRadius: UIConstants.cornerRadius) // UIConstants 사용
                                    .fill(GRColor.gray200Line) // GRColor 사용
                                    .frame(width: UIIconSize.avatar / 1.06, height: UIIconSize.avatar / 1.06) // UIIconSize 사용 (적절한 값으로 조정)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(GRColor.gray500) // GRColor 사용
                                    )
                            }
                            .background(
                                RoundedRectangle(cornerRadius: UIConstants.cornerRadius) // UIConstants 사용
                                    .fill(index == currentStageIndex ? GRColor.pointColor.opacity(0.1) : Color.clear) // GRColor 사용
                            )
                            
                            // 단계 이름
                            Text(getPhaseNameFor(index: index))
                                .font(.caption)
                                .fontWeight(index == currentStageIndex ? .semibold : .regular)
                                .foregroundColor(index == currentStageIndex ? GRColor.pointColor : .textSecondary) // GRColor 및 Color extension 사용
                        }
                        
                        // 화살표 (마지막이 아닌 경우)
                        if index != currentStageIndex {
                            Image(systemName: "arrow.right")
                                .foregroundColor(GRColor.gray400) // GRColor 사용
                                .font(.caption)
                        }
                    }
                }
                .padding(.horizontal, UIConstants.horizontalPadding) // UIConstants 사용
            }
        }
        .padding(.horizontal, UIConstants.horizontalPadding) // UIConstants 사용
        .padding(.vertical, UIConstants.verticalPadding) // UIConstants 사용
        .background(
            RoundedRectangle(cornerRadius: UIConstants.cornerRadius) // UIConstants 사용
                .fill(Color.background) // Color extension 사용
        )
        .padding(.horizontal, UIConstants.horizontalPadding) // UIConstants 사용
    }
    
    // MARK: - Date Navigation Section
    
    private var dateNavigationSection: some View {
        HStack {
            Button(action: {
                searchDate = Calendar.current.date(byAdding: .month, value: -1, to: searchDate) ?? searchDate
                viewModel.loadPost(characterUUID: characterUUID, searchDate: searchDate)
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2) // TODO: UIIconSize 또는 별도 폰트 스타일 가이드 확인 필요
                    .foregroundColor(GRColor.pointColor) // GRColor 사용
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
                    .font(.title2) // TODO: UIIconSize 또는 별도 폰트 스타일 가이드 확인 필요
                    .foregroundColor(GRColor.pointColor) // GRColor 사용
            }
        }
        .padding(.horizontal, UIConstants.horizontalPadding) // UIConstants 사용
        .padding(.vertical, UIConstants.verticalPadding / 1.6) // UIConstants 사용 (적절한 값으로 조정)
    }
    
    // MARK: - Activity Section
    
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: UIConstants.verticalPadding) { // UIConstants 사용
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(GRColor.grColorRed) // GRColor 사용
                Text("함께 했던 순간")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack(spacing: UIConstants.horizontalPadding) { // UIConstants 사용
                // 활동 아이콘
                VStack {
                    Image(systemName: "pawprint.circle.fill")
                        .font(.system(size: UIIconSize.large)) // UIIconSize 사용
                        .foregroundColor(GRColor.grColorOrange) // GRColor 사용
                    
                    Text("총 활동량")
                        .font(.caption)
                        .foregroundColor(.textSecondary) // Color extension 사용
                }
                
                Divider()
                    .frame(height: 60)
                
                // 스탯 정보
                VStack(alignment: .leading, spacing: 5) { // TODO: UIConstants에서 적절한 값으로 변경 고려
                    StatRow(title: "활동량", value: viewModel.characterStatus.activity, color: GRColor.grColorOrange) // GRColor 사용
                    StatRow(title: "포만감", value: viewModel.characterStatus.satiety, color: GRColor.grColorGreen) // GRColor 사용
                    StatRow(title: "체력", value: viewModel.characterStatus.stamina, color: GRColor.grColorBlue) // GRColor 사용
                    StatRow(title: "레벨", value: viewModel.characterStatus.level, maxValue: 99, color: GRColor.grColorPurple) // GRColor 사용
                }
                
                Spacer()
            }
        }
        .padding(UIConstants.horizontalPadding) // UIConstants 사용
        .background(
            RoundedRectangle(cornerRadius: UIConstants.cornerRadius) // UIConstants 사용
                .fill(Color.background) // Color extension 사용
        )
        .padding(.horizontal, UIConstants.horizontalPadding) // UIConstants 사용
    }
    
    // MARK: - Story List Section
    
    private var storyListSection: some View {
        VStack(alignment: .leading, spacing: UIConstants.verticalPadding) { // UIConstants 사용
            HStack {
                Image(systemName: "book.fill")
                    .foregroundColor(GRColor.grColorBrown) // GRColor 사용
                Text("들려준 이야기")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                
                if !viewModel.posts.isEmpty {
                    Text("\(viewModel.posts.count)개")
                        .font(.caption)
                        .foregroundColor(.textSecondary) // Color extension 사용
                }
            }
            .padding(.horizontal, UIConstants.horizontalPadding) // UIConstants 사용
            
            if viewModel.posts.isEmpty {
                VStack(spacing: 10) { // TODO: UIConstants에서 적절한 값으로 변경 고려
                    Image(systemName: "book.closed")
                        .font(.system(size: UIIconSize.large)) // UIIconSize 사용
                        .foregroundColor(GRColor.gray400) // GRColor 사용
                    
                    Text("이번 달에 기록된 이야기가 없습니다")
                        .foregroundColor(GRColor.gray500) // GRColor 사용
                        .font(.subheadline)
                }
                .frame(height: 100)
                .frame(maxWidth: .infinity)
            } else {
                LazyVStack(spacing: 0) {
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
                                .padding(.leading, 80) // TODO: UIConstants 또는 다른 방식으로 값 관리 고려
                        }
                    }
                }
                .background(Color.background) // Color extension 사용
                .cornerRadius(UIConstants.cornerRadius) // UIConstants 사용
            }
        }
        .padding(.horizontal, UIConstants.horizontalPadding) // UIConstants 사용
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
                Image("quokka")
                    .resizable()
                    .scaledToFit()
            } else {
                Image("CatLion")
                    .resizable()
                    .scaledToFit()
            }
        }
        .background(
            RoundedRectangle(cornerRadius: UIConstants.cornerRadius) // UIConstants 사용
                .fill(GRColor.gray200Line) // GRColor 사용
        )
        .overlay(
            RoundedRectangle(cornerRadius: UIConstants.cornerRadius) // UIConstants 사용
                .stroke(GRColor.gray300Disable, lineWidth: 1) // GRColor 사용
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
                .foregroundColor(.textSecondary) // Color extension 사용
                .frame(width: 60, alignment: .leading) // TODO: UIConstants 값으로 변경 고려
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.textPrimary) // Color extension 사용
            
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
                .foregroundColor(.textSecondary) // Color extension 사용
                .frame(width: 50, alignment: .leading) // TODO: UIConstants 값으로 변경 고려
            
            Text("\(value)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color) // GRColor 사용 (파라미터로 전달받은 color)
                .frame(width: 30, alignment: .trailing) // TODO: UIConstants 값으로 변경 고려
            
            Text("/ \(maxValue)")
                .font(.caption)
                .foregroundColor(.textSecondary) // Color extension 사용
            
            Spacer()
        }
    }
}

struct StoryRowView: View {
    let post: GRPost
    let onEdit: () -> Void
    let onDelete: () -> Void
    let formatDate: (Date) -> String // 추가
    
    var body: some View {
        NavigationLink(destination: WriteStoryView(currentMode: .read, characterUUID: post.characterUUID, postID: post.postID)) {
            HStack(spacing: UIConstants.horizontalPadding) { // UIConstants 사용
                // 이미지
                AsyncImage(url: URL(string: post.postImage)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: UIIconSize.avatar / 1.06, height: UIIconSize.avatar / 1.06) // UIIconSize 사용 (적절한 값으로 조정)
                        .clipShape(RoundedRectangle(cornerRadius: UIConstants.cornerRadius)) // UIConstants 사용
                } placeholder: {
                    RoundedRectangle(cornerRadius: UIConstants.cornerRadius) // UIConstants 사용
                        .fill(GRColor.gray200Line) // GRColor 사용
                        .frame(width: UIIconSize.avatar / 1.06, height: UIIconSize.avatar / 1.06) // UIIconSize 사용 (적절한 값으로 조정)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(GRColor.gray500) // GRColor 사용
                        )
                }
                
                // 텍스트 정보
                VStack(alignment: .leading, spacing: UIConstants.verticalPadding / 4) { // UIConstants 사용 (적절한 값으로 조정)
                    Text(post.postTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundColor(.textPrimary) // Color extension 사용
                    
                    Text(formatDate(post.createdAt))
                        .font(.caption)
                        .foregroundColor(.textSecondary) // Color extension 사용
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(GRColor.gray400) // GRColor 사용
            }
            .padding(.vertical, UIConstants.verticalPadding / 2) // UIConstants 사용 (적절한 값으로 조정)
            .padding(.horizontal, UIConstants.horizontalPadding) // UIConstants 사용
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label("삭제", systemImage: "trash")
            }
            .tint(GRColor.redError) // GRColor 사용
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button(action: onEdit) {
                Label("편집", systemImage: "pencil")
            }
            .tint(GRColor.pointColor) // GRColor 사용
        }
    }
}

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: UIConstants.verticalPadding) { // UIConstants 사용
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("로딩 중...")
                    .foregroundColor(.white)
                    .font(.subheadline)
            }
            .padding(UIConstants.horizontalPadding) // UIConstants 사용
            .background(
                RoundedRectangle(cornerRadius: UIConstants.cornerRadius) // UIConstants 사용
                    .fill(Color.black.opacity(0.8))
            )
        }
    }
}

// MARK: - CharacterDetailView Extensions

extension CharacterDetailView {
    
    // 표시용 주소 문자열 반환
    private func getDisplayAddress() -> String {
        if characterAddress == .userHome {
            return "\(viewModel.user.userName)의 \(deviceModel)"
        } else {
            return getAddressDisplayName(characterAddress)
        }
    }
    
    // 태어난 후 경과 일수 계산
    private func getDaysOld() -> Int {
        Calendar.current.dateComponents([.day], from: viewModel.character.birthDate, to: Date()).day ?? 0
    }
    
    // 성장 단계 이미지 URL 반환
    private func getGrowthStageImageURL(for index: Int) -> URL? {
        guard index < viewModel.growthStages.count else { return nil }
        return viewModel.growthStages[index].imageURL
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
    
    // 주소 표시명 반환
    private func getAddressDisplayName(_ address: Address) -> String {
        switch address {
        case .userHome: return "메인"
        case .paradise: return "동산"
        case .space: return "우주"
        }
    }
    
    // 액션에 따른 시스템 이미지 반환
    private func getSystemImageForAction(_ title: String) -> String {
        switch title {
        case "기기로 불러오기": return "house"
        case "동산으로 보내기": return "mountain.2"
        case "우주로 보내기": return "trash"
        default: return "questionmark"
        }
    }
    
    // 사용 가능한 목적지 반환
    private func getAvailableDestinations(from currentLocation: Address) -> [Address] {
        switch currentLocation {
        case .userHome: return [.paradise, .space]
        case .paradise: return [.userHome, .space]
        case .space: return [.userHome, .paradise]
        }
    }
    
    // 주소 메뉴 아이템 생성
    private func getAddressMenuItems() -> [MenuItem] {
        let destinations = getAvailableDestinations(from: characterAddress)
        
        return destinations.map { destination in
            let titleText: String
            switch destination {
            case .userHome: titleText = "기기로 불러오기"
            case .paradise: titleText = "동산으로 보내기"
            case .space: titleText = "우주로 보내기"
            }
            
            return MenuItem(
                title: titleText,
                action: {
                    if destination == .space {
                        isShowingSpaceConfirmation = true
                    } else {
                        // 주소 변경
                        viewModel.updateAddress(characterUUID: characterUUID, newAddress: destination)
                        
                        // 알림 보내기
                        NotificationCenter.default.post(
                            name: NSNotification.Name("CharacterAddressChanged"),
                            object: nil,
                            userInfo: ["characterUUID": characterUUID, "address": destination.rawValue]
                        )
                        
                        if destination != .userHome {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                dismiss()
                            }
                        }
                    }
                }
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

// MARK: - UIDevice Extension

extension UIDevice {
    static func getDeviceModelName() -> String {
        return "iPhone"
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CharacterDetailView(characterUUID: "CF6NXxcH5HgGjzVE0nVE")
    }
}
