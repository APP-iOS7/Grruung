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
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 홈 탭
            Tab("홈", systemImage: "house.fill", value: 0) {
                Text("홈")
            }
            
            // 캐릭터 도감 탭
            Tab("캐릭터", systemImage: "teddybear.fill", value: 1) {
                Text("캐릭터 도감")
            }
            
            // 상점 탭
            Tab("상점", systemImage: "cart.fill", value: 2) {
                Text("상점")
            }
            
            // 마이페이지 탭
            Tab("마이페이지", systemImage: "person.circle.fill", value: 3) {
                SettingView()
            }
        }
    }
}

#Preview {
    HomeView()
}
