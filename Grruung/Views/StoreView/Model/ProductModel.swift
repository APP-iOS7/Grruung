//
//  ProductModel.swift
//  Grruung
//
//  Created by 심연아 on 5/12/25.
//

import SwiftUI

struct Product: Identifiable {
    let id = UUID()
    let iconName: String
    let name: String
    let price: Int
    let bgColor: Color
}

let products = [
    Product(iconName: "syringe", name: "주사 치료", price: 199, bgColor: .blue.opacity(0.4)),
    Product(iconName: "bandage", name: "밴드 치료", price: 159, bgColor: .yellow.opacity(0.4)),
    Product(iconName: "pill", name: "약물 치료", price: 89, bgColor: .pink.opacity(0.4)),
    Product(iconName: "tennisball", name: "캐치볼 놀이", price: 189, bgColor: .green.opacity(0.4)),
    Product(iconName: "bird", name: "힐링하기", price: 229, bgColor: .purple.opacity(0.4)),
    Product(iconName: "shippingbox", name: "랜덤박스선물", price: 209, bgColor: .orange.opacity(0.4)),
    Product(iconName: "pill", name: "약물 치료", price: 89, bgColor: .cyan.opacity(0.4)),
    Product(iconName: "tennisball", name: "캐치볼 놀이", price: 189, bgColor: .green.opacity(0.4)),
]

let treatmentProducts = [
    Product(iconName: "syringe", name: "주사 치료", price: 199, bgColor: .blue.opacity(0.4)),
    Product(iconName: "bandage", name: "밴드 치료", price: 159, bgColor: .yellow.opacity(0.4)),
    Product(iconName: "pill", name: "약물 치료", price: 89, bgColor: .pink.opacity(0.4)),
    Product(iconName: "syringe", name: "주사 치료", price: 199, bgColor: .blue.opacity(0.4)),
    Product(iconName: "bandage", name: "밴드 치료", price: 159, bgColor: .yellow.opacity(0.4)),
    Product(iconName: "pill", name: "약물 치료", price: 89, bgColor: .pink.opacity(0.4)),
    Product(iconName: "syringe", name: "주사 치료", price: 199, bgColor: .blue.opacity(0.4)),
    Product(iconName: "bandage", name: "밴드 치료", price: 159, bgColor: .yellow.opacity(0.4)),
    Product(iconName: "pill", name: "약물 치료", price: 89, bgColor: .pink.opacity(0.4)),
]

let playProducts = [
    Product(iconName: "tennisball", name: "캐치볼 놀이", price: 189, bgColor: .green.opacity(0.4)),
    Product(iconName: "gamecontroller", name: "게임하기", price: 149, bgColor: .orange.opacity(0.4)),
    Product(iconName: "tennisball", name: "캐치볼 놀이", price: 189, bgColor: .green.opacity(0.4)),
    Product(iconName: "gamecontroller", name: "게임하기", price: 149, bgColor: .orange.opacity(0.4)),
    Product(iconName: "tennisball", name: "캐치볼 놀이", price: 189, bgColor: .green.opacity(0.4)),
    Product(iconName: "gamecontroller", name: "게임하기", price: 149, bgColor: .orange.opacity(0.4)),
]

let recoveryProducts = [
    Product(iconName: "bird", name: "힐링하기", price: 229, bgColor: .purple.opacity(0.4)),
    Product(iconName: "leaf", name: "산책하기", price: 129, bgColor: .mint.opacity(0.4)),
    Product(iconName: "bird", name: "힐링하기", price: 229, bgColor: .purple.opacity(0.4)),
    Product(iconName: "leaf", name: "산책하기", price: 129, bgColor: .mint.opacity(0.4)),
    Product(iconName: "bird", name: "힐링하기", price: 229, bgColor: .purple.opacity(0.4)),
    Product(iconName: "leaf", name: "산책하기", price: 129, bgColor: .mint.opacity(0.4)),
    Product(iconName: "bird", name: "힐링하기", price: 229, bgColor: .purple.opacity(0.4)),
    Product(iconName: "leaf", name: "산책하기", price: 129, bgColor: .mint.opacity(0.4)),
]
