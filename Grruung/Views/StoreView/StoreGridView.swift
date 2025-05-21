//
//  StoreGridView.swift
//  Grruung
//
//  Created by 심연아 on 5/12/25.
//

import SwiftUI

struct StoreGridView: View {
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
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
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
        }
    }
}

struct ProductItemView: View {
    let iconName: String
    let name: String
    let price: Int
    let bgColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(bgColor)
                    .frame(height: 90)

                Image(systemName: iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.black)
            }

            Text(name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.black)

            Text("\(price) 코인")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(8)
    }
}

//#Preview {
//    StoreGridView()
//}
