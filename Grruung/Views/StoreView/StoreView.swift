//
//  StoreView.swift
//  Grruung
//
//  Created by 심연아 on 5/1/25.
//

import SwiftUI

struct StoreView: View {
    let tabs = ["Tab 1", "Tab 2", "Tab 3", "Tab 4", "Tab 5"]
    let tabImages = ["pill", "fork.knife", "heart.circle.fill", "sun.max.fill", "camera"]
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(tabs.indices) { index in
                            Button(action: { withAnimation {
                                selectedTab = index
                            }}) {
                                VStack {
                                    Text(tabs[index]).font(.headline)
                                        .foregroundColor(selectedTab == index ? .white : .gray)
                                    Capsule()
                                        .fill(selectedTab == index ? Color.white : Color.clear)
                                        .frame(height: 3)
                                } .padding(.vertical, 8)
                                    .padding(.horizontal, 15)
                            }
                        }
                    }.padding(.horizontal)
                }
                Spacer()
                
                Image(systemName: tabImages[selectedTab]).resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .navigationTitle("Store")
        }
    }
}

#Preview {
    StoreView()
        .preferredColorScheme(.dark)
}
