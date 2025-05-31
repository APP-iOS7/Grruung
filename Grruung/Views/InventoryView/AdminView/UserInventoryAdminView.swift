//
//  userInventoryAdminView.swift
//  Grruung
//
//  Created by mwpark on 5/20/25.
//

import SwiftUI

struct UserInventoryAdminView: View {
    private let garaUserId = "23456"
    
    @State private var itemNumber: String = UUID().uuidString
    @State private var itemName: String = ""
    @State private var itemImage: String = ""
    @State private var itemType: ItemType = .consumable
    @State private var itemCategory: ItemCategory = .drug
    @State private var itemDescription: String = ""
    @State private var itemEffectDescription: String = ""
    @State private var itemQuantity: String = ""
    @State private var isOn2: Bool = false
    @StateObject private var userInventoryViewModel = UserInventoryViewModel()
    var body: some View {
        ScrollView {
            Text("인벤토리 아이템 생성기")
                .font(.largeTitle)
                .bold()
            
            TextField("아이템 번호", text: $itemNumber)
                .textFieldStyle(.roundedBorder)
                .padding()
            TextField("아이템 이름", text: $itemName)
                .textFieldStyle(.roundedBorder)
                .padding()
            TextField("아이템 설명", text: $itemDescription)
                .textFieldStyle(.roundedBorder)
                .padding()
            TextEditor(text: $itemEffectDescription)
                .frame(height: 150)
                .border(Color.gray)
                .padding()
            TextField("아이템 수량", text: $itemQuantity)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            Picker("Choose a category", selection: $itemCategory) {
                ForEach(ItemCategory.allCases, id: \.self) { category in
                    Text(category.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            .cornerRadius(15)
            .padding()
            
            HStack {
                Spacer()
                Text("소모품")
                Toggle("", isOn: $isOn2)
                    .labelsHidden() // <- 레이블 완전히 숨기기
                    .toggleStyle(SwitchToggleStyle()) // 기본 스위치 스타일
                Text("영구")
                Spacer()
            }
            .padding()
            Button(action: {
                Task {
                    let item = GRUserInventory(userItemNumber: itemNumber, userItemName: itemName, userItemType: isOn2 == false ? .consumable : .permanent, userItemImage: itemCategory == .drug ? "pill" : "soccerball", userIteamQuantity: Int(itemQuantity) ?? -1, userItemDescription: itemDescription, userItemEffectDescription: itemEffectDescription, userItemCategory: itemCategory, purchasedAt: Date()
                    )
                    
                    await userInventoryViewModel.saveInventory(userId: garaUserId, inventory: item)
                    
                    await MainActor.run {
                        itemName = ""
                        itemDescription = ""
                        itemQuantity = ""
                        itemNumber = String(Int.random(in: 1...100))
                        isOn2 = false
                    }
                }
            }) {
                Text("아이템 추가")
                    .foregroundStyle(.red)
            }
        }
        .onAppear {
            if itemEffectDescription.isEmpty {
                itemEffectDescription = "아이템 효과 설명"
            }
        }
    }
}


#Preview {
    UserInventoryAdminView()
}
