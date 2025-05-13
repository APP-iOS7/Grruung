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

                // ScrollViewReader로 섹션 이동 제목 누르면 거기로 이동
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 45) {
                            SectionView(title: "치료", id: "치료", products: treatmentProducts, proxy: proxy)
                            SectionView(title: "놀이", id: "놀이", products: playProducts, proxy: proxy)
                            SectionView(title: "회복", id: "회복", products: recoveryProducts, proxy: proxy)
                        }
                        .padding()
                    }
                    .onChange(of: selectedTab) { newIndex in
                        withAnimation {
                            proxy.scrollTo(tabs[newIndex], anchor: .top)
                        }
                    }
                }
            }
            .navigationTitle("Store")
        }
    }
}

struct SectionView: View {
    let title: String
    let id: String
    let products: [Product]
    let proxy: ScrollViewProxy

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: {
                withAnimation {
                    proxy.scrollTo(id, anchor: .top)
                }
            }) {
                Text(title)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.primary)
            }
            .id(id) // scroll 대상은 여전히 유지
            .padding(.horizontal)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(products) { product in
                    NavigationLink(destination: ProductDetailView(product: product)) {
                        ProductItemView(
                            iconName: product.iconName,
                            name: product.name,
                            price: product.price,
                            bgColor: product.bgColor
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

#Preview {
    StoreView()
}
