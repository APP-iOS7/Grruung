//
//  ContentView.swift
//  Grruung
//
//  Created by NoelMacMini on 4/30/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authService: AuthService
    var body: some View {
        Group {
            if authService.authenticationState == .authenticated {
                // 로그인된 상태 = 홈 화면 표시
                MainTabView()
            } else {
                // 비로그인 상태 = 로그인 화면 표시
                LoginView()
            }
        }
        .onAppear {
            // 앱 시작 시 자동으로 로그인 상태 확인
            authService.checkAuthState()
            
            // TODO: 이미 로그인된 상태라면 캐릭터 정보 로드
        }
        .onChange(of: authService.authenticationState) { oldState, newState in
            if oldState == .unauthenticated && newState == .authenticated {
                // 로그인 성공 시
                if let userId = authService.user?.uid {
                    print("로그인 \(Bool(!userId.isEmpty) ? "성공" : "실패")")
                    // TODO: 사용자 정보 로드
                    // TODO: 캐릭터 정보 로드
                }
            } else if oldState == .authenticated && newState == .unauthenticated {
                // 로그아웃 시
                // TODO: 사용자정보 리셋
            }
        }
    }
}

// 메인 탭 뷰 (HomeView를 대체)
struct MainTabView: View {
    // @State private var selectedTab: Tab = .home
    @State private var selectedTab = 0
    
    // 탭 아이템 정의
//    enum Tab {
//        case home, test, character, shop, myPage
//    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 홈 탭
            Tab("홈", systemImage: "house.fill", value: 0) {
                HomeView()
            }
            
            // 테스트 탭
            Tab("테스트", systemImage: "house.fill", value: 1) {
                HomeTestView()
            }
            
            // 캐릭터 도감 탭
            Tab("캐릭터", systemImage: "teddybear.fill", value: 2) {
                CharDexView()
            }
            
            // 상점 탭
            Tab("상점", systemImage: "cart.fill", value: 3) {
                StoreView()
            }
            
            // 마이페이지 탭
            Tab("마이페이지", systemImage: "person.circle.fill", value: 4) {
                SettingView()
            }
        }
    }
}

#Preview {
    ContentView()
}
