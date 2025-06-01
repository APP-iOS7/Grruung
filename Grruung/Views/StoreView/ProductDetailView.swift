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
    @State private var isRotating = false
    @State private var isBouncing = false
    @EnvironmentObject var userInventoryViewModel: UserInventoryViewModel
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
                        
                        Text("₩\(product.itemPrice)")
                            .font(.title)
                            .bold()
                    }
                    .padding(.horizontal)
                    
                    // 제품 이미지
                    ZStack {
                        // 바닥 그림자처럼 보이는 배경 타원형
                        Ellipse()
                            .fill(Color.black.opacity(0.1))
                            .frame(width: 140, height: 20)
                            .offset(y: 90)

                        // 메인 이미지
                        Image(product.itemImage)
                            .resizable()
                            .renderingMode(.original)
                            .scaledToFit()
                            .frame(width: 180, height: 180)
                            .rotationEffect(.degrees(isRotating ? 3 : -3))
                            .offset(y: isBouncing ? -2 : 2)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                                    isRotating = true
                                }
                                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                    isBouncing = true
                                }
                            }
                    }
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
                    quantity += 1
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.title2)
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
