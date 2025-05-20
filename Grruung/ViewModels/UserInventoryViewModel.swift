//
//  UserInventoryViewModel.swift
//  Grruung
//
//  Created by mwpark on 5/19/25.
//

import Foundation
import FirebaseFirestore

class UserInventoryViewModel: ObservableObject {
    @Published var inventories: [GRUserInventory]? = nil
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
    func fetchInventories(userId: String, completion: @escaping ([GRUserInventory]) -> Void) {
        db.collection(collectionName)
            .document(userId)
            .collection("items")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ 불러오기 실패: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                self.inventories = documents.compactMap { doc in
                    let data = doc.data()
                    
                    guard
                        let itemNumber = data["userItemNumber"] as? Int,
                        let itemName = data["userItemName"] as? String,
                        let itemTypeRaw = data["userItemType"] as? String,
                        let itemType = GRUserInventory.ItemType(rawValue: itemTypeRaw),
                        let itemImage = data["userItemImage"] as? String,
                        let itemQuantity = data["userItemQuantity"] as? Int,
                        let itemDescription = data["userItemDescription"] as? String,
                        let itemCategoryRaw = data["userItemCategory"] as? String,
                        let itemCategory = GRUserInventory.ItemCategory(rawValue: itemCategoryRaw),
                        let timestamp = data["purchasedAt"] as? Timestamp
                    else {
                        print("❌ 파싱 실패 for document \(doc.documentID)")
                        return nil
                    }
                    
                    return GRUserInventory(
                        userItemNumber: itemNumber,
                        userItemName: itemName,
                        userItemType: itemType,
                        userItemImage: itemImage,
                        userIteamQuantity: itemQuantity,
                        userItemDescription: itemDescription,
                        userItemCategory: itemCategory,
                        purchasedAt: timestamp.dateValue()
                    )
                }
                completion(self.inventories!)
            }
    }
    // MARK: - 삭제
}
