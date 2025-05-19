//
//  GRUserInventory.swift
//  Grruung
//
//  Created by mwpark on 5/13/25.
//

import Foundation

/// 유저의 인벤토리 모델
/// - 상점에서 구매한 물품의 정보를 담는 구조체
struct GRUserInventory {
    var userItemNumber: Int
    var userItemName: String
    var userItemType: ItemType
    var userItemImage: String
    var userItemQuantity: Int
    var userItemDescription: String
    var userItemCategory: ItemCategory
    var purchasedAt: Date
    
    init(userItemNumber: Int, userItemName: String, userItemType: ItemType, userItemImage: String, userIteamQuantity: Int, userItemDescription: String, userItemCategory: ItemCategory, purchasedAt: Date) {
        self.userItemNumber = userItemNumber
        self.userItemName = userItemName
        self.userItemType = userItemType
        self.userItemImage = userItemImage
        self.userItemQuantity = userIteamQuantity
        self.userItemDescription = userItemDescription
        self.userItemCategory = userItemCategory
        self.purchasedAt = purchasedAt
    }
    
    enum ItemType: String {
        case consumable = "소모품"
        case permanent = "영구"
    }
    enum ItemCategory: String {
        case drug = "약품"
        case toy = "장난감"
        /// 나중에~
        // case avatar = "의류"
    }
}

