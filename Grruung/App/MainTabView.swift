//
//  MainTabView.swift
//  Grruung
//
//  Created by KimJunsoo on 5/30/25.
//

import SwiftUI

// 메인 탭 뷰 (HomeView를 대체)
struct MainTabView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var characterService: FirebaseService
    @State private var selectedTab = 0
    
    // 탭 아이템 정의
    enum TabItem: String, CaseIterable {
        case home = "홈"
        case charDex = "캐릭터"
        case store = "상점"
        case myPage = "설정"
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .charDex: return "teddybear.fill"
            case .store: return "cart.fill"
            case .myPage: return "person.circle.fill"
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 홈 탭
            HomeView()
                .tabItem {
                    Label(TabItem.home.rawValue, systemImage: TabItem.home.icon)
                }
                .tag(0)
            
            // 캐릭터 도감 탭
            CharDexView()
                .tabItem {
                    Label(TabItem.charDex.rawValue, systemImage: TabItem.charDex.icon)
                }
                .tag(1)
            
            // 상점 탭
            StoreView()
                .tabItem {
                    Label(TabItem.store.rawValue, systemImage: TabItem.store.icon)
                }
                .tag(2)
            
            // 마이페이지 탭
            SettingView()
                .tabItem {
                    Label(TabItem.myPage.rawValue, systemImage: TabItem.myPage.icon)
                }
                .tag(3)
        }
        .onAppear {
            // 탭 아이템 모양 설정
            setupTabBarAppearance()
        }
    }
    
    // 탭바 외관 설정
    private func setupTabBarAppearance() {
        // iOS 15 이상에서는 UITabBar.appearance() 대신 아래 방식 사용
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        // 원하는 경우 탭바 색상 등 조정
        appearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
