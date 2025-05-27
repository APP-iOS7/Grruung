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
    @State private var gold = 0
    @State private var diamond = 0
    
    @StateObject var userInventoryViewModel = UserInventoryViewModel()
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var authService: AuthService
    @State var realUserId = ""
    
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
                            Text("\(diamond)")
                                .font(.title3)
                        }
                        
                        //코인
                        HStack(spacing: 8) {
                            Image(systemName: "circle.fill")
                                .resizable()
                                .frame(width: 25, height: 25)
                                .foregroundColor(.yellow)
                            Text("\(gold)")
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
                                .environmentObject(userInventoryViewModel)
                            SectionView(title: "치료", id: "치료", products: treatmentProducts, proxy: proxy)
                                .environmentObject(userInventoryViewModel)
                            SectionView(title: "놀이", id: "놀이", products: playProducts, proxy: proxy)
                                .environmentObject(userInventoryViewModel)
                            SectionView(title: "회복", id: "회복", products: recoveryProducts, proxy: proxy)
                                .environmentObject(userInventoryViewModel)
                            SectionView(title: "티켓", id: "티켓", products: ticketProducts, proxy: proxy)
                                .environmentObject(userInventoryViewModel)
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
        } //
        .onAppear {
            // 상점 진입 시 사용자 인벤토리 미리 로드
            Task {
                realUserId = authService.currentUserUID.isEmpty ? "23456" : authService.currentUserUID
                
                do {
                    try await userViewModel.fetchUser(userId: realUserId)
                    print("[유저로드] \(realUserId) user 로드 완료")
                    
                    gold = userViewModel.user?.gold ?? 0
                    diamond = userViewModel.user?.diamond ?? 0
                } catch {
                    print("[유저로드] 유저 로드 실패: \(error.localizedDescription)")
                }
                
                do {
                    try await userInventoryViewModel.fetchInventories(userId: realUserId)
                    print("[상점진입] 인벤토리 미리 로드 완료")
                } catch {
                    print("[상점진입] 인벤토리 로드 실패: \(error.localizedDescription)")
                }
                
                
            }
        }
        .environmentObject(userInventoryViewModel)
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
    
    @EnvironmentObject var userInventoryViewModel: UserInventoryViewModel
    
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
                    NavigationLink(destination: ProductDetailView(product: product)
                        .environmentObject(userInventoryViewModel))
                    {
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
        .environmentObject(AuthService())
        .environmentObject(UserViewModel())
}
