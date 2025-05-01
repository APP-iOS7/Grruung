//
//  TestView.swift
//  Grruung
//
//  Created by NoelMacMini on 5/1/25.
//

import SwiftUI

struct ParkTestView: View {
    let items = Array(1...10)
        
        let columns = [
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
        
        var body: some View {
            NavigationStack {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(items, id: \.self) { item in
                            NavigationLink(value: item) {
                                VStack {
                                    Text("Item \(item)")
                                        .frame(height: 180)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.gray.opacity(0.5))
                                        .cornerRadius(10)
                                        .foregroundColor(.white)
                                    
                                    Text("구릉이")
                                        .foregroundStyle(.black)
                                        .bold()
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Text("1살 (02월 14일 생)")
                                        .foregroundStyle(.gray)
                                        .font(.caption)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                    .padding()
                }
                .navigationTitle("캐릭터 도감")
                .navigationDestination(for: Int.self) { value in
                    DetailView()
                }
            }
        }
}

#Preview {
    ParkTestView()
}


struct DetailView: View {
    var body: some View {
        
    }
}
