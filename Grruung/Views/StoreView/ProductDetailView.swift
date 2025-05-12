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
        VStack(spacing: 20) {
            Image(systemName: product.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)

            Text(product.name)
                .font(.title)
                .fontWeight(.bold)

            Text("가격: \(product.price)")
                .font(.headline)

            Spacer()
            
        }
        
        .padding()
        Button(action: {
            withAnimation {
                showAlert = true
            }
        }) {
            Text("상품 구매")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.cyan)
                .foregroundColor(.black)
                .cornerRadius(12)
                .padding(.horizontal)
        }
        .navigationTitle("상세보기")
        if showAlert {
            AlertView(isPresented: $showAlert)
                .transition(.opacity)
                .zIndex(1)
        }
    }
}


