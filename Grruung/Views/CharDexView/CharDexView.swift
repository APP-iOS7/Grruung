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
    
    // FIXME: - Start 실시간 리스너를 위한 속성 추가
    @State private var charactersListener: ListenerRegistration?
    // FIXME: - End
    
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
    @State private var showingOnboarding = false
    
    // Environment Objects
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var userInventoryViewModel: UserInventoryViewModel
    @EnvironmentObject private var characterDexViewModel: CharacterDexViewModel
    
    @State private var isDataLoaded: Bool = false
    
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
            ZStack {
                VStack {
                    if isLoading || !isDataLoaded {
                        LoadingView()
                    } else {
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
                                                Button {
                                                    // 슬롯이 가득 찼는지 확인
                                                    if sortedCharacters.count >= unlockCount {
                                                        showingNotEnoughAlert = true
                                                    } else {
                                                        showingOnboarding = true
                                                    }
                                                } label: {
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
                    }
                }
            }
            .padding(.bottom, 30)
            .scrollContentBackground(.hidden)
            .background(
                LinearGradient(colors: [
                    Color(GRColor.mainColor1_1),
                    Color(GRColor.mainColor1_2)
                ],
                               startPoint: .top, endPoint: .bottom)
            ) 
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
                loadInitialData()
            }
            .onDisappear {
                // FIXME: - Start 리스너 정리
                charactersListener?.remove()
                charactersListener = nil
                // FIXME: - End
            }
            
            // MARK: - Alert Modifiers
            .alert("슬롯을 해제합니다.", isPresented: $showingUnlockAlert) {
                Button("해제", role: .destructive) {
                    unlockSlot()
                }
                Button("취소", role: .cancel) {}
            }
            .alert("슬롯을 해제하면 더 많은 캐릭터를 추가할 수 있습니다.", isPresented: $showingNotEnoughAlert) {
                Button("슬롯 해금하기") {
                    selectedLockedIndex = 0
                    showingUnlockAlert = true
                }
                Button("취소", role: .cancel) {
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
            .sheet(isPresented: $showingOnboarding) {
                OnboardingView()
                    .onDisappear {
                        // 온보딩이 끝나면 데이터 새로고침은 실시간 리스너가 처리
                        print("✅ 온보딩 완료 - 실시간 리스너가 자동 업데이트 처리")
                    }
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
                if character.status.address == "userHome" {
                    Image(systemName: "house")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .offset(x: 60, y: -40)
                        .foregroundStyle(.blue)
                } else if character.status.address == "paradise" {
                    Image(systemName: "mountain.2")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .offset(x: 60, y: -40)
                        .foregroundStyle(.black)
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
        .cornerRadius(UIConstants.cornerRadius)
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
    
    // 데이터 로딩
    private func loadInitialData() {
        Task {
            isLoading = true
            isDataLoaded = false
            
            guard let currentUserId = authService.user?.uid else {
                print("❌ 사용자 ID를 찾을 수 없습니다.")
                isLoading = false
                return
            }
            
            // 1. 동산 데이터 먼저 로드
            do {
                try await characterDexViewModel.fetchCharDex(userId: currentUserId)
                unlockCount = characterDexViewModel.unlockCount
                unlockTicketCount = characterDexViewModel.unlockTicketCount
                selectedLockedIndex = characterDexViewModel.selectedLockedIndex
            } catch {
                print("❌ 동산 데이터 로드 실패: \(error.localizedDescription)")
            }
            
            // 2. 인벤토리 데이터 로드
            do {
                try await userInventoryViewModel.fetchInventories(userId: currentUserId)
                
                // 티켓 수량 확인 및 업데이트
                if let ticket = userInventoryViewModel.inventories.first(where: { $0.userItemName == "동산 잠금해제x1" }) {
                    unlockTicketCount = ticket.userItemQuantity
                    await updateCharDexData()
                }
            } catch {
                print("❌ 인벤토리 로드 실패: \(error.localizedDescription)")
            }
            
            // 3. 캐릭터 데이터 로드 (실시간 리스너로 설정)
            setupRealtimeCharacterListener()
            
            // 로딩 상태 업데이트
            isLoading = false
            
            // 데이터가 실제로 로드될 때까지 isDataLoaded를 false로 유지
            // 실시간 리스너에서 데이터가 처음 도착하면 isDataLoaded를 true로 설정
        }
    }
    
    // FIXME: - Start 실시간 캐릭터 리스너 설정
    /// Firebase 실시간 리스너를 설정하여 캐릭터 변화를 감지
    private func setupRealtimeCharacterListener() {
        guard let userID = authService.user?.uid else {
            print("❌ 사용자 인증 정보가 없습니다")
            return
        }
        
        print("🔄 실시간 캐릭터 리스너 설정 중...")
        
        // 기존 리스너가 있다면 제거
        charactersListener?.remove()
        
        // 캐릭터 컬렉션에 실시간 리스너 설정
        charactersListener = Firestore.firestore()
            .collection("users").document(userID)
            .collection("characters")
            .addSnapshotListener { snapshot, error in
                
                if let error = error {
                    print("❌ 실시간 리스너 오류: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.errorMessage = "데이터 동기화 실패: \(error.localizedDescription)"
                        self.isDataLoaded = true // 오류가 있어도 로딩 상태 종료
                    }
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("📝 캐릭터 문서가 없습니다")
                    DispatchQueue.main.async {
                        self.characters = []
                        self.isDataLoaded = true // 데이터가 없어도 로딩 상태 종료
                    }
                    return
                }
                
                print("🔄 실시간 업데이트: \(documents.count)개 캐릭터 감지")
                
                // 문서들을 GRCharacter 객체로 변환
                let updatedCharacters = documents.compactMap { document -> GRCharacter? in
                    return self.parseCharacterFromDocument(document)
                }.filter { character in
                    // space 주소가 아닌 캐릭터만 포함 (삭제된 캐릭터 제외)
                    return character.status.address != "space"
                }
                
                // 메인 스레드에서 UI 업데이트
                DispatchQueue.main.async {
                    self.characters = updatedCharacters
                    self.isDataLoaded = true // 데이터 로드 완료
                    
                    print("✅ 캐릭터 목록 업데이트 완료: \(updatedCharacters.count)개")
                    
                    // 캐릭터 수와 해제 슬롯 수 체크 로직
                    if self.unlockCount <= self.sortedCharacters.count && self.firstAlert {
                        self.showingNotEnoughAlert = true
                    }
                    
                    if self.sortedCharacters.count > self.unlockCount {
                        self.showingErrorAlert = true
                    }
                }
            }
    }
    
    /// Firestore 문서에서 GRCharacter 객체로 파싱
    private func parseCharacterFromDocument(_ document: DocumentSnapshot) -> GRCharacter? {
        let data = document.data() ?? [:]
        let characterID = document.documentID
        
        // 기본 캐릭터 정보 파싱
        let speciesRaw = data["species"] as? String ?? ""
        let species = PetSpecies(rawValue: speciesRaw) ?? .CatLion
        let name = data["name"] as? String ?? "이름 없음"
        let imageName = data["image"] as? String ?? ""
        let createdAtTimestamp = data["createdAt"] as? Timestamp
        let createdAt = createdAtTimestamp?.dateValue() ?? Date()
        
        // 상태 정보 파싱
        let statusData = data["status"] as? [String: Any] ?? [:]
        let level = statusData["level"] as? Int ?? 1
        let exp = statusData["exp"] as? Int ?? 0
        let expToNextLevel = statusData["expToNextLevel"] as? Int ?? 100
        let phaseRaw = statusData["phase"] as? String ?? ""
        let phase = CharacterPhase(rawValue: phaseRaw) ?? .infant
        let satiety = statusData["satiety"] as? Int ?? 50
        let stamina = statusData["stamina"] as? Int ?? 50
        let activity = statusData["activity"] as? Int ?? 50
        let affection = statusData["affection"] as? Int ?? 50
        let affectionCycle = statusData["affectionCycle"] as? Int ?? 0
        let healthy = statusData["healthy"] as? Int ?? 50
        let clean = statusData["clean"] as? Int ?? 50
        let address = statusData["address"] as? String ?? "userHome"
        let birthDateTimestamp = statusData["birthDate"] as? Timestamp
        let birthDate = birthDateTimestamp?.dateValue() ?? Date()
        let appearance = statusData["appearance"] as? [String: String] ?? [:]
        
        let status = GRCharacterStatus(
            level: level,
            exp: exp,
            expToNextLevel: expToNextLevel,
            phase: phase,
            satiety: satiety,
            stamina: stamina,
            activity: activity,
            affection: affection,
            affectionCycle: affectionCycle,
            healthy: healthy,
            clean: clean,
            address: address,
            birthDate: birthDate,
            appearance: appearance
        )
        
        return GRCharacter(
            id: characterID,
            species: species,
            name: name,
            imageName: imageName,
            birthDate: birthDate,
            createdAt: createdAt,
            status: status
        )
    }
    // FIXME: - End
    
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

// 로딩 화면 컴포넌트
struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            Text("데이터 로딩 중...")
                .font(.headline)
        }
    }
}
