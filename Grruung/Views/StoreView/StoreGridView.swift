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
    @State private var isLimitedItemVisible = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                Image(product.itemImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.black)
                
                if product.itemTag == ItemTag.limited {
                    Text("한정")
                        .font(.caption2)
                        .bold()
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.red)
                        .clipShape(Capsule())
                        .opacity(isLimitedItemVisible ? 1 : 0)
                        .onAppear {
                            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                isLimitedItemVisible.toggle()
                            }
                        }
                }
            }
            
            Text(product.itemName)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.black)
            
            HStack(spacing: 8) {
                Image(systemName: product.itemCurrencyType.rawValue == ItemCurrencyType.diamond.rawValue ? "diamond.fill" : "circle.fill")
                    .foregroundColor(product.itemCurrencyType.rawValue == ItemCurrencyType.diamond.rawValue ? .cyan : .yellow)
                
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
