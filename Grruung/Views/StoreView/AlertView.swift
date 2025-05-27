//
//  alertView.swift
//  Grruung
//
//  Created by 심연아 on 5/7/25.
//

import SwiftUI
import Foundation

struct AlertView: View {
    @EnvironmentObject var userInventoryViewModel: UserInventoryViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var authService: AuthService
    @State private var isProcessing = false
    @State var realUserId = ""
    @State private var showNotEnoughMoneyAlert = false
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
                
                // 처리 중 표시
                if isProcessing {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("구매 처리 중...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                }
                
                // 버튼들
                HStack(spacing: 12) {
                    // NO 버튼
                    AnimatedCancelButton {
                        withAnimation {
                            isPresented = false
                        }
                    }
                    
                    // YES 버튼
                    AnimatedConfirmButton {
                        Task {
                            if authService.currentUserUID == "" {
                                realUserId = "23456"
                            } else {
                                realUserId = authService.currentUserUID
                            }
                            await handlePurchase()
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
        .alert("잔액이 부족합니다", isPresented: $showNotEnoughMoneyAlert) {
            Button("확인", role: .cancel) { }
        }
    }
    
    // MARK: - 구매 처리 메서드
    private func handlePurchase() async {
        // 중복 처리 방지
        guard !isProcessing else {
            print("[중복방지] 이미 처리 중입니다")
            return
        }
        
        isProcessing = true
        print("[구매시작] 아이템 구매 처리 시작")
        print("[구매정보] 아이템명: \(product.itemName), 수량: \(quantity)")
        
        // 유저정보가 있는지 확인
        guard let user = userViewModel.user else {
            print("❌ 유저 정보 없음")
            isProcessing = false
            return
        }

        let totalPrice = product.itemPrice * quantity
        
        // 상품이 골드인지 다이아인지
        let hasEnoughCurrency: Bool
        switch product.itemCurrencyType {
        case .gold:
            hasEnoughCurrency = user.gold >= totalPrice
        case .diamond:
            hasEnoughCurrency = user.diamond >= totalPrice
        }
        
        guard hasEnoughCurrency else {
            print("❌ 잔액 부족: 구매 금액 \(totalPrice), 보유 금액 \(product.itemCurrencyType == .gold ? user.gold : user.diamond)")
            
            await MainActor.run {
                isPresented = false
                showNotEnoughMoneyAlert = true
            }
            
            isProcessing = false
            return
        }
        
        let updatedGold = product.itemCurrencyType == .gold ? user.gold - totalPrice : user.gold
        let updatedDiamond = product.itemCurrencyType == .diamond ? user.diamond - totalPrice : user.diamond
        
        do {
            let buyItem = GRUserInventory(
                userItemNumber: product.itemNumber,
                userItemName: product.itemName,
                userItemType: product.itemType,
                userItemImage: product.itemImage,
                userIteamQuantity: quantity,
                userItemDescription: product.itemDescription,
                userItemEffectDescription: product.itemEffectDescription,
                userItemCategory: product.itemCategory
            )
            
            // 이미 로드된 인벤토리에서 기존 아이템 확인 (즉시 확인)
            if let existingItem = userInventoryViewModel.inventories.first(where: {
                $0.userItemNumber == buyItem.userItemNumber
            }) {
                print("[기존아이템] 발견 - 현재수량: \(existingItem.userItemQuantity)")
                let newQuantity = existingItem.userItemQuantity + quantity
                print("[수량업데이트] 새로운 수량: \(newQuantity)")
                                
                // 수량 업데이트 (await로 즉시 처리)
                await userInventoryViewModel.updateItemQuantity(
                    userId: realUserId,
                    item: existingItem,
                    newQuantity: newQuantity
                )
            } else {
                print("[신규아이템] 새로운 아이템 추가")
                
                // 새 아이템 저장 (await로 즉시 처리)
                await userInventoryViewModel.saveInventory(
                    userId: realUserId,
                    inventory: buyItem
                )
            }
            
            userViewModel.updateCurrency(userId: realUserId, gold: updatedGold, diamond: updatedDiamond)
            print("🛒 [구매완료] 처리 완료!")
            
            // 성공 시 창 닫기
            await MainActor.run {
                isPresented = false
            }
            
        } catch {
            print("❌ 구매 처리 중 오류: \(error)")
        }
        
        isProcessing = false
    }
}

//
//#Preview {
//    AlertView()
//}
