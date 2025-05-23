//
//  StoreView.swift
//  Grruung
//
//  Created by 심연아 on 5/1/25.
//

import SwiftUI

struct StoreView: View {
    let tabs = ["전체", "치료", "놀이", "회복", "티켓"]
    @State private var selectedTab = 0
    @State private var coins = 40
    @State private var cash = 12000
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Spacer()

                    HStack(spacing: 200) {
                        //현금
                        HStack(spacing: 8) {
                            Image(systemName: "diamond.fill")
                                .resizable()
                                .frame(width: 20, height: 25)
                                .foregroundColor(.cyan)
                            Text("\(cash)")
                                .font(.title3)
                        }

                        //코인
                        HStack(spacing: 8) {
                            Image(systemName: "circle.fill")
                                .resizable()
                                .frame(width: 25, height: 25)
                                .foregroundColor(.yellow)
                            Text("\(coins)")
                                .font(.title2)
                        }
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 8)
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
                        VStack(alignment: .leading, spacing: 45) {
                            // 각 섹션은 ID로 scrollTo 대상
                            SectionView(title: "전체", id: "전체", products: allProducts, proxy: proxy)
                            SectionView(title: "치료", id: "치료", products: treatmentProducts, proxy: proxy)
                            SectionView(title: "놀이", id: "놀이", products: playProducts, proxy: proxy)
                            SectionView(title: "회복", id: "회복", products: recoveryProducts, proxy: proxy)
                            SectionView(title: "티켓", id: "티켓", products: ticketProducts, proxy: proxy)
                        }
                        .padding()
                    }
                    .onChange(of: selectedTab) { _, newIndex in
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

// 제품 리스트 보여주는 섹션 뷰
struct SectionView: View {
    let title: String
    let id: String
    let products: [GRShopItem]
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
            .id(id)
            .padding(.horizontal)
            
            Divider()
                .frame(height: 1)
                .background(Color.black.opacity(0.7))
                .padding(.vertical, 8)

            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(products) { product in
                    NavigationLink(destination: ProductDetailView(product: product)) {
                        ProductItemView(
                            iconName: product.itemImage,
                            name: product.itemName,
                            price: product.itemPrice,
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
