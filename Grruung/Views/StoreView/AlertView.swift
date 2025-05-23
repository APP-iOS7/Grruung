//
//  alertView.swift
//  Grruung
//
//  Created by 심연아 on 5/7/25.
//

import SwiftUI

struct AlertView: View {
    @EnvironmentObject var userInventoryViewModel: UserInventoryViewModel
    @State private var isProcessing = false
    private let dummyUserId = "12345"

    let product: Product
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
                Text("가격: \(product.price * quantity)")
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
                            handlePurchase()
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
    
    // MARK: - 구매 처리 메서드
    private func handlePurchase() {
        // 중복 처리 방지
        guard !isProcessing else {
            print("[중복방지] 이미 처리 중입니다")
            return
        }
        
        isProcessing = true
        print("[구매시작] 아이템 구매 처리 시작")
        print("[구매정보] 아이템명: \(product.name), 수량: \(quantity)")
        
        do {
            let buyItem = GRUserInventory(
                userItemNumber: product.id.uuidString,
                userItemName: product.name,
                userItemType: .consumable,
                userItemImage: product.iconName,
                userIteamQuantity: quantity,
                userItemDescription: product.description,
                userItemEffectDescription: "",
                userItemCategory: .drug
            )
            
            // 이미 로드된 인벤토리에서 기존 아이템 확인 (즉시 확인)
            if let existingItem = userInventoryViewModel.inventories.first(where: { $0.userItemNumber == buyItem.userItemNumber }) {
                print("[기존아이템] 발견 - 현재수량: \(existingItem.userItemQuantity)")
                let newQuantity = existingItem.userItemQuantity + quantity
                print("[수량업데이트] 새로운 수량: \(newQuantity)")
                
                // 수량 업데이트 (await로 즉시 처리)
                userInventoryViewModel.updateItemQuantity(
                    userId: dummyUserId,
                    item: existingItem,
                    newQuantity: newQuantity
                )
            } else {
                print("[신규아이템] 새로운 아이템 추가")
                
                // 새 아이템 저장 (await로 즉시 처리)
                userInventoryViewModel.saveInventory(
                    userId: dummyUserId,
                    inventory: buyItem
                )
            }
            
            print("🛒 [구매완료] 처리 완료!")
            
            // 성공 시 즉시 창 닫기
            isPresented = false
            
        }
        
        isProcessing = false
    }
}

//
//#Preview {
//    AlertView()
//}
