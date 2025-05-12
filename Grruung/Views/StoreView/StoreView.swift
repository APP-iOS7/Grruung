//
//  StoreView.swift
//  Grruung
//
//  Created by 심연아 on 5/1/25.
//

import SwiftUI

struct StoreView: View {
    let tabs = ["치료", "놀이", "회복"]
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            VStack {
                // 상단 탭
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(tabs.indices, id: \.self) { index in
                            Button(action: {
                                withAnimation {
                                    selectedTab = index
                                }
                            }) {
                                VStack {
                                    Text(tabs[index])
                                        .font(.headline)
                                        .foregroundColor(selectedTab == index ? .primary : .secondary)
                                    Capsule()
                                        .fill(selectedTab == index ? Color.primary : Color.clear)
                                        .frame(height: 3)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 15)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // ScrollViewReader로 섹션 이동
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 32) {
                            SectionView(title: "치료", id: "치료", products: treatmentProducts)
                            SectionView(title: "놀이", id: "놀이", products: playProducts)
                            SectionView(title: "회복", id: "회복", products: recoveryProducts)
                        }
                        .padding()
                    }
                    .onChange(of: selectedTab) { newIndex in
                        withAnimation {
                            proxy.scrollTo(tabs[newIndex], anchor: .top)
                        }
                    }
                }

                // 구매 버튼
                
            }
            .navigationTitle("Store")
        }

    }
}

struct SectionView: View {
    let title: String
    let id: String
    let products: [Product]

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
                .bold()
                .id(id) // <-- scrollTo 타겟

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(products) { product in
                    NavigationLink(destination: ProductDetailView(product: product)) {
                        ProductItemView(
                            iconName: product.iconName,
                            name: product.name,
                            price: product.price,
                            bgColor: product.bgColor
                        )
                    }
                    .buttonStyle(PlainButtonStyle()) // 탭뷰랑 겹쳐 눌림 방지용
                }
            }
        }
    }
}


#Preview {
    StoreView()
}
