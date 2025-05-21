//
//  CharDexView.swift
//  Grruung
//
//  Created by mwpark on 5/2/25.
//

import SwiftUI

struct CharDexView: View {
    // 생성 가능한 최대 캐릭터 수
    private let maxDexCount: Int = 20
    // 초기 생성 가능한 캐릭터 수
    @State private var unlockCount: Int = 5
    // 정렬 타입 변수
    @State private var sortType: SortType = .original
    // 잠금 해제 티켓의 수(테스트 용)
    @State private var unlockTicketCount: Int = 3
    // 잠금 그리드 클릭 위치
    @State private var selectedLockedIndex: Int? = nil
    
    // 잠금해제 alert 변수
    @State private var showingUnlockAlert = false
    // 생성 가능한 캐릭터 수가 부족한 경우 alert 변수
    @State private var showingNotEnoughAlert = false
    // 잠금 해제 티켓의 수가 부족한 경우 alert 변수
    @State private var showingNotEnoughTicketAlert = false
    
    @State private var firstAlert = true
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    // 임시 데이터(테스트 용)
    @State private var garaCharacters: [GRCharacter] = [
        GRCharacter(species: PetSpecies.CatLion, name: "구릉이1", imageName: "hare",
                    birthDate: Calendar.current.date(from: DateComponents(year: 2023, month: 12, day: 25))!, createdAt: Date()),
        GRCharacter(species: PetSpecies.CatLion, name: "구릉이2", imageName: "hare",
                    birthDate: Calendar.current.date(from: DateComponents(year: 2023, month: 12, day: 25))!, createdAt: Date()),
        GRCharacter(species: PetSpecies.CatLion, name: "구릉이3", imageName: "hare",
                    birthDate: Calendar.current.date(from: DateComponents(year: 2010, month: 12, day: 13))!, createdAt: Date()),
        GRCharacter(species: PetSpecies.CatLion, name: "구르릉", imageName: "hare",
                    birthDate: Calendar.current.date(from: DateComponents(year: 2023, month: 2, day: 13))!, createdAt: Date()),
        GRCharacter(species: PetSpecies.CatLion, name: "구르릉", imageName: "hare",
                    birthDate: Calendar.current.date(from: DateComponents(year: 2000, month: 2, day: 13))!, createdAt: Date()),
    ]
    
    enum SortType {
        case original
        case createdAscending
        case createdDescending
        case alphabet
    }
    
    // 현재 캐릭터 슬롯 정렬 프로퍼티
    var sortedCharacterSlots: [GRCharacter] {
        switch sortType {
        case .original:
            return garaCharacters
        case .createdAscending:
            return garaCharacters.sorted { $0.birthDate > $1.birthDate }
        case .createdDescending:
            return garaCharacters.sorted { $0.birthDate < $1.birthDate }
        case .alphabet:
            return garaCharacters.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        }
    }
    
    private var characterSlots: [GRCharacter] {
        let hasCharacters = sortedCharacterSlots
        
        // 생성 가능한 슬롯 수 = unlockCount - 현재 캐릭터 수
        let addableCount = max(0, unlockCount - hasCharacters.count)
        
        // "plus" 슬롯 추가
        let plusCharacters = (0..<addableCount).map { _ in
            GRCharacter(species: PetSpecies.Undefined, name: "", imageName: "plus", birthDate: Date(), createdAt: Date())
        }
        
        // 현재까지 채워진 슬롯 수 = 캐릭터 + plus
        let filledCount = hasCharacters.count + plusCharacters.count
        
        // 나머지 잠금 슬롯 수
        let lockedCount = max(0, maxDexCount - filledCount)
        let lockedCharacters = (0..<lockedCount).map { _ in
            GRCharacter(species: PetSpecies.Undefined, name: "", imageName: "lock.fill", birthDate: Date(), createdAt: Date())
        }
        
        return hasCharacters + plusCharacters + lockedCharacters
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                HStack {
                    Text("\(garaCharacters.count)")
                        .foregroundStyle(.yellow)
                    Text("/ \(maxDexCount) 수집")
                    
                }
                .frame(maxWidth: 180)
                .font(.title)
                .background(alignment: .center, content: {
                    Capsule()
                        .fill(Color.brown.opacity(0.5))
                })
                
                HStack {
                    if unlockTicketCount <= 0 {
                        Spacer()
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
                    ForEach(Array(characterSlots.enumerated()), id: \.element.id) { index, character in
                        if character.imageName == "lock.fill" {
                            lockSlot(at: index)
                        } else if character.imageName == "plus" {
                            addSlot
                        } else {
                            NavigationLink(destination: DetailView(character: character)) {
                                characterSlot(character)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("캐릭터 동산")
            .toolbar {
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
                        Label("정렬", systemImage: "arrow.up.arrow.down")
                    }
                }
            }
            .alert("슬롯을 해제합니다.", isPresented: $showingUnlockAlert) {
                Button("해제", role: .destructive) {
                    if unlockTicketCount <= 0 {
                        showingNotEnoughTicketAlert = true
                    } else {
                        if unlockCount < maxDexCount {
                            unlockCount += 1
                            unlockTicketCount -= 1
                        }
                    }
                    
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
            .onAppear {
                if unlockCount == garaCharacters.count && firstAlert {
                    showingNotEnoughAlert = true
                }
            }
        }
    }
    
    // 캐릭터 슬롯
    private func characterSlot(_ character: GRCharacter) -> some View {
        VStack(alignment: .center) {
            Image(systemName: character.imageName)
                .resizable()
                .frame(width: 100, height: 100, alignment: .center)
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(.black)
            
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
    private func lockSlot(at index: Int) -> some View {
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
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 16)
        }
        .buttonStyle(.plain)
    }
    
    // 추가할 수 있는 슬롯(남은 슬롯 표시)
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
}

// 임시 디테일 뷰
struct DetailView: View {
    var character: GRCharacter
    
    var body: some View {
        VStack {
            Image(systemName: character.imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .padding()
            
            Text(character.name)
                .font(.largeTitle)
                .bold()

            Text(character.species.rawValue)
                .font(.title)
                .foregroundStyle(.gray)
            
            Spacer()
        }
        .navigationTitle(character.name)
        .padding()
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
}
