//
//  GRShopItem.swift
//  Grruung
//
//  Created by 심연아 on 5/12/25.
//  Edited by mwpark on 5/23/25.
//

import SwiftUI

struct GRStoreItem: Identifiable {
    let id = UUID()
    let itemNumber: String
    var itemName: String
    var itemTarget: PetSpecies
    var itemType: ItemType
    var itemImage: String
    var itemQuantity: Int
    var limitedQuantity: Int
    var purchasedQuantity: Int
    var itemPrice: Int
    var itemCurrencyType: ItemCurrencyType
    var itemDescription: String
    var itemEffectDescription: String
    var itemTag: ItemTag
    var itemCategory: ItemCategory
    var isItemOwned: Bool
    let bgColor: Color
    
    init(itemName: String,
         itemTarget: PetSpecies = .Undefined,
         itemType: ItemType,
         itemImage: String,
         itemQuantity: Int,
         limitedQuantity: Int,
         purchasedQuantity: Int,
         itemPrice: Int,
         itemCurrencyType: ItemCurrencyType = .gold,
         itemDescription: String,
         itemEffectDescription: String,
         itemTag: ItemTag,
         itemCategory: ItemCategory,
         isItemOwned: Bool = false,
         bgColor: Color
    ) {
        self.itemNumber = id.uuidString
        self.itemName = itemName
        self.itemTarget = itemTarget
        self.itemType = itemType
        self.itemImage = itemImage
        self.itemQuantity = itemQuantity
        self.limitedQuantity = limitedQuantity
        self.purchasedQuantity = purchasedQuantity
        self.itemPrice = itemPrice
        self.itemCurrencyType = itemCurrencyType
        self.itemDescription = itemDescription
        self.itemEffectDescription = itemEffectDescription
        self.itemTag = itemTag
        self.itemCategory = itemCategory
        self.isItemOwned = isItemOwned
        self.bgColor = bgColor
    }
}

enum ItemType: String, CaseIterable {
    case consumable = "소모품"
    case permanent = "영구"
}

enum ItemCategory: String, CaseIterable {
    case drug = "약품"
    case toy = "장난감"
    case etc = "기타"
    /// 나중에~
    // case avatar = "의류"
}

enum ItemTag: String, CaseIterable {
    case limited = "기간+한정상품"
    case normal = "일반상품"
}

enum ItemCurrencyType: String, CaseIterable {
    case gold = "골드"
    case diamond = "다이아"
    case won = "원"
}

let products = [
    GRStoreItem(itemName: "다이아 → 골드",
               itemType: .consumable,
               itemImage: "DiamondToGold",
               itemQuantity: 1,
               limitedQuantity: 10,
               purchasedQuantity: 0,
               itemPrice: 10,
               itemCurrencyType: .diamond,
               itemDescription: "10 다이아를 1000 골드로 교환할 수 있는 아이템입니다.",
               itemEffectDescription: "사용 시 1000 골드를 획득합니다.",
               itemTag: .normal,
               itemCategory: .etc, // 새 범주 추가 가능
               bgColor: .yellow.opacity(0.4)),
    
    GRStoreItem(itemName: "5 다이아",
               itemType: .consumable,
               itemImage: "diamond_5",
               itemQuantity: 1,
               limitedQuantity: 1,
               purchasedQuantity: 0,
               itemPrice: 1200,
                itemCurrencyType: .won,
               itemDescription: "입문자를 위한 소형 다이아 팩입니다.",
               itemEffectDescription: "구매 시 5 다이아를 획득합니다.",
               itemTag: .normal,
               itemCategory: .etc,
               bgColor: .yellow.opacity(0.4)),
    GRStoreItem(itemName: "12 다이아",
               itemType: .consumable,
               itemImage: "diamond_12",
               itemQuantity: 1,
               limitedQuantity: 1,
               purchasedQuantity: 0,
               itemPrice: 2500,
                itemCurrencyType: .won,
               itemDescription: "가성비 좋은 소형 팩! 조금 더 여유 있게 사용해보세요.",
               itemEffectDescription: "구매 시 12 다이아를 획득합니다.",
               itemTag: .normal,
               itemCategory: .etc,
               bgColor: .yellow.opacity(0.4)),
    GRStoreItem(itemName: "30 다이아",
               itemType: .consumable,
               itemImage: "diamond_30",
               itemQuantity: 1,
               limitedQuantity: 1,
               purchasedQuantity: 0,
               itemPrice: 5900,
                itemCurrencyType: .won,
               itemDescription: "일상적으로 사용하기 좋은 다이아 팩입니다.",
               itemEffectDescription: "구매 시 30 다이아를 획득합니다.",
               itemTag: .normal,
               itemCategory: .etc,
               bgColor: .yellow.opacity(0.4)),
    GRStoreItem(itemName: "65 다이아",
               itemType: .consumable,
               itemImage: "diamond_65",
               itemQuantity: 1,
               limitedQuantity: 1,
               purchasedQuantity: 0,
               itemPrice: 12000,
                itemCurrencyType: .won,
               itemDescription: "다양한 프리미엄 아이템 구매에 적합한 중형 팩입니다.",
               itemEffectDescription: "구매 시 65 다이아를 획득합니다.",
               itemTag: .normal,
               itemCategory: .etc,
               bgColor: .yellow.opacity(0.4)),
    GRStoreItem(itemName: "140 다이아",
               itemType: .consumable,
               itemImage: "diamond_140",
               itemQuantity: 1,
               limitedQuantity: 1,
               purchasedQuantity: 0,
               itemPrice: 25000,
                itemCurrencyType: .won,
               itemDescription: "게임을 더 깊이 즐기고 싶은 유저를 위한 대형 팩입니다.",
               itemEffectDescription: "구매 시 140 다이아를 획득합니다.",
               itemTag: .normal,
               itemCategory: .etc,
               bgColor: .yellow.opacity(0.4)),
    GRStoreItem(itemName: "300 다이아",
               itemType: .consumable,
               itemImage: "diamond_300",
               itemQuantity: 1,
               limitedQuantity: 1,
               purchasedQuantity: 0,
               itemPrice: 49000,
                itemCurrencyType: .won,
               itemDescription: "가장 많은 혜택을 제공하는 초대형 팩!",
               itemEffectDescription: "구매 시 300 다이아를 획득합니다.",
               itemTag: .normal,
               itemCategory: .etc,
               bgColor: .yellow.opacity(0.4)),
    
    GRStoreItem(itemName: "주사 치료",
               itemType: .consumable,
               itemImage: "Injection",
               itemQuantity: 1,
               limitedQuantity: 10,
               purchasedQuantity: 0,
               itemPrice: 199,
               itemDescription: "빠르고 정확한 주사 치료로 활력을 되찾아요.",
               itemEffectDescription: "에너지가 회복됩니다.",
               itemTag: .normal,
               itemCategory: .drug,
               bgColor: .blue.opacity(0.4)),
    
    GRStoreItem(itemName: "진단 치료",
               itemType: .consumable,
               itemImage: "stethoscope",
               itemQuantity: 1,
               limitedQuantity: 10,
               purchasedQuantity: 0,
               itemPrice: 159,
               itemDescription: "의사에게 정확한 진단으로 더 빨리 나아요!",
               itemEffectDescription: "작은 상처가 치료됩니다.",
               itemTag: .normal,
               itemCategory: .drug,
               bgColor: .yellow.opacity(0.4)),
    
    GRStoreItem(itemName: "약물 치료",
               itemType: .consumable,
               itemImage: "medicineBottles",
               itemQuantity: 1,
               limitedQuantity: 10,
               purchasedQuantity: 0,
               itemPrice: 89,
               itemDescription: "복용이 쉬운 알약으로 내부부터 회복.",
               itemEffectDescription: "컨디션이 향상됩니다.",
               itemTag: .normal,
               itemCategory: .drug,
               bgColor: .pink.opacity(0.4)),
    
    GRStoreItem(itemName: "캐치볼 놀이",
               itemType: .permanent,
               itemImage: "volleyball",
               itemQuantity: 1,
               limitedQuantity: 10,
               purchasedQuantity: 0,
               itemPrice: 189,
               itemDescription: "몸도 마음도 튕겨내는 재미! 건강한 유대감 형성.",
               itemEffectDescription: "스트레스가 감소합니다.",
               itemTag: .normal,
               itemCategory: .toy,
               bgColor: .green.opacity(0.4)),
    
    GRStoreItem(itemName: "힐링하기",
               itemType: .consumable,
               itemImage: "healing",
               itemQuantity: 1,
               limitedQuantity: 10,
               purchasedQuantity: 0,
               itemPrice: 229,
               itemDescription: "조용히 자연을 느끼며 회복하는 시간.",
               itemEffectDescription: "마음이 안정됩니다.",
               itemTag: .normal,
               itemCategory: .etc,
               bgColor: .purple.opacity(0.4)),
    
    GRStoreItem(itemName: "랜덤박스선물",
               itemType: .consumable,
               itemImage: "randomBoxGift",
               itemQuantity: 1,
               limitedQuantity: 10,
               purchasedQuantity: 0,
               itemPrice: 209,
               itemDescription: "무엇이 들어있을까? 기대를 담은 깜짝 선물!",
               itemEffectDescription: "무작위 아이템을 획득합니다.",
               itemTag: .normal,
               itemCategory: .etc,
               bgColor: .orange.opacity(0.4)),
    
    GRStoreItem(itemName: "약물 치료",
               itemType: .consumable,
               itemImage: "pill",
               itemQuantity: 1,
               limitedQuantity: 10,
               purchasedQuantity: 0,
               itemPrice: 89,
               itemDescription: "증상에 맞춘 약물로 속부터 치유.",
               itemEffectDescription: "질병이 완화됩니다.",
               itemTag: .normal,
               itemCategory: .drug,
               bgColor: .cyan.opacity(0.4)),
    
    GRStoreItem(itemName: "캐치볼 놀이",
               itemType: .permanent,
               itemImage: "tennisball",
               itemQuantity: 1,
               limitedQuantity: 10,
               purchasedQuantity: 0,
               itemPrice: 189,
               itemDescription: "던지고 받고, 함께 놀며 즐거운 운동 시간!",
               itemEffectDescription: "운동 능력이 향상됩니다.",
               itemTag: .normal,
               itemCategory: .toy,
               bgColor: .green.opacity(0.4))
]

let treatmentProducts = [
    GRStoreItem(itemName: "주사 치료",
               itemType: .consumable,
               itemImage: "syringe",
               itemQuantity: 1,
               limitedQuantity: 10,
               purchasedQuantity: 0,
               itemPrice: 199,
               itemDescription: "신속한 치료를 위한 전문 주사.",
               itemEffectDescription: "즉각적인 체력 회복.",
               itemTag: .normal,
               itemCategory: .drug,
               bgColor: .blue.opacity(0.4)),
    
    GRStoreItem(itemName: "밴드 치료",
               itemType: .consumable,
               itemImage: "bandage",
               itemQuantity: 1,
               limitedQuantity: 10,
               purchasedQuantity: 0,
               itemPrice: 159,
               itemDescription: "상처 부위 보호에 탁월한 밴드.",
               itemEffectDescription: "상처가 치료됩니다.",
               itemTag: .normal,
               itemCategory: .drug,
               bgColor: .yellow.opacity(0.4)),
    
    GRStoreItem(itemName: "약물 치료",
               itemType: .consumable,
               itemImage: "pill",
               itemQuantity: 1,
               limitedQuantity: 10,
               purchasedQuantity: 0,
               itemPrice: 89,
               itemDescription: "증상 완화에 효과적인 약물 치료.",
               itemEffectDescription: "증상이 완화됩니다.",
               itemTag: .normal,
               itemCategory: .drug,
               bgColor: .pink.opacity(0.4)),
    
    GRStoreItem(itemName: "주사 치료",
               itemType: .consumable,
               itemImage: "syringe",
               itemQuantity: 1,
               limitedQuantity: 10,
               purchasedQuantity: 0,
               itemPrice: 199,
               itemDescription: "신속한 치료를 위한 전문 주사.",
               itemEffectDescription: "즉각적인 체력 회복.",
               itemTag: .normal,
               itemCategory: .drug,
               bgColor: .blue.opacity(0.4)),
]

// 놀이
let playProducts = [
    GRStoreItem(itemName: "힐링하기",
               itemType: .consumable,
               itemImage: "bird",
               itemQuantity: 1,
               limitedQuantity: 10,
               purchasedQuantity: 0,
               itemPrice: 229,
               itemDescription: "마음의 안정을 위한 자연과의 교감.",
               itemEffectDescription: "정서적 안정 및 스트레스 감소.",
               itemTag: .normal,
               itemCategory: .etc,
               bgColor: .purple.opacity(0.4)),
    
    GRStoreItem(itemName: "산책하기",
               itemType: .consumable,
               itemImage: "walking",
               itemQuantity: 1,
               limitedQuantity: 10,
               purchasedQuantity: 0,
               itemPrice: 129,
               itemDescription: "자연 속에서의 산책으로 기분 전환!",
               itemEffectDescription: "기분 전환과 활력 회복.",
               itemTag: .normal,
               itemCategory: .etc,
               bgColor: .mint.opacity(0.4))
]

// 회복
let recoveryProducts: [GRStoreItem] = [
    GRStoreItem(itemName: "아이스크림",
               itemType: .consumable,
               itemImage: "icecream",
               itemQuantity: 1,
               limitedQuantity: 10,
               purchasedQuantity: 0,
               itemPrice: 229,
               itemDescription: "마음의 안정을 위한 자연과의 교감.",
               itemEffectDescription: "스트레스 완화 및 심신 안정.",
               itemTag: .normal,
               itemCategory: .toy,
               bgColor: .purple.opacity(0.4)),
    
    GRStoreItem(itemName: "햄버거",
               itemType: .consumable,
               itemImage: "burger",
               itemQuantity: 1,
               limitedQuantity: 10,
               purchasedQuantity: 0,
               itemPrice: 129,
               itemDescription: "자연 속에서의 산책으로 기분 전환!",
               itemEffectDescription: "기분 전환 및 건강 회복.",
               itemTag: .normal,
               itemCategory: .toy,
               bgColor: .mint.opacity(0.4)),
    
    GRStoreItem(itemName: "팬케이크",
               itemType: .consumable,
               itemImage: "pancake",
               itemQuantity: 1,
               limitedQuantity: 10,
               purchasedQuantity: 0,
               itemPrice: 229,
               itemDescription: "편안한 휴식으로 체력과 정신 회복.",
               itemEffectDescription: "에너지 충전과 집중력 향상.",
               itemTag: .normal,
               itemCategory: .toy,
               bgColor: .purple.opacity(0.4)),
    
    GRStoreItem(itemName: "복숭아 먹기",
               itemType: .consumable,
               itemImage: "peach",
               itemQuantity: 1,
               limitedQuantity: 10,
               purchasedQuantity: 0,
               itemPrice: 129,
               itemDescription: "상쾌한 공기와 함께 걷는 치유의 시간.",
               itemEffectDescription: "신체적 긴장 완화.",
               itemTag: .normal,
               itemCategory: .toy,
               bgColor: .mint.opacity(0.4)),
    
    GRStoreItem(itemName: "배 먹기",
               itemType: .consumable,
               itemImage: "pear",
               itemQuantity: 1,
               limitedQuantity: 10,
               purchasedQuantity: 0,
               itemPrice: 229,
               itemDescription: "조용한 힐링타임으로 기분전환.",
               itemEffectDescription: "정서적 안정 및 회복.",
               itemTag: .normal,
               itemCategory: .toy,
               bgColor: .purple.opacity(0.4)),

    GRStoreItem(itemName: "수박 먹기",
               itemType: .consumable,
               itemImage: "watermelon",
               itemQuantity: 1,
               limitedQuantity: 0,
               purchasedQuantity: 0,
               itemPrice: 129,
               itemDescription: "몸과 마음이 모두 리프레시 되는 시간!",
               itemEffectDescription: "체력 회복과 힐링 효과.",
               itemTag: .normal,
               itemCategory: .toy,
               bgColor: .mint.opacity(0.4)),
    
    GRStoreItem(itemName: "쉐이크",
               itemType: .consumable,
               itemImage: "shake",
               itemQuantity: 1,
               limitedQuantity: 10,
               purchasedQuantity: 0,
               itemPrice: 129,
               itemDescription: "스트레스를 날려줄 초록빛 산책.",
               itemEffectDescription: "스트레스 해소 및 휴식.",
               itemTag: .normal,
               itemCategory: .toy,
               bgColor: .mint.opacity(0.4)),
    
    GRStoreItem(itemName: "초밥 먹기",
               itemType: .consumable,
               itemImage: "sushi",
               itemQuantity: 1,
               limitedQuantity: 10,
               purchasedQuantity: 0,
               itemPrice: 229,
               itemDescription: "잠시 멈추고 숨을 고르는 소중한 시간.",
               itemEffectDescription: "마음의 안정과 리프레시.",
               itemTag: .normal,
               itemCategory: .toy,
               bgColor: .purple.opacity(0.4)),
    
    GRStoreItem(itemName: "와플 먹기",
               itemType: .consumable,
               itemImage: "waffle",
               itemQuantity: 1,
               limitedQuantity: 10,
               purchasedQuantity: 0,
               itemPrice: 129,
               itemDescription: "몸과 마음이 모두 리프레시 되는 시간!",
               itemEffectDescription: "체력 회복과 힐링 효과.",
               itemTag: .normal,
               itemCategory: .toy,
               bgColor: .mint.opacity(0.4))
]

//한정판
let limitedProducts = [
    GRStoreItem(itemName: "스페셜 스파클",
               itemType: .consumable,
               itemImage: "star",
               itemQuantity: 1,
               limitedQuantity: 100, // 예시 수량
               purchasedQuantity: 0,
               itemPrice: 499,
               itemCurrencyType: .diamond,
               itemDescription: "희귀 성분이 반짝이는 건강 부스트 세럼. 한정 수량!",
               itemEffectDescription: "즉시 활력 상승 + 특별 효과",
               itemTag: .limited,
               itemCategory: .drug,
               bgColor: .indigo.opacity(0.5)),
    
    GRStoreItem(itemName: "울트라 부스터",
               itemType: .consumable,
               itemImage: "flame.fill",
               itemQuantity: 1,
               limitedQuantity: 100,
               purchasedQuantity: 0,
               itemPrice: 559,
               itemCurrencyType: .diamond,
               itemDescription: "관절까지 뜨거운 에너지 폭발! 소진 시까지 판매.",
               itemEffectDescription: "에너지 완전 충전",
               itemTag: .limited,
               itemCategory: .drug,
               bgColor: .red.opacity(0.5)),
    
    GRStoreItem(itemName: "킹덤 VIP 티켓",
               itemType: .consumable,
               itemImage: "circleCrown",
               itemQuantity: 1,
               limitedQuantity: 50,
               purchasedQuantity: 0,
               itemPrice: 799,
               itemDescription: "왕실급 혜택을 누릴 수 있는 프리미엄 이용권.",
               itemEffectDescription: "VIP 서비스 제공",
               itemTag: .limited,
               itemCategory: .etc,
               bgColor: .yellow.opacity(0.5)),
    
    GRStoreItem(itemName: "랜덤 깜짝박스",
               itemType: .consumable,
               itemImage: "gift.fill",
               itemQuantity: 1,
               limitedQuantity: 100,
               purchasedQuantity: 0,
               itemPrice: 699,
               itemDescription: "프리미엄 아이템만 담은 고급 랜덤 박스!",
               itemEffectDescription: "프리미엄 아이템 무작위 획득",
               itemTag: .limited,
               itemCategory: .etc,
               bgColor: .pink.opacity(0.5))
]

// 티켓
let ticketProducts = [
    GRStoreItem(itemName: "10회 이용권",
               itemType: .consumable,
               itemImage: "ticket.fill",
               itemQuantity: 10,
               limitedQuantity: 10,
               purchasedQuantity: 0,
               itemPrice: 399,
               itemDescription: "10회 이용 가능한 스탬프 티켓!",
               itemEffectDescription: "10회 서비스 이용 가능",
               itemTag: .normal,
               itemCategory: .etc,
               bgColor: .orange.opacity(0.4)),
    
    GRStoreItem(itemName: "30일 패스",
               itemType: .consumable,
               itemImage: "circleCrown",
               itemQuantity: 1,
               limitedQuantity: 10,
               purchasedQuantity: 0,
               itemPrice: 599,
               itemDescription: "무제한으로 즐기는 30일 자유 이용권.",
               itemEffectDescription: "30일 동안 무제한 이용",
               itemTag: .normal,
               itemCategory: .etc,
               bgColor: .cyan.opacity(0.4)),
    GRStoreItem(itemName: "동산 잠금해제x1",
               itemType: .permanent,
               itemImage: "ticket.fill",
               itemQuantity: 1,
               limitedQuantity: 10,
               purchasedQuantity: 0,
               itemPrice: 9900,
               itemCurrencyType: .won,
               itemDescription: "캐릭터 동산의 슬롯 1개를 잠금해제 할 수 있습니다.",
               itemEffectDescription: "30일 동안 무제한 이용",
               itemTag: .normal,
               itemCategory: .etc,
               bgColor: .cyan.opacity(0.4))
]

// 모든 것들
let allProducts: [GRStoreItem] =
products + treatmentProducts + playProducts + limitedProducts + ticketProducts

