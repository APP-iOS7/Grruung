//
//  ItemPopupView.swift
//  Grruung
//
//  Created by mwpark on 6/15/25.
//

import SwiftUI

struct ItemPopupView: View {
    let item: GRStoreItem
    let userId: String
    
    @Binding var isPresented: Bool
    
    @EnvironmentObject var userInventoryViewModel: UserInventoryViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            Text("획득한 아이템")
                .font(.title2)
                .bold()

            Image(item.itemImage)
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)

            Text(item.itemName)
                .font(.headline)

            Button("확인") {
//                dismiss()
                saveItemToFirebase()
                isPresented = false
            }
            .padding()
            .background(GRColor.buttonColor_1)
            .foregroundColor(.black)
            .cornerRadius(10)
        }
        .frame(maxWidth: 300)
        .padding()
//        .background(GRColor.mainColor1_1)
        .background(Color.white) // 반드시 불투명 색
        .cornerRadius(10)
        .shadow(radius: 10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.brown, lineWidth: 2)
        )
        .padding()
        .shadow(radius: 10)
    }
    
    private func saveItemToFirebase() {
            // 🔁 기존 인벤토리에서 같은 아이템이 있는지 확인
            if let existingItem = userInventoryViewModel.inventories.first(where: {
                $0.userItemName == item.itemName
            }) {
                print("🟡 기존 아이템 발견 → 수량 증가")

                let newQuantity = existingItem.userItemQuantity + item.itemQuantity

                userInventoryViewModel.updateItemQuantity(
                    userId: userId,
                    item: existingItem,
                    newQuantity: newQuantity
                )

            } else {
                print("🟢 새로운 아이템 저장")

                let newInventory = GRUserInventory(
                    userItemNumber: UUID().uuidString,
                    userItemName: item.itemName,
                    userItemType: item.itemType,
                    userItemImage: item.itemImage,
                    userIteamQuantity: item.itemQuantity,
                    userItemDescription: item.itemDescription,
                    userItemEffectDescription: item.itemEffectDescription,
                    userItemCategory: item.itemCategory
                )

                Task {
                    await userInventoryViewModel.saveInventory(userId: userId, inventory: newInventory)
                }
            }
        }
}
