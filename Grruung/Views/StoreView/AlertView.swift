//
//  alertView.swift
//  Grruung
//
//  Created by 심연아 on 5/7/25.
//

import SwiftUI

struct AlertView: View {
    @StateObject private var userInventoryViewModel = UserInventoryViewModel()
    @State private var userInventories: [GRUserInventory] = []
    let product: GRShopItem
    var quantity: Int
    @Binding var isPresented: Bool // 팝업 제어용
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // 아이콘
                Circle()
                    .fill(Color.cyan)
                    .frame(width: 75, height: 75)
                    .overlay(
                        Image(systemName: "ticket.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    )
                
                // 제목
                Text("가격: \(product.itemPrice * quantity)")
                    .font(.headline)
                    .foregroundColor(.black)
                
                // 설명
                Text("구매할까요?")
                    .font(.subheadline)
                    .foregroundColor(.black.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // 버튼들
                HStack(spacing: 12) {
                    // NO 버튼
                    AnimatedCancelButton {
                        withAnimation {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                isPresented = false
                            }
                        }
                    }
                    // YES 버튼
                    AnimatedConfirmButton {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            isPresented = false
                        }
                        
                        let buyItem = GRUserInventory(userItemNumber: product.itemNumber, userItemName: product.itemName, userItemType: product.itemType, userItemImage: product.itemImage, userIteamQuantity: quantity, userItemDescription: product.itemDescription, userItemEffectDescription: product.itemEffectDescription, userItemCategory: product.itemCategory)
                        
                        userInventoryViewModel.fetchInventories(userId: "12345") { allItems in
                            userInventories = allItems
                        }
                        
                        // 인벤토리에 있는 아이템을 구매할 경우
                        if let foundItem = userInventories.first(where: { $0.userItemNumber == buyItem.userItemNumber }) {
                            userInventoryViewModel.updateItemQuantity(userId: "12345", item: foundItem, newQuantity: foundItem.userItemQuantity + quantity)
                        } else {
                            userInventoryViewModel.saveInventory(userId: "12345", inventory: buyItem)
                        }
                    }
                }
                .frame(height: 50)
                .padding(.horizontal)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(20)
            .padding(.horizontal, 30)
            .frame(maxWidth: 300)
        }
    }
}

//
//#Preview {
//    AlertView()
//}
