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
    // 생성 가능한 최대 캐릭터 수
    private let maxDexCount: Int = 10
    // 초기 생성 가능한 캐릭터 수
    @State private var unlockCount: Int = 0
    // 정렬 타입 변수
    @State private var sortType: SortType = .original
    // 언락 티켓 갯수
    @State private var unlockTicketCount: Int = 0
    // 잠금 그리드 클릭 위치
    @State private var selectedLockedIndex: Int = -1
    @State private var realUserId: String = ""
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var userInventoryViewModel: UserInventoryViewModel
    @EnvironmentObject private var characterDexViewModel: CharacterDexViewModel
    @EnvironmentObject private var characterDetailViewModel: CharacterDetailViewModel
    // 잠금해제 alert 변수
    @State private var showingUnlockAlert = false
    // 생성 가능한 캐릭터 수가 부족한 경우 alert 변수
    @State private var showingNotEnoughAlert = false
    // 잠금 해제 티켓의 수가 부족한 경우 alert 변수
    @State private var showingNotEnoughTicketAlert = false
    // 초기 슬롯 해제 alert
    @State private var firstAlert = true
    // 알 수 없는 에러 alert
    @State private var showingErrorAlert = false
    @Environment(\.dismiss) var dismiss

    @State private var isLoading: Bool = false

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    // 임시 데이터(테스트 용)
    @State private var garaCharacters: [GRCharacter] = [
        GRCharacter(species: PetSpecies.CatLion, name: "구릉이1", imageName: "hare",
                    birthDate: Calendar.current.date(from: DateComponents(year: 2023, month: 12, day: 25))!, createdAt: Date(), status: GRCharacterStatus(address: "userHome"))
    ].filter { !($0.status.address == "space") }
    
    // 캐릭터 데이터
    @State private var realCharacters: [GRCharacter] = []
        .filter { !($0.status.address == "space") }
    
    private enum SortType {
        case original
        case createdAscending
        case createdDescending
        case alphabet
    }
    
    // 현재 캐릭터 슬롯 정렬 프로퍼티
    private var sortedCharacterSlots: [GRCharacter] {
        switch sortType {
        case .original:
            return realCharacters
        case .createdAscending:
            return realCharacters.sorted { $0.birthDate > $1.birthDate }
        case .createdDescending:
            return realCharacters.sorted { $0.birthDate < $1.birthDate }
        case .alphabet:
            return realCharacters.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        }
    }
    
    // 전체 슬롯 계산 (캐릭터 + 추가 가능한 슬롯 + 잠금 슬롯)
    private var characterSlots: [GRCharacter] {
        let hasCharacters = sortedCharacterSlots
        
        // 생성 가능한 슬롯 수 = unlockCount - 현재 캐릭터 수
        let addableCount = max(0, unlockCount - hasCharacters.count)
        
        // "plus" 슬롯 추가
        let plusCharacters = (0..<addableCount).map { index in
            GRCharacter(id: "plus-\(index)", species: .Undefined, name: "", imageName: "plus", birthDate: Date(), createdAt: Date())
        }
        
        // 현재까지 채워진 슬롯 수 = 캐릭터 + plus
        let filledCount = hasCharacters.count + plusCharacters.count
        
        // 나머지 잠금 슬롯 수
        let lockedCount = max(0, maxDexCount - filledCount)
        let lockedCharacters = (0..<lockedCount).map { index in
            GRCharacter(id: "lock-\(index)", species: .Undefined, name: "", imageName: "lock.fill", birthDate: Date(), createdAt: Date())
        }
        
        return hasCharacters + plusCharacters + lockedCharacters
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if !characterDexViewModel.isLoading {
                    HStack {
                        Text("\(realCharacters.count)")
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
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Array(characterSlots.enumerated()), id: \.offset) { index, character in
                            if character.imageName == "lock.fill" {
                                lockSlot(at: index)
                            } else if character.imageName == "plus" {
                                addSlot
                            } else {
                                NavigationLink(destination: {
                                    CharacterDetailView(characterUUID: character.id)
                                }) {
                                    characterSlot(character)
                                }
                            }
                        }
                    }
                    .padding()
                } else {
                    ProgressView("데이터 로딩중...")
                }
            }
//            .navigationTitle("캐릭터 동산")
            .scrollContentBackground(.hidden) // 기본 배경을 숨기고
            .background(
                LinearGradient(colors: [
                    Color(GRColor.mainColor1_1),
                    Color(GRColor.mainColor1_2)
                ],
                               startPoint: .top, endPoint: .bottom)
            ) // 원하는 색상 지정
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: CharDexSearchView(searchCharacters: realCharacters)) {
                        Image(systemName: "magnifyingglass")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
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
            }
            // 슬롯 해제 Alert
            .alert("슬롯을 해제합니다.", isPresented: $showingUnlockAlert) {
                Button("해제", role: .destructive) {
                    if unlockTicketCount <= 0 {
                        showingNotEnoughTicketAlert = true
                    } else {
                        if unlockCount < maxDexCount {
                            if let item = userInventoryViewModel.inventories.first(where: { $0.userItemName == "동산 잠금해제x1" }) {
                                unlockCount += 1
                                unlockTicketCount -= 1
                                characterDexViewModel.updateCharDex(
                                    userId: realUserId,
                                    unlockCount: unlockCount,
                                    unlockTicketCount: unlockTicketCount,
                                    selectedLockedIndex: selectedLockedIndex
                                )
                                userInventoryViewModel.updateItemQuantity(userId: realUserId, item: item, newQuantity: unlockTicketCount)
                            } else {
                                showingErrorAlert = true
                            }
                        }
                    }
                }
                Button("취소", role: .cancel) {}
            }
            // 캐릭터 슬롯이 부족한 경우 Alert
            .alert("슬롯을 해제하면 더 많은 캐릭터를 추가할 수 있습니다.", isPresented: $showingNotEnoughAlert) {
                Button("확인", role: .cancel) {
                    firstAlert = false
                }
            }
            // 티켓 부족 Alert
            .alert("잠금해제 티켓의 수가 부족합니다", isPresented: $showingNotEnoughTicketAlert) {
                Button("확인", role: .cancel) {}
            }
            // 에러 Alert
            .alert("에러 발생", isPresented: $showingErrorAlert) {
                Button("확인", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("알 수 없는 에러가 발생하였습니다!")
            }
            .onAppear {
                Task {
                    // 유저 Id 가져오기
                    realUserId = authService.currentUserUID.isEmpty ? "23456" : authService.currentUserUID
                    // 캐릭터 데이터 가져오기
                    await fetchCharacters(userId: realUserId)
                    // 인벤토리 데이터 가져오기
                    try await userInventoryViewModel.fetchInventories(userId: realUserId)
                    // 동산 데이터 가져오기
                    if !characterDexViewModel.isLoading {
                        try await characterDexViewModel.fetchCharDex(userId: realUserId)
                        
                        // 인벤토리에서 티켓 갯수 가져와서 저장 후 불러오기
                        if let ticket = userInventoryViewModel.inventories.first(where: { $0.userItemName == "동산 잠금해제x1" }) {
                            characterDexViewModel.updateCharDex(userId: realUserId, unlockCount: characterDexViewModel.unlockCount, unlockTicketCount: ticket.userItemQuantity, selectedLockedIndex: characterDexViewModel.selectedLockedIndex)
                            try await characterDexViewModel.fetchCharDex(userId: realUserId)
                        }
                        unlockTicketCount = characterDexViewModel.unlockTicketCount
                        unlockCount = characterDexViewModel.unlockCount
                        selectedLockedIndex = characterDexViewModel.selectedLockedIndex
                        
                        // 캐릭터 목록 업데이트
                        await loadCharacters()
                    }
                    
                    // 캐릭터 수와 해제 슬롯 수가 같은 경우 안내
                    if unlockCount == realCharacters.count && firstAlert {
                        showingNotEnoughAlert = true
                    }
                    
                    // 캐릭터 수가 해제 슬롯 수보다 많으면 에러
                    if realCharacters.count > unlockCount {
                        showingErrorAlert = true
                    }
                }
                
                // 알림 리스너 설정
                NotificationCenter.default.addObserver(
                    forName: NSNotification.Name("CharacterAddressChanged"),
                    object: nil,
                    queue: .main
                ) { notification in
                    Task {
                        // 캐릭터 목록 새로고침
                        await self.loadCharacters()
                    }
                }
            }
            // 뷰가 사라질 때 알림 리스너 제거
            .onDisappear {
                NotificationCenter.default.removeObserver(self)
            }
        }
    }
    
    // 캐릭터 슬롯
    fileprivate func characterSlot(_ character: GRCharacter) -> some View {
        VStack(alignment: .center) {
            ZStack {
                // 이미지 부분 수정
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
        .cornerRadius(UIConstants.cornerRadius)
        .foregroundColor(.gray)
        .padding(.bottom, 16)
    }
    
    // 잠겨있는 슬롯
    private func lockSlot(at index: Int) -> some View {
        GeometryReader { geo in
            let yPosition = geo.frame(in: .global).minY
            let yOffset = -abs((yPosition.truncatingRemainder(dividingBy: 120)) - 60) / 5
            
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
                        .cornerRadius(UIConstants.cornerRadius)
                }
                .padding(.bottom, 16)
                .offset(y: yOffset)
            }
            .buttonStyle(.plain)
        }
        .frame(height: 180)
    }
    
    // 추가할 수 있는 슬롯(남은 슬롯 표시)
    private var addSlot: some View {
        GeometryReader { geo in
            let yPosition = geo.frame(in: .global).minY
            let yOffset = -abs((yPosition.truncatingRemainder(dividingBy: 120)) - 60) / 5
            
            VStack {
                Image(systemName: "plus")
                    .scaledToFit()
                    .font(.system(size: 60))
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
                    .background(Color.brown.opacity(0.5))
                    .cornerRadius(UIConstants.cornerRadius)
            }
            .padding(.bottom, 16)
            .offset(y: yOffset)
        }
        .frame(height: 180)
    }
    
    func fetchCharacters(userId: String) async {
        let db = Firestore.firestore()
        
        do {
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("characters")
                .getDocuments()
            
            var tempCharacters: [GRCharacter] = []
            
            for document in snapshot.documents {
                let data = document.data()
                
                // 기본값 정의
                let species = PetSpecies(rawValue: data["species"] as? String ?? "") ?? .Undefined
                let name = data["name"] as? String ?? "이름 없음"
                let imageName = data["imageName"] as? String ?? ""
                
                // status 맵 파싱
                var level = 1
                var exp = 0
                var expToNextLevel = 100
                var phase: CharacterPhase = .egg
                var address = "동산"
                var satiety = 100
                var stamina = 100
                var activity = 100
                var affection = 0
                var affectionCycle = 0
                var healthy = 50
                var clean = 50
                var appearance: [String: String] = [:]
                var birthDate = Date()
                
                if let statusMap = data["status"] as? [String: Any] {
                    level = statusMap["level"] as? Int ?? 1
                    exp = statusMap["exp"] as? Int ?? 0
                    expToNextLevel = statusMap["expToNextLevel"] as? Int ?? 100
                    phase = CharacterPhase(rawValue: statusMap["phase"] as? String ?? "") ?? .egg
                    address = statusMap["address"] as? String ?? "동산"
                    satiety = statusMap["satiety"] as? Int ?? 100
                    stamina = statusMap["stamina"] as? Int ?? 100
                    activity = statusMap["activity"] as? Int ?? 100
                    affection = statusMap["affection"] as? Int ?? 0
                    affectionCycle = statusMap["affectionCycle"] as? Int ?? 0
                    healthy = statusMap["healthy"] as? Int ?? 50
                    clean = statusMap["clean"] as? Int ?? 50
                    appearance = statusMap["appearance"] as? [String: String] ?? [:]
                    birthDate = (statusMap["birthDate"] as? Timestamp)?.dateValue() ?? Date()
                }
                
                let character = GRCharacter(
                    id: document.documentID,
                    species: species,
                    name: name,
                    imageName: imageName,
                    birthDate: birthDate,
                    status: GRCharacterStatus(
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
                )
                
                tempCharacters.append(character)
            }
            
            // UI 업데이트는 메인 스레드에서!
            await MainActor.run {
                self.realCharacters = tempCharacters
            }
        } catch {
            print("문서 불러오기 실패: \(error.localizedDescription)")
        }
    }
    
    private func loadCharacters() async {
        print("[CharDexView] 캐릭터 목록 로드 시작")
        await MainActor.run {
            isLoading = true
        }
        
        // Firebase에서 현재 사용자의 캐릭터 목록 가져오기
        do {
            let userHome = await fetchCharactersWithAddress(address: "userHome")
            let paradise = await fetchCharactersWithAddress(address: "paradise")
            
            // space는 제외 (삭제된 캐릭터)
            let allCharacters = userHome + paradise
            
            print("[CharDexView] 총 \(allCharacters.count)개 캐릭터 로드 완료 (Home: \(userHome.count), Paradise: \(paradise.count))")
            
            await MainActor.run {
                self.realCharacters = allCharacters.filter { !($0.status.address == "space") }
                self.isLoading = false
            }
        } catch {
            print("[CharDexView] 캐릭터 로드 중 오류 발생: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }

    private func fetchCharactersWithAddress(address: String) async -> [GRCharacter] {
        return await withCheckedContinuation { continuation in
            FirebaseService.shared.findCharactersByAddress(address: address) { characters, error in
                if let error = error {
                    print("[CharDexView] 주소 \(address)로 캐릭터 검색 실패: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                } else {
                    continuation.resume(returning: characters ?? [])
                }
            }
        }
    }
}

// 날짜 -> 00월 00일 포맷으로 변경 함수
func formatToMonthDay(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM월 dd일"
    return formatter.string(from: date)
}

// 나이 계산 함수
func calculateAge(_ birthDate: Date) -> Int {
    let calendar = Calendar.current
    let now = Date()
    
    let age = calendar.dateComponents([.year], from: birthDate, to: now).year ?? 0
    
    if let birthdayThisYear = calendar.date(bySetting: .year, value: calendar.component(.year, from: now), of: birthDate),
       now < birthdayThisYear {
        return age - 1
    }
    
    return age
}



#Preview {
    CharDexView()
        .environmentObject(CharacterDexViewModel())
        .environmentObject(CharacterDetailViewModel())
        .environmentObject(UserInventoryViewModel())
        .environmentObject(AuthService())
}
