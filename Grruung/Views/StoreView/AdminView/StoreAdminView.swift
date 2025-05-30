//
//  StoreAdminView.swift
//  Grruung
//
//  Created by mwpark on 5/29/25.
//

import SwiftUI

struct StoreAdminView: View {
    @State private var itemNumber: String = UUID().uuidString
    @State private var itemName: String = ""
    @State private var itemImage: String = ""
    @State private var itemType: ItemType = .consumable
    @State private var itemCategory: ItemCategory = .drug
    @State private var itemDescription: String = ""
    @State private var itemEffectDescription: String = ""
    @State private var limitedQuantity: String = ""
    @State private var itemPrice: String = ""
    @State private var itemCurrencyType: ItemCurrencyType = .gold
    @State private var itemTag: ItemTag = .normal
    
    @StateObject private var userInventoryViewModel = UserInventoryViewModel()
    
    var body: some View {
        ScrollView {
            Text("아이템 생성기")
                .font(.largeTitle)
                .bold()
            
            TextField("아이템 번호를 입력하세요.", text: $itemNumber)
                .textFieldStyle(.roundedBorder)
                .padding()
            TextField("아이템 이름을 입력하세요.", text: $itemName)
                .textFieldStyle(.roundedBorder)
                .padding()
            TextField("아이템 이미지 이름을 입력하세요.", text: $itemImage)
                .textFieldStyle(.roundedBorder)
                .padding()
            TextField("아이템 설명을 입력하세요.", text: $itemDescription)
                .textFieldStyle(.roundedBorder)
                .padding()
            TextEditor(text: $itemEffectDescription)
                .frame(height: 150)
                .border(Color.gray)
                .padding()
            TextField("아이템 한정 수량", text: $limitedQuantity)
                .textFieldStyle(.roundedBorder)
                .padding()
            TextField("아이템 가격을 입력하세요.", text: $itemPrice)
                .textFieldStyle(.roundedBorder)
                .padding()
            Picker("Choose a category", selection: $itemCurrencyType) {
                ForEach(ItemCurrencyType.allCases, id: \.self) { currency in
                    Text(currency.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            .cornerRadius(15)
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
            
            Picker("Choose a item tag", selection: $itemTag) {
                ForEach(ItemTag.allCases, id: \.self) { itemTag in
                    Text(itemTag.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            .cornerRadius(15)
            .padding()
            
            Picker("Choose a item type", selection: $itemType) {
                ForEach(ItemType.allCases, id: \.self) { itemType in
                    Text(itemType.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            .cornerRadius(15)
            .padding()
            
            Button(action: {
                let item = GRStoreItem(
                    itemName: itemName, itemTarget: .Undefined, itemType: itemType, itemImage: itemImage, itemQuantity: 0, limitedQuantity: Int(limitedQuantity) ?? 0, purchasedQuantity: 0, itemPrice: Int(itemPrice) ?? 0, itemCurrencyType: itemCurrencyType, itemDescription: itemDescription, itemEffectDescription: itemEffectDescription, itemTag: itemTag, itemCategory: itemCategory, isItemOwned: false, bgColor: .blue.opacity(0.4))
                Task {
                    await MainActor.run {
                        itemNumber = UUID().uuidString
                        itemName = ""
                        itemDescription = ""
                        itemEffectDescription = ""
                    }
                }
            }) {
                Text("아이템 추가")
                    .foregroundStyle(.red)
            }
        }
        .onAppear {
            if itemEffectDescription.isEmpty {
                itemEffectDescription = "아이템 효과를 입력하세요."
            }
        }
    }
}

#Preview {
    StoreAdminView()
}
