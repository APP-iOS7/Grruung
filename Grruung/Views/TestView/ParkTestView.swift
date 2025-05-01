//
//  TestView.swift
//  Grruung
//
//  Created by NoelMacMini on 5/1/25.
//

import SwiftUI

struct ParkTestView: View {
    private let maxDexCount: Int = 10
    @State private var isFull: Bool = false
    
    // 더미 데이터
    let garaCharacter: [GRCharacter] = [
        GRCharacter(species: "고양이사자", name: "구르릉", imageName: "hare"),
        GRCharacter(species: "고양이사자", name: "구르릉", imageName: "hare"),
        GRCharacter(species: "고양이사자", name: "구르릉", imageName: "hare"),
        GRCharacter(species: "고양이사자", name: "구르릉", imageName: "hare"),
        GRCharacter(species: "고양이사자", name: "구르릉", imageName: "hare"),
    ]
    
    // 전체 캐릭터 슬롯
    private var characterList: [GRCharacter] {
        var unlockedCharacters = garaCharacter
        let lockedCount = maxDexCount - unlockedCharacters.count
        let extraCharacter = GRCharacter(species: "", name: "", imageName: "plus")
        
        if lockedCount > 0 {
            unlockedCharacters.append(extraCharacter)
            if lockedCount == 1 {
                return unlockedCharacters
            }
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
        GridItem(.flexible()),
        GridItem(.flexible())
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
                                    .foregroundStyle(.black)
                                    .frame(height: 180)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.black.opacity(0.3))
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
                                        .frame(height: 180)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.gray.opacity(0.5))
                                        .cornerRadius(10)
                                        .foregroundColor(.white)
                                    
                                    Text(character.name)
                                        .foregroundStyle(.black)
                                        .bold()
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Text("1살 (02월 14일 생)")
                                        .foregroundStyle(.gray)
                                        .font(.caption)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("캐릭터 도감")
        }
    }
}

#Preview {
    ParkTestView()
}

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
