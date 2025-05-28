//
//  ProductDetailView.swift
//  Grruung
//
//  Created by 심연아 on 5/12/25.
//

//
//  ProductDetailView.swift
//  Grruung
//
//  Created by 심연아 on 5/12/25.
//

import SwiftUI

struct ProductDetailView: View {
    let product: GRShopItem
    @State private var quantity: Int = 1
    @State private var showAlert = false
    @State private var isOutOfLimitedQuantity: Bool = false
    @EnvironmentObject var userInventoryViewModel: UserInventoryViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 제품명 + 가격
                    VStack(alignment: .leading, spacing: 8) {
                        Text(product.itemName)
                            .font(.largeTitle)
                            .bold()
                        HStack(spacing: 8) {
                            if product.itemCurrencyType.rawValue == "다이아" {
                                Image(systemName: "diamond.fill")
                                    .resizable()
                                    .frame(width: 20, height: 25)
                                    .foregroundColor(.cyan)
                            } else {
                                Image(systemName: "circle.fill")
                                    .resizable()
                                    .frame(width: 25, height: 25)
                                    .foregroundColor(.yellow)
                            }
                            Text("\(product.itemPrice)")
                                .font(.title)
                                .bold()
                        }
                    }
                    .padding(.horizontal)
                    
                    // 제품 이미지
                    Image(product.itemImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .padding()
                    
                    // 설명
                    Text(product.itemDescription)
                        .font(.body)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            // 수량 선택
            HStack {
                Button {
                    if quantity > 1 { quantity -= 1 }
                } label: {
                    Image(systemName: "minus.circle")
                        .font(.title2)
                }
                
                Text("\(quantity)")
                    .font(.title)
                    .padding(.horizontal, 16)
                
                Button {
                    if quantity < product.limitedQuantity {
                        quantity += 1
                    } else {
                        showAlert = true
                    }
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.title2)
                }
                .alert("한정 수량 초과", isPresented: $showAlert) {
                    Button("확인", role: .cancel) { }
                } message: {
                    Text("더 이상 구매하실 수 없습니다.")
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            
            // 하단 버튼
            Button(action: {
                showAlert = true
            }) {
                Text("ADD TO CART")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.cyan)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
        .sheet(isPresented: $showAlert) {
            AlertView(product: product, quantity: quantity, isPresented: $showAlert)
                .environmentObject(userInventoryViewModel)
                .environmentObject(userViewModel)
                .environmentObject(authService)
        }
    }
}


#Preview {
    if let product = treatmentProducts.first {
        ProductDetailView(product: product)
    } else {
        Text("샘플 데이터 없음")
    }
}
