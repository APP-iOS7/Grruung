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
            VStack(spacing: 20) {
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
                        .font(.title2)
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
        HStack(alignment: .top, spacing: 15) {
            // 캐릭터 이미지
            CharacterImageView(character: viewModel.character)
                .frame(width: 120, height: 120)
            
            // 캐릭터 정보
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(title: "떨어진 날", value: formatDate(viewModel.character.createdAt))
                InfoRow(title: "태어난 날", value: formatDate(viewModel.character.birthDate))
                InfoRow(title: "종", value: viewModel.character.species.rawValue)
                InfoRow(title: "사는 곳", value: getDisplayAddress())
                InfoRow(title: "생 후", value: "\(getDaysOld())일")
                InfoRow(title: "현재 단계", value: viewModel.characterStatus.phase.rawValue)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }
    
    // MARK: - Growth Progress Section
    
    private var growthProgressSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "pawprint.fill")
                    .foregroundColor(.blue)
                Text("성장 과정")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(0...currentStageIndex, id: \.self) { index in
                        VStack(spacing: 8) {
                            // 성장 단계 이미지
                            AsyncImage(
                                url: getGrowthStageImageURL(for: index)
                            ) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray5))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(.gray)
                                    )
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(index == currentStageIndex ? Color.blue.opacity(0.1) : Color.clear)
                            )
                            
                            // 단계 이름
                            Text(getPhaseNameFor(index: index))
                                .font(.caption)
                                .fontWeight(index == currentStageIndex ? .semibold : .regular)
                                .foregroundColor(index == currentStageIndex ? .blue : .secondary)
                        }
                        
                        // 화살표 (마지막이 아닌 경우)
                        if index != currentStageIndex {
                            Image(systemName: "arrow.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
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
                    .foregroundColor(.blue)
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
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
    
    // MARK: - Activity Section
    
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("함께 했던 순간")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack(spacing: 20) {
                // 활동 아이콘
                VStack {
                    Image(systemName: "pawprint.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    
                    Text("총 활동량")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 60)
                
                // 스탯 정보
                VStack(alignment: .leading, spacing: 5) {
                    StatRow(title: "활동량", value: viewModel.characterStatus.activity, color: .orange)
                    StatRow(title: "포만감", value: viewModel.characterStatus.satiety, color: .green)
                    StatRow(title: "체력", value: viewModel.characterStatus.stamina, color: .blue)
                    StatRow(title: "레벨", value: viewModel.characterStatus.level, maxValue: 99, color: .purple)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }
    
    // MARK: - Story List Section
    
    private var storyListSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "book.fill")
                    .foregroundColor(.brown)
                Text("들려준 이야기")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                
                if !viewModel.posts.isEmpty {
                    Text("\(viewModel.posts.count)개")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            if viewModel.posts.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("이번 달에 기록된 이야기가 없습니다")
                        .foregroundColor(.gray)
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
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
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
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
            
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
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .leading)
            
            Text("\(value)")
                .font(.caption)
                .fontWeight(.semibold)
                .frame(width: 30, alignment: .trailing)
            
            Text("/ \(maxValue)")
                .font(.caption)
                .foregroundColor(.secondary)
            
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
            HStack(spacing: 15) {
                // 이미지
                AsyncImage(url: URL(string: post.postImage)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
                
                // 텍스트 정보
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.postTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    Text(formatDate(post.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label("삭제", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button(action: onEdit) {
                Label("편집", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }
}

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 15) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("로딩 중...")
                    .foregroundColor(.white)
                    .font(.subheadline)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
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
