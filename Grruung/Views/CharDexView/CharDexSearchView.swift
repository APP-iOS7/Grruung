//
//  CharDexSearchView.swift
//  Grruung
//
//  Created by mwpark on 5/12/25.
//

import SwiftUI

struct CharDexSearchView: View {
    private let maxDexCount: Int = 20
    @State private var unlockCount: Int = 5
    @State private var sortType: SortType = .original
    @State private var showingErrorAlert = false
    // 검색 내용
    @State private var searchText = ""
    // 검색되는 캐릭터들
    let searchCharacters: [GRCharacter]
    
    enum SortType {
        case original, createdAscending, createdDescending, alphabet
    }
    
    private var filteredCharacters: [GRCharacter] {
        let sorted: [GRCharacter]
        switch sortType {
        case .original:
            sorted = searchCharacters
        case .createdAscending:
            sorted = searchCharacters.sorted { $0.birthDate > $1.birthDate }
        case .createdDescending:
            sorted = searchCharacters.sorted { $0.birthDate < $1.birthDate }
        case .alphabet:
            sorted = searchCharacters.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        }
        
        if searchText.isEmpty {
            return sorted
        } else {
            return sorted.filter {
                // 대소문자 구분 없이, 사용자의 언어 설정(로케일)을 고려해서 필터링
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                TextField("캐릭터 이름을 입력하세요", text: $searchText)
                    .padding()
                    .background(Color(.systemGray6))
                    .frame(height: 32)
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
                    .overlay(
                        HStack {
                            Spacer()
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                }, label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                })
                                .padding(.trailing, 20)
                            }
                        }
                    )
                
                HStack {
                    if filteredCharacters.count == 0 {
                        Text("해당 이름을 가진 캐릭터는 존재하지 않습니다.")
                            .padding(.top, 16)
                    }
                }
                .frame(maxWidth: .infinity)
                .font(.title3)
                
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Array(filteredCharacters.enumerated()), id: \.element.id) { index, character in
                        NavigationLink(destination: DetailView(character: character)) {
                            characterSlot(character)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("캐릭터 검색")
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
                        Label("정렬", systemImage: "line.3.horizontal")
                    }
                }
            }
            .alert("에러 발생", isPresented: $showingErrorAlert) {
                Button("확인", role: .cancel) {}
            } message: {
                Text("알 수 없는 에러가 발생하였습니다!")
            }
        }
    }
    
    private func characterSlot(_ character: GRCharacter) -> some View {
        VStack(alignment: .center) {
            ZStack {
                Image(systemName: character.imageName)
                    .resizable()
                    .frame(width: 100, height: 100, alignment: .center)
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.black)
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
}

#Preview {
    CharDexSearchView(searchCharacters: [
        GRCharacter(species: PetSpecies.CatLion, name: "구릉이1", imageName: "hare",
                    birthDate: Calendar.current.date(from: DateComponents(year: 2023, month: 12, day: 25))!),
        GRCharacter(species: PetSpecies.CatLion, name: "구릉이2", imageName: "hare",
                    birthDate: Calendar.current.date(from: DateComponents(year: 2023, month: 12, day: 25))!),
        GRCharacter(species: PetSpecies.CatLion, name: "구릉이3", imageName: "hare",
                    birthDate: Calendar.current.date(from: DateComponents(year: 2010, month: 12, day: 13))!),
        GRCharacter(species: PetSpecies.CatLion, name: "구르릉", imageName: "hare",
                    birthDate: Calendar.current.date(from: DateComponents(year: 2023, month: 2, day: 13))!),
        GRCharacter(species: PetSpecies.CatLion, name: "구르릉", imageName: "hare",
                    birthDate: Calendar.current.date(from: DateComponents(year: 2000, month: 2, day: 13))!),
    ])
}
