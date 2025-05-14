//
//  userInventoryView.swift
//  Grruung
//
//  Created by mwpark on 5/14/25.
//

import SwiftUI

struct userInventoryView: View {
    let columns = [
        GridItem(.flexible())
    ]
    
    let garaItems: [GRUserInventory] = [
        GRUserInventory(
            userItemNumber: 1,
            userItemName: "비타민 젤리",
            userItemType: .consumable,
            userItemImage: "pill",
            userIteamQuantity: Int.random(in: 1...10),
            userItemDescription: "피로 회복에 좋은 비타민 젤리예요.",
            userItemCategory: .drug,
            purchasedAt: Date(timeIntervalSinceNow: -Double.random(in: 1...60) * 86400)
        ),
        GRUserInventory(
            userItemNumber: 2,
            userItemName: "딸랑이 인형",
            userItemType: .permanent,
            userItemImage: "soccerball",
            userIteamQuantity: Int.random(in: 1...10),
            userItemDescription: "지루할 틈이 없어요! 딸랑딸랑 장난감.",
            userItemCategory: .toy,
            purchasedAt: Date(timeIntervalSinceNow: -Double.random(in: 1...60) * 86400)
        ),
        GRUserInventory(
            userItemNumber: 3,
            userItemName: "감기약",
            userItemType: .consumable,
            userItemImage: "pill",
            userIteamQuantity: Int.random(in: 1...10),
            userItemDescription: "달달한 감기약이에요.",
            userItemCategory: .drug,
            purchasedAt: Date(timeIntervalSinceNow: -Double.random(in: 1...60) * 86400)
        ),
        GRUserInventory(
            userItemNumber: 4,
            userItemName: "알록달록 공",
            userItemType: .permanent,
            userItemImage: "soccerball",
            userIteamQuantity: Int.random(in: 1...10),
            userItemDescription: "놀기 좋아하는 펫의 최고의 선택.",
            userItemCategory: .toy,
            purchasedAt: Date(timeIntervalSinceNow: -Double.random(in: 1...60) * 86400)
        ),
        GRUserInventory(
            userItemNumber: 5,
            userItemName: "에너지 드링크",
            userItemType: .consumable,
            userItemImage: "pill",
            userIteamQuantity: Int.random(in: 1...10),
            userItemDescription: "타우린이 많이 들어있어요.",
            userItemCategory: .drug,
            purchasedAt: Date(timeIntervalSinceNow: -Double.random(in: 1...60) * 86400)
        )
    ]
    var body: some View {
        ScrollView {
            Text("가방")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            LazyVGrid(columns: columns) {
                ForEach(garaItems, id: \.userItemNumber) { item in
                    HStack {
                        Image(systemName: item.userItemImage)
                            .resizable()
                            .frame(width: 60, height: 60)
                            .aspectRatio(contentMode: .fit)
                            .overlay {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(lineWidth: 1)
                                    .background(Color.gray.opacity(0.3))
                            }
                            .padding(.trailing, 8)
                        
                        VStack(alignment: .leading) {
                            Text(item.userItemName)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(item.userItemDescription)
                                .lineLimit(1)
                            Text("보유: \(item.userIteamQuantity)")
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(lineWidth: 2)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }
}

#Preview {
    userInventoryView()
}
