//
//  StoreTestFetcher.swift
//  Grruung
//
//  Created by mwpark on 5/30/25.
//

import StoreKit

class StoreItemFetcher: ObservableObject {
    @Published var product: Product?

    let productID = "com.smallearedcat.grruung.charDex_unlock_ticket"

    init() {
        Task {
            await loadProduct()
        }
    }

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [productID])
            if let first = products.first {
                await MainActor.run {
                    self.product = first
                }
            }
        } catch {
            print("상품 로딩 실패: \(error)")
        }
    }
}
