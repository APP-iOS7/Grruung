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
    @State private var selectedTab = 0
    let buttons = ["backpack.fill", "cart.fill", "mountain.2.fill"]
    let icons = ["book.fill", "microphone.fill", "lock.fill"]
    let bars: [(icon: String, color: Color, width: CGFloat)] = [
        ("fork.knife", Color.orange, 80),
        ("heart.fill", Color.red, 120),
        ("bolt.fill", Color.yellow, 100)
    ]
    
    var body: some View {
        
        // 상단 경험치 바
        VStack {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 20)
                        .frame(height: 30)
<<<<<<< HEAD
                        .foregroundColor(Color.gray.opacity(0.2))
                    
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "6159A0"), Color(hex: "6159A0")]),
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
            
            // 캐릭터 왼쪽 버튼
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
                                Image(systemName: button)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                // 캐릭터 이미지 추가
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
                                Image(systemName: icon)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            Spacer()
                .padding(.top, 10)
            
            
            // 캐릭터 오른쪽 버튼
            VStack(spacing: 5) {
                ForEach(bars, id: \.icon) { bar in
                    HStack(spacing: 15) {
                        Image(systemName:bar.icon)
                            .foregroundColor(bar.color)
                        
                        
                        // 펫 상태
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 10)
                                .frame(height: 10)
                                .foregroundColor(Color.gray.opacity(0.1))
                            
                            RoundedRectangle(cornerRadius: 10)
                                .frame(width: bar.width, height: 10)
                                .foregroundColor(bar.color)
                        }
                        .frame(width: 170, height: 10)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        
        // 활동 탭
        HStack(spacing: 15) {
            ForEach(0..<4) { _ in
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: 75, height: 75)
                        .foregroundColor(Color.gray.opacity(0.1))
                    Image(systemName: "lock.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding(.top, 70)
        }
        
        TabView(selection: $selectedTab) {
            // 홈 탭
            Tab("홈", systemImage: "house.fill", value: 0) {
                //  Text("Home")
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
