//
//  UserInventoryViewModel.swift
//  Grruung
//
//  Created by mwpark on 5/19/25.
//

import Foundation
import FirebaseFirestore

class UserInventoryViewModel: ObservableObject {
    @Published var inventories: [GRUserInventory] = []
    private let db = Firestore.firestore()
    private let collectionName = "userInventories"
    
    // MARK: - 아이템 저장
    func saveInventory(userId: String, inventory: GRUserInventory) {
        let data: [String: Any] = [
            "userItemNumber": inventory.userItemNumber,
            "userItemName": inventory.userItemName,
            "userItemType": inventory.userItemType.rawValue,
            "userItemImage": inventory.userItemImage,
            "userItemQuantity": inventory.userItemQuantity,
            "userItemDescription": inventory.userItemDescription,
            "userItemCategory": inventory.userItemCategory.rawValue,
            "purchasedAt": Timestamp(date: inventory.purchasedAt)
        ]
        do {
            try db.collection(collectionName)
                .document(userId)
                .collection("items")
                .document(inventory.userItemName)
                .setData(data)
        } catch {
            print("❌ 저장 실패: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 불러오기
    
    // MARK: - 삭제
}
