//
//  CharDexView.swift
//  Grruung
//
//  Created by mwpark on 5/2/25.
//

import SwiftUI

struct CharDexView: View {
    // 최대 도감의 캐릭터 갯수
    private let maxDexCount: Int = 20
    // 정렬 상태
    @State private var sortType: SortType = .original
    
    // 그리드 레이아웃
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    // 더미 데이터(테스트용)
    let garaCharacter: [GRCharacter] = [
        GRCharacter(species: "고양이사자", name: "구릉이1", imageName: "hare"),
        GRCharacter(species: "고양이사자", name: "구릉이2", imageName: "hare",
                    birthDate: Calendar.current.date(from: DateComponents(year: 2023, month: 12, day: 25))!),
        GRCharacter(species: "고양이사자", name: "구릉이3", imageName: "hare", birthDate:Calendar.current.date(from: DateComponents(year: 2010, month: 12, day: 13))!),
        GRCharacter(species: "고양이사자", name: "구르릉", imageName: "hare",
                    birthDate:Calendar.current.date(from: DateComponents(year: 2023, month: 2, day: 13))!),
        GRCharacter(species: "고양이사자", name: "구릉이4", imageName: "hare"),
        GRCharacter(species: "고양이사자", name: "구릉이5", imageName: "hare"),
    ]
    
    // 정렬 종류
    enum SortType {
        case original
        case createdAscending
        case createdDescending
        case alphabet
    }
    // 데이터 정렬 연산 프로퍼티
    var sortedCharacterList: [GRCharacter] {
        switch sortType {
        case .original:
            return garaCharacter
        case .createdAscending:
            return garaCharacter.sorted { $0.birthDate > $1.birthDate }
        case .createdDescending:
            return garaCharacter.sorted { $0.birthDate < $1.birthDate }
        case .alphabet:
            return garaCharacter.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        }
    }
    
    // 전체 캐릭터 슬롯
    private var characterList: [GRCharacter] {
        var unlockedCharacters = sortedCharacterList
        let lockedCount = maxDexCount - unlockedCharacters.count - 1
        let extraCharacter = GRCharacter(species: "", name: "", imageName: "plus")
        
        if lockedCount > 0 {
            unlockedCharacters.append(extraCharacter)
            
            // Array repeat 썼더니 같은 인스턴스로 인식해서 map으로 변경
            let lockedCharacters = (0..<lockedCount).map { _ in
                GRCharacter(species: "", name: "", imageName: "lock.fill")
            }
            return unlockedCharacters + lockedCharacters
        } else if lockedCount == 0 {
            unlockedCharacters.append(extraCharacter)
            return unlockedCharacters
        } else {
            
        }
        return unlockedCharacters
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(characterList, id: \.id) { character in
                        if character.imageName == "lock.fill" {
                            // 잠긴 슬롯
                            VStack {
                                Image(systemName: character.imageName)
                                    .scaledToFit()
                                    .font(.system(size: 60))
                                    .foregroundStyle(.black)
                                    .frame(height: 180)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.black.opacity(0.5))
                                    .cornerRadius(10)
                                    .foregroundColor(.gray)
                                
                                Text("잠금")
                                    .foregroundStyle(.black)
                                    .bold()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text(" ")
                                    .foregroundStyle(.gray)
                                    .font(.caption)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.bottom, 16)
                        } else if character.imageName == "plus" {
                            // 추가할 수 있음을 나타내는 표시
                            VStack {
                                Image(systemName: character.imageName)
                                    .scaledToFit()
                                    .font(.system(size: 60))
                                    .foregroundStyle(.black)
                                    .frame(height: 180)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(10)
                                    .foregroundColor(.gray)
                                
                                Text(" ")
                                    .foregroundStyle(.black)
                                    .bold()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text(" ")
                                    .foregroundStyle(.gray)
                                    .font(.caption)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.bottom, 16)
                        } else {
                            // 보유한 캐릭터 슬롯
                            NavigationLink(destination: DetailView(character: character)) {
                                VStack {
                                    Image(systemName: character.imageName)
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundStyle(.black)
                                        .frame(height: 180)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.black.opacity(0.2))
                                        .cornerRadius(10)
                                        .foregroundColor(.gray)
                                    
                                    Text(character.name)
                                        .foregroundStyle(.black)
                                        .bold()
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Text("\(calculateAge(character.birthDate)) 살 (\(formatToMonthDay(character.birthDate)) 생)")
                                        .foregroundStyle(.gray)
                                        .font(.caption)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.bottom, 16)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("캐릭터 도감")
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
        }
    }
    
}

// 임시 디테일 뷰(테스트 용)
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
            
            Text(character.species)
                .font(.title)
                .foregroundStyle(.gray)
            
            Spacer()
        }
        .navigationTitle(character.name)
        .padding()
    }
}

// Date타입을 00월 00일 포맷으로 리턴하는 함수
func formatToMonthDay(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM월 dd일"
    return formatter.string(from: date)
}

// 나이를 계산하는 함수
func calculateAge(_ birthDate: Date) -> Int {
    let calendar = Calendar.current
    let now = Date()
    
    let age = calendar.dateComponents([.year], from: birthDate, to: now).year ?? 0
    
    // 생일이 안 지났으면 1살 빼기
    if let birthdayThisYear = calendar.date(bySetting: .year, value: calendar.component(.year, from: now), of: birthDate),
       now < birthdayThisYear {
        return age - 1
    }
    
    return age
}

#Preview {
    CharDexView()
}
