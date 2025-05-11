//
//  HomeView.swift
//  Grruung
//
//  Created by NoelMacMini on 5/1/25.
//

import SwiftUI

struct HomeView: View {
    // MARK: - Properties
    @EnvironmentObject private var authService: AuthService
    let bars: [(icon: String, color: Color, width: CGFloat)] = [
        ("🍴", Color.orange, 80),
        ("♥️", Color.red, 120),
        ("⚡️", Color.yellow, 100)
    ]
    let buttons = ["🛍️", "🛒", "⛰️"]
    let icons = ["📖", "💬", "🔒"]
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 20)
                        .frame(height: 30)
                        .foregroundColor(Color.gray.opacity(0.1))
                    
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "E8E8E9"), Color(hex: "999999")]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 200, height: 30)
                    .cornerRadius(20)
                }
                .frame(height: 20)
                .padding()
                .padding(.top, 50)
            }
            .frame(height: 150)
            
            HStack {
                VStack(spacing: 10) {
                    ForEach(buttons, id: \.self) { button in
                        Button(action: {
                            print("\(button) 버튼 클릭")
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(Color.gray.opacity(0.2))
                                Text(button)
                            }
                        }
                    }
                }
                
                Image("CatLion")
                    .resizable()
                    .frame(width: 200, height: 200)
                
                VStack(spacing: 10) {
                    ForEach(icons, id: \.self) { icon in
                        Button(action: {
                            print("\(icon) 버튼 클릭")
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(Color.gray.opacity(0.2))
                                Text(icon)
                            }
                        }
                    }
                }
            }
            Spacer()
                .padding(.top, 10)
            
            VStack(spacing: 5) {
                ForEach(bars, id: \.icon) { item in
                    HStack(spacing: 15) {
                        Text(item.icon)
                            .
                        font(.system(size: 14, weight: .medium))
                        
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 10)
                                .frame(height: 10)
                                .foregroundColor(Color.gray.opacity(0.1))
                            
                            RoundedRectangle(cornerRadius: 10)
                                .frame(width: item.width, height: 10)
                                .foregroundColor(item.color)
                        }
                        .frame(width: 170, height: 10)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        
        HStack(spacing: 15) {
            ForEach(0..<4) { _ in
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: 75, height: 75)
                        .foregroundColor(Color.gray.opacity(0.1))
                    Image(systemName: "lock.fill")
                }
            }
            .padding(.top, 70)
        }
    }
}

#Preview {
    HomeView()
}
