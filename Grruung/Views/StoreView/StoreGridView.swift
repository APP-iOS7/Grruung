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
                            ProductItemView(product: product)
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
    let product: GRShopItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                Image(product.itemImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.black)
            }
            
            Text(product.itemName)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.black)
            
            HStack(spacing: 8) {
                Image(systemName: product.itemCurrencyType.rawValue == "다이아" ? "diamond.fill" : "circle.fill")
                    .foregroundColor(product.itemCurrencyType.rawValue == "다이아" ? .cyan : .yellow)
                
                Text("\(product.itemPrice)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(8)
    }
}

//#Preview {
//    StoreGridView()
//}
