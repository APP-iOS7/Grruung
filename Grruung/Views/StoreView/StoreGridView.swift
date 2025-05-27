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
                                iconName: product.itemImage,
                                name: product.itemName,
                                price: product.itemPrice,
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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
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
