//
//  CharDexView.swift
//  Grruung
//
//  Created by mwpark on 5/2/25.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage

struct CharDexView: View {
    // MARK: - Properties
    
    // 생성 가능한 최대 캐릭터 수
    private let maxDexCount: Int = 10
    
    // 캐릭터 관련 상태
    @State private var characters: [GRCharacter] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    
    // 정렬 옵션
    @State private var sortType: SortType = .original
    
    // 슬롯 관련 상태
    @State private var unlockCount: Int = 2  // 기본값 2개 슬롯 해금
    @State private var unlockTicketCount: Int = 0
    @State private var selectedLockedIndex: Int = -1
    
    // 알림창 상태
    @State private var showingUnlockAlert = false
    @State private var showingNotEnoughAlert = false
    @State private var showingNotEnoughTicketAlert = false
    @State private var showingErrorAlert = false
    @State private var firstAlert = true
    
    // Environment Objects
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var userInventoryViewModel: UserInventoryViewModel
    @EnvironmentObject private var characterDexViewModel: CharacterDexViewModel
    
    // Grid 레이아웃 설정
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    // MARK: - Computed Properties
    
    // 정렬 타입 정의
    private enum SortType {
        case original
        case createdAscending
        case createdDescending
        case alphabet
    }
    
    // 정렬된 캐릭터 목록
    private var sortedCharacters: [GRCharacter] {
        let visibleCharacters = characters.filter { $0.status.address != "space" }
        
        switch sortType {
        case .original:
            return visibleCharacters
        case .createdAscending:
            return visibleCharacters.sorted { $0.birthDate > $1.birthDate }
        case .createdDescending:
            return visibleCharacters.sorted { $0.birthDate < $1.birthDate }
        case .alphabet:
            return visibleCharacters.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        }
    }
    
    // 표시할 슬롯(캐릭터 + 추가 가능 슬롯 + 잠금 슬롯)
    private var displaySlots: [SlotItem] {
        // 1. 실제 캐릭터 슬롯
        let characterSlots = sortedCharacters.map { SlotItem.character($0) }
        
        // 2. 추가 가능한 슬롯 ('플러스' 슬롯)
        let addableCount = max(0, unlockCount - characterSlots.count)
        let addSlots = (0..<addableCount).map { _ in SlotItem.add }
        
        // 3. 잠금 슬롯
        let filledCount = characterSlots.count + addSlots.count
        let lockedCount = max(0, maxDexCount - filledCount)
        let lockSlots = (0..<lockedCount).map { idx in SlotItem.locked(index: idx) }
        
        return characterSlots + addSlots + lockSlots
    }
    
    // 현재 유저 ID
    private var currentUserId: String {
        authService.currentUserUID.isEmpty ? "23456" : authService.currentUserUID
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    VStack {
                        ProgressView("데이터 로딩 중...")
                            .padding(.top, 100)
                    }
                } else {
                    VStack(spacing: 20) {
                        // 수집 현황 정보
                        HStack {
                            Text("\(sortedCharacters.count)")
                                .foregroundStyle(.yellow)
                            Text("/ \(maxDexCount) 수집")
                        }
                        .frame(maxWidth: 180)
                        .font(.title)
                        .background(alignment: .center) {
                            Capsule()
                                .fill(Color.brown.opacity(0.5))
                        }
                        
                        // 티켓 수량 표시
                        ticketCountView
                        
                        // 캐릭터 그리드
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(Array(displaySlots.enumerated()), id: \.offset) { index, slot in
                                switch slot {
                                case .character(let character):
                                    NavigationLink(destination: CharacterDetailView(characterUUID: character.id)) {
                                        characterSlot(character)
                                    }
                                case .add:
                                    NavigationLink(destination: OnboardingView()) {
                                        addSlot
                                    }
                                case .locked(let index):
                                    lockSlot(index: index)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("캐릭터 동산")
            .toolbar {
                // 검색 버튼
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: CharDexSearchView(searchCharacters: sortedCharacters)) {
                        Image(systemName: "magnifyingglass")
                    }
                }
                
                // 정렬 옵션 메뉴
                ToolbarItem(placement: .navigationBarTrailing) {
                    sortOptionsMenu
                }
            }
            .onAppear {
                loadData()
                
                // 알림 리스너 설정
                setupNotificationObservers()
            }
            .onDisappear {
                // 알림 리스너 제거
                NotificationCenter.default.removeObserver(self)
            }
            
            // MARK: - Alert Modifiers
            .alert("슬롯을 해제합니다.", isPresented: $showingUnlockAlert) {
                Button("해제", role: .destructive) {
                    unlockSlot()
                }
                Button("취소", role: .cancel) {}
            }
            .alert("슬롯을 해제하면 더 많은 캐릭터를 추가할 수 있습니다.", isPresented: $showingNotEnoughAlert) {
                Button("확인", role: .cancel) {
                    firstAlert = false
                }
            }
            .alert("잠금해제 티켓의 수가 부족합니다", isPresented: $showingNotEnoughTicketAlert) {
                Button("확인", role: .cancel) {}
            }
            .alert("에러 발생", isPresented: $showingErrorAlert) {
                Button("확인", role: .cancel) {}
            } message: {
                Text("알 수 없는 에러가 발생하였습니다!")
            }
        }
    }
    
    // MARK: - UI Components
    
    // 티켓 수량 표시 뷰
    private var ticketCountView: some View {
        HStack {
            if unlockTicketCount <= 0 {
                ZStack {
                    Image(systemName: "ticket")
                        .resizable()
                        .scaledToFit()
                        .padding(.top, 8)
                        .frame(width: 30, height: 30)
                        .foregroundStyle(Color.brown.opacity(0.5))
                    Image(systemName: "xmark")
                        .resizable()
                        .scaledToFit()
                        .padding(.top, 8)
                        .frame(width: 30, height: 30)
                        .foregroundStyle(.red)
                }
            }
            ForEach(0..<unlockTicketCount, id: \.self) { _ in
                Image(systemName: "ticket")
                    .resizable()
                    .scaledToFit()
                    .padding(.top, 8)
                    .frame(width: 30, height: 30)
                    .foregroundStyle(Color.brown.opacity(0.5))
            }
        }
    }
    
    // 정렬 옵션 메뉴
    private var sortOptionsMenu: some View {
        Menu {
            Button {
                sortType = .original
            } label: {
                Label("기본", systemImage: sortType == .original ? "checkmark" : "")
            }
            
            Button {
                sortType = .alphabet
            } label: {
                Label("가나다 순", systemImage: sortType == .alphabet ? "checkmark" : "")
            }
            
            Button {
                sortType = .createdAscending
            } label: {
                Label("생성 순 ↑", systemImage: sortType == .createdAscending ? "checkmark" : "")
            }
            
            Button {
                sortType = .createdDescending
            } label: {
                Label("생성 순 ↓", systemImage: sortType == .createdDescending ? "checkmark" : "")
            }
        } label: {
            Label("정렬", systemImage: "line.3.horizontal")
        }
    }
    
    // 캐릭터 슬롯 뷰
    private func characterSlot(_ character: GRCharacter) -> some View {
        VStack(alignment: .center) {
            ZStack {
                // 이미지 부분
                Group {
                    if character.status.phase == .egg {
                        // 운석 단계일 경우 이미지 사용
                        Image("egg")
                            .resizable()
                            .frame(width: 100, height: 100, alignment: .center)
                            .aspectRatio(contentMode: .fit)
                    } else {
                        // 그 외 단계에서는 species에 따라 이미지 결정
                        if character.species == .quokka {
                            Image("quokka")
                                .resizable()
                                .frame(width: 100, height: 100, alignment: .center)
                                .aspectRatio(contentMode: .fit)
                        } else {
                            Image("CatLion")
                                .resizable()
                                .frame(width: 100, height: 100, alignment: .center)
                                .aspectRatio(contentMode: .fit)
                        }
                    }
                }
                .foregroundStyle(.black)
                
                // 위치 표시 아이콘
                if character.status.address == "space" {
                    Image(systemName: "xmark")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 15, height: 15)
                        .offset(x: 60, y: -40)
                        .foregroundStyle(.red)
                } else {
                    Image(systemName: character.status.address == "userHome" ? "house": "mountain.2")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .offset(x: 60, y: -40)
                        .foregroundStyle(character.status.address == "userHome" ? .blue : .black)
                }
            }
            Text(character.name)
                .foregroundStyle(.black)
                .bold()
                .lineLimit(1)
                .frame(maxWidth: .infinity)
            
            Text("\(calculateAge(character.birthDate)) 살 (\(formatToMonthDay(character.birthDate)) 생)")
                .foregroundStyle(.gray)
                .font(.caption)
                .frame(maxWidth: .infinity)
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
        .background(Color.brown.opacity(0.5))
        .cornerRadius(20)
        .foregroundColor(.gray)
        .padding(.bottom, 16)
    }
    
    // 잠겨있는 슬롯
    private func lockSlot(index: Int) -> some View {
        Button {
            selectedLockedIndex = index
            showingUnlockAlert = true
        } label: {
            VStack {
                Image(systemName: "lock.fill")
                    .scaledToFit()
                    .font(.system(size: 60))
                    .foregroundStyle(.black)
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(20)
            }
            .padding(.bottom, 16)
        }
        .buttonStyle(.plain)
    }
    
    // 추가할 수 있는 슬롯
    private var addSlot: some View {
        VStack {
            Image(systemName: "plus")
                .scaledToFit()
                .font(.system(size: 60))
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .background(Color.brown.opacity(0.5))
                .cornerRadius(20)
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - Methods
    
    /// 초기 데이터 로딩
    private func loadData() {
        Task {
            isLoading = true
            
            // 1. 캐릭터 데이터 로드
            await loadCharacters()
            
            // 2. 인벤토리 데이터 로드
            do {
                try await userInventoryViewModel.fetchInventories(userId: currentUserId)
            } catch {
                print("❌ 인벤토리 로드 실패: \(error.localizedDescription)")
            }
            
            // 3. 동산 정보 로드
            do {
                try await characterDexViewModel.fetchCharDex(userId: currentUserId)
                
                // 상태 업데이트
                unlockCount = characterDexViewModel.unlockCount
                unlockTicketCount = characterDexViewModel.unlockTicketCount
                selectedLockedIndex = characterDexViewModel.selectedLockedIndex
                
                // 티켓 수량 확인 및 업데이트
                if let ticket = userInventoryViewModel.inventories.first(where: { $0.userItemName == "동산 잠금해제x1" }) {
                    unlockTicketCount = ticket.userItemQuantity
                    await updateCharDexData()
                }
                
                // 캐릭터 수와 해제 슬롯 수 체크
                if unlockCount == sortedCharacters.count && firstAlert {
                    showingNotEnoughAlert = true
                }
                
                if sortedCharacters.count > unlockCount {
                    showingErrorAlert = true
                }
            } catch {
                print("❌ 동산 데이터 로드 실패: \(error.localizedDescription)")
            }
            
            isLoading = false
        }
    }
    
    /// 캐릭터 데이터 로드
    private func loadCharacters() async {
        print("📱 캐릭터 데이터 로드 시작")
        
        // 1. 메인 캐릭터 로드
        let userHomeCharacters = await fetchCharactersWithAddress(address: "userHome")
        
        // 2. 동산 캐릭터 로드
        let paradiseCharacters = await fetchCharactersWithAddress(address: "paradise")
        
        // 3. 전체 캐릭터 통합
        let allCharacters = userHomeCharacters + paradiseCharacters
        
        print("📱 총 \(allCharacters.count)개 캐릭터 로드 (Home: \(userHomeCharacters.count), Paradise: \(paradiseCharacters.count))")
        
        // UI 업데이트
        await MainActor.run {
            self.characters = allCharacters
        }
    }
    
    /// 특정 주소에 있는 캐릭터 로드
    private func fetchCharactersWithAddress(address: String) async -> [GRCharacter] {
        let displayAddress: String
        
        // 주소 변환 (영문 -> 한글)
        switch address {
        case "paradise":
            displayAddress = "paradise"
        case "userHome":
            displayAddress = "userHome"
        default:
            displayAddress = address
        }
        
        return await withCheckedContinuation { continuation in
            FirebaseService.shared.findCharactersByAddress(address: displayAddress) { characters, error in
                if let error = error {
                    print("❌ 주소 \(address) 캐릭터 로드 실패: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                } else {
                    print("✅ 주소 \(address)에서 \(characters?.count ?? 0)개 캐릭터 로드")
                    continuation.resume(returning: characters ?? [])
                }
            }
        }
    }
    
    /// 동산 데이터 업데이트
    private func updateCharDexData() async {
        characterDexViewModel.updateCharDex(
            userId: currentUserId,
            unlockCount: unlockCount,
            unlockTicketCount: unlockTicketCount,
            selectedLockedIndex: selectedLockedIndex
        )
    }
    
    /// 슬롯 해금
    private func unlockSlot() {
        if unlockTicketCount <= 0 {
            showingNotEnoughTicketAlert = true
            return
        }
        
        if unlockCount < maxDexCount {
            if let ticket = userInventoryViewModel.inventories.first(where: { $0.userItemName == "동산 잠금해제x1" }) {
                // 슬롯 해금
                unlockCount += 1
                unlockTicketCount -= 1
                
                // Firebase 업데이트
                characterDexViewModel.updateCharDex(
                    userId: currentUserId,
                    unlockCount: unlockCount,
                    unlockTicketCount: unlockTicketCount,
                    selectedLockedIndex: selectedLockedIndex
                )
                
                // 인벤토리 아이템 수량 업데이트
                userInventoryViewModel.updateItemQuantity(
                    userId: currentUserId,
                    item: ticket,
                    newQuantity: unlockTicketCount
                )
            } else {
                showingErrorAlert = true
            }
        }
    }
    
    /// 알림 리스너 설정
    private func setupNotificationObservers() {
        // 캐릭터 주소 변경 리스너
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("CharacterAddressChanged"),
            object: nil,
            queue: .main
        ) { _ in
            Task {
                await self.loadCharacters()
            }
        }
        
        // 캐릭터 이름 변경 리스너
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("CharacterNameChanged"),
            object: nil,
            queue: .main
        ) { _ in
            Task {
                await self.loadCharacters()
            }
        }
        
        // 메인 캐릭터 설정 리스너
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("CharacterSetAsMain"),
            object: nil,
            queue: .main
        ) { _ in
            Task {
                await self.loadCharacters()
            }
        }
    }
}

// MARK: - Helper Types

/// 슬롯 아이템 타입
enum SlotItem {
    case character(GRCharacter)
    case add
    case locked(index: Int)
}

// MARK: - Helper Functions

/// 날짜를 MM월 DD일 형식으로 변환
func formatToMonthDay(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM월 dd일"
    return formatter.string(from: date)
}

/// 나이 계산 함수
func calculateAge(_ birthDate: Date) -> Int {
    let calendar = Calendar.current
    let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
    return ageComponents.year ?? 0
}

// MARK: - Preview
#Preview {
    CharDexView()
        .environmentObject(CharacterDexViewModel())
        .environmentObject(UserInventoryViewModel())
        .environmentObject(AuthService())
}
