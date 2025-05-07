//
//  CharDexView.swift
//  Grruung
//
//  Created by mwpark on 5/2/25.
//

import SwiftUI

struct CharDexView: View {
    private let maxDexCount: Int = 20
    @State private var isFull: Bool = false

    // 더미 데이터
    let garaCharacter: [GRCharacter] = [
        GRCharacter(species: "고양이사자", name: "구르릉", imageName: "hare"),
        GRCharacter(species: "고양이사자", name: "구르릉", imageName: "hare",
            birthDate: Calendar.current.date(from: DateComponents(year: 2023, month: 12, day: 25))!),
        GRCharacter(species: "고양이사자", name: "구르릉", imageName: "hare", birthDate:Calendar.current.date(from: DateComponents(year: 2010, month: 12, day: 13))!),
        GRCharacter(species: "고양이사자", name: "구르릉", imageName: "hare",
            birthDate:Calendar.current.date(from: DateComponents(year: 2023, month: 2, day: 13))!),
        GRCharacter(species: "고양이사자", name: "구르릉", imageName: "hare"),
        GRCharacter(species: "고양이사자", name: "구르릉", imageName: "hare"),
    ]
    
    // 전체 캐릭터 슬롯
    private var characterList: [GRCharacter] {
        var unlockedCharacters = garaCharacter
        let lockedCount = maxDexCount - unlockedCharacters.count - 1
        let extraCharacter = GRCharacter(species: "", name: "", imageName: "plus")
        
        if lockedCount > 0 {
            unlockedCharacters.append(extraCharacter)
            
            // Array repeat 썼더니 같은 인스턴스로 인식해서 map으로 변경
            let lockedCharacters = (0..<lockedCount).map { _ in
                GRCharacter(species: "", name: "", imageName: "lock.fill")
            }
            return unlockedCharacters + lockedCharacters
        } else {
        }
        return unlockedCharacters
    }
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
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
                        } else if character.imageName == "plus" {
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
        }
    }
    
    func formatToMonthDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM월 dd일"
        return formatter.string(from: date)
    }
    
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
}

#Preview {
    CharDexView()
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
            
            Text(character.species)
                .font(.title)
                .foregroundStyle(.gray)
            
            Spacer()
        }
        .navigationTitle(character.name)
        .padding()
    }
}
