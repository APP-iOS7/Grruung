////
////  ProductModel.swift
////  Grruung
////
////  Created by 심연아 on 5/12/25.
////
//
//import SwiftUI
//
//struct Product: Identifiable {
//    let id = UUID()
//    let iconName: String
//    let name: String
//    let price: Int
//    let bgColor: Color
//    let description: String
//}
//
//let products = [
//    Product(iconName: "syringe", name: "주사 치료", price: 199, bgColor: .blue.opacity(0.4), description: "빠르고 정확한 주사 치료로 활력을 되찾아요."),
//    Product(iconName: "bandage", name: "밴드 치료", price: 159, bgColor: .yellow.opacity(0.4), description: "상처엔 역시 부드러운 밴드! 간편한 응급 처치."),
//    Product(iconName: "pill", name: "약물 치료", price: 89, bgColor: .pink.opacity(0.4), description: "복용이 쉬운 알약으로 내부부터 회복."),
//    Product(iconName: "tennisball", name: "캐치볼 놀이", price: 189, bgColor: .green.opacity(0.4), description: "몸도 마음도 튕겨내는 재미! 건강한 유대감 형성."),
//    Product(iconName: "bird", name: "힐링하기", price: 229, bgColor: .purple.opacity(0.4), description: "조용히 자연을 느끼며 회복하는 시간."),
//    Product(iconName: "shippingbox", name: "랜덤박스선물", price: 209, bgColor: .orange.opacity(0.4), description: "무엇이 들어있을까? 기대를 담은 깜짝 선물!"),
//    Product(iconName: "pill", name: "약물 치료", price: 89, bgColor: .cyan.opacity(0.4), description: "증상에 맞춘 약물로 속부터 치유."),
//    Product(iconName: "tennisball", name: "캐치볼 놀이", price: 189, bgColor: .green.opacity(0.4), description: "던지고 받고, 함께 놀며 즐거운 운동 시간!")
//]
//
//let treatmentProducts = [
//    Product(iconName: "syringe", name: "주사 치료", price: 199, bgColor: .blue.opacity(0.4), description: "신속한 치료를 위한 전문 주사."),
//    Product(iconName: "bandage", name: "밴드 치료", price: 159, bgColor: .yellow.opacity(0.4), description: "상처 부위 보호에 탁월한 밴드."),
//    Product(iconName: "pill", name: "약물 치료", price: 89, bgColor: .pink.opacity(0.4), description: "증상 완화에 효과적인 약물 치료."),
//    Product(iconName: "syringe", name: "주사 치료", price: 199, bgColor: .blue.opacity(0.4), description: "신속한 치료를 위한 전문 주사."),
//    Product(iconName: "bandage", name: "밴드 치료", price: 159, bgColor: .yellow.opacity(0.4), description: "상처 부위 보호에 탁월한 밴드."),
//    Product(iconName: "pill", name: "약물 치료", price: 89, bgColor: .pink.opacity(0.4), description: "증상 완화에 효과적인 약물 치료."),
//    Product(iconName: "syringe", name: "주사 치료", price: 199, bgColor: .blue.opacity(0.4), description: "신속한 치료를 위한 전문 주사."),
//    Product(iconName: "bandage", name: "밴드 치료", price: 159, bgColor: .yellow.opacity(0.4), description: "상처 부위 보호에 탁월한 밴드."),
//    Product(iconName: "pill", name: "약물 치료", price: 89, bgColor: .pink.opacity(0.4), description: "증상 완화에 효과적인 약물 치료."),
//]
//
//let playProducts = [
//    Product(iconName: "tennisball", name: "캐치볼 놀이", price: 189, bgColor: .green.opacity(0.4), description: "활동성과 친밀감을 동시에 키우는 놀이."),
//    Product(iconName: "gamecontroller", name: "게임하기", price: 149, bgColor: .orange.opacity(0.4), description: "긴장 풀고 재미있는 시간! 스트레스 해소 OK."),
//    Product(iconName: "tennisball", name: "캐치볼 놀이", price: 189, bgColor: .green.opacity(0.4), description: "신체 활동을 통한 긍정 에너지 충전."),
//    Product(iconName: "gamecontroller", name: "게임하기", price: 149, bgColor: .orange.opacity(0.4), description: "다양한 게임으로 집중력과 유대감 향상."),
//    Product(iconName: "tennisball", name: "캐치볼 놀이", price: 189, bgColor: .green.opacity(0.4), description: "놀이를 통한 자연스러운 운동."),
//    Product(iconName: "gamecontroller", name: "게임하기", price: 149, bgColor: .orange.opacity(0.4), description: "함께 즐기며 웃음이 넘치는 시간!")
//]
//
//let recoveryProducts = [
//    Product(iconName: "bird", name: "힐링하기", price: 229, bgColor: .purple.opacity(0.4), description: "마음의 안정을 위한 자연과의 교감."),
//    Product(iconName: "leaf", name: "산책하기", price: 129, bgColor: .mint.opacity(0.4), description: "자연 속에서의 산책으로 기분 전환!"),
//    Product(iconName: "bird", name: "힐링하기", price: 229, bgColor: .purple.opacity(0.4), description: "편안한 휴식으로 체력과 정신 회복."),
//    Product(iconName: "leaf", name: "산책하기", price: 129, bgColor: .mint.opacity(0.4), description: "상쾌한 공기와 함께 걷는 치유의 시간."),
//    Product(iconName: "bird", name: "힐링하기", price: 229, bgColor: .purple.opacity(0.4), description: "조용한 힐링타임으로 기분전환."),
//    Product(iconName: "leaf", name: "산책하기", price: 129, bgColor: .mint.opacity(0.4), description: "스트레스를 날려줄 초록빛 산책."),
//    Product(iconName: "bird", name: "힐링하기", price: 229, bgColor: .purple.opacity(0.4), description: "잠시 멈추고 숨을 고르는 소중한 시간."),
//    Product(iconName: "leaf", name: "산책하기", price: 129, bgColor: .mint.opacity(0.4), description: "몸과 마음이 모두 리프레시 되는 시간!")
//]
//
////한정판
//let limitedProducts = [
//    Product(iconName: "sparkles",   name: "스페셜 스파클",   price: 499,
//            bgColor: .indigo.opacity(0.5),
//            description: "희귀 성분이 반짝이는 건강 부스트 세럼. 한정 수량!"),
//    Product(iconName: "flame.fill", name: "울트라 부스터",        price: 559,
//            bgColor: .red.opacity(0.5),
//            description: "관절까지 뜨거운 에너지 폭발! 소진 시까지 판매."),
//    Product(iconName: "crown.fill", name: "킹덤 VIP 티켓",        price: 799,
//            bgColor: .yellow.opacity(0.5),
//            description: "왕실급 혜택을 누릴 수 있는 프리미엄 이용권."),
//    Product(iconName: "gift.fill",  name: "랜덤 깜짝박스", price: 699,
//            bgColor: .pink.opacity(0.5),
//            description: "프리미엄 아이템만 담은 고급 랜덤 박스!")
//]
//
//// 티켓
//let ticketProducts = [
//    Product(iconName: "ticket.fill", name: "10회 이용권", price: 399, bgColor: .orange.opacity(0.4),
//            description: "10회 이용 가능한 스탬프 티켓!"),
//    Product(iconName: "ticket.fill", name: "30일 패스",  price: 599, bgColor: .cyan.opacity(0.4),
//            description: "무제한으로 즐기는 30일 자유 이용권.")
//]
//
//// 모든 것들
//let allProducts: [Product] =
//    limitedProducts + ticketProducts
//
