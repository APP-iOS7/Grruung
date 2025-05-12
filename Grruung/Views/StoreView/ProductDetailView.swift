//
//  ProductDetailView.swift
//  Grruung
//
//  Created by 심연아 on 5/12/25.
//

import SwiftUI

struct ProductDetailView: View {
    let product: Product

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
        .navigationTitle("상세보기")
    }
}


