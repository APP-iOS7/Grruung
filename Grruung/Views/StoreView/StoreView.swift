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
    @State private var showAlert = false
    
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
                                    Text(tabs[index])
                                        .font(.headline)
                                        .foregroundColor(selectedTab == index ? .primary : .secondary)
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
                
                Group {
                    if selectedTab == 0 {
                        StoreGridView()
                            .transition(.opacity)
                    } else {
                        Image(systemName: tabImages[selectedTab])
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
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
            }
            .navigationTitle("Store")
        }
        if showAlert {
            AlertView(isPresented: $showAlert)
                .transition(.opacity)
                .zIndex(1)
        }
    }
}
#Preview {
    StoreView()
}
