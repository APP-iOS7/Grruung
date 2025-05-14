//
//  ProductDetailView.swift
//  Grruung
//
//  Created by 심연아 on 5/12/25.
//

import SwiftUI

struct ProductDetailView: View {
    let product: Product
    @State private var showAlert = false

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea() // 배경색 추가

            VStack {
                Spacer()

                    Image(systemName: product.iconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .padding()
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 1)

                    Text(product.name)
                        .font(.title)
                        .fontWeight(.bold)

                    Text("₩\(product.price)")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                Text(product.description)
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.white) // 박스 배경색
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)

                    Spacer()
                    Button(action: {
                        withAnimation {
                            showAlert = true
                        }
                    }) {
                        Text("상품 구매")
                            .font(.title3)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.cyan)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(radius: 1)
                    }
                    .padding(.horizontal)
                    .padding(.top, 100)

            }

            if showAlert {
                AlertView(product: product, isPresented: $showAlert)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .navigationTitle("상세보기")
    }
}

#Preview {
    if let product = treatmentProducts.first {
            ProductDetailView(product: product)
        } else {
            Text("샘플 데이터 없음")
        }
}


