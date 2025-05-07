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

/// 메인 탭 뷰 (HomeView를 대체)
struct MainTabView: View {
    // MARK: - 0. 프로퍼티
    @State private var selectedTab: Tab = .home
    
    // 탭 아이템 정의
    enum Tab {
        case home, character, shop, myPage
    }
    
    // MARK: - 1. 바디
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("홈")
                }
                .tag(Tab.home)
            
            Text("캐릭터 도감 화면")
                .tabItem {
                    Image(systemName: "pawprint.fill")
                    Text("캐릭터")
                }
                .tag(Tab.character)
            
            Text("상점 화면")
                .tabItem {
                    Image(systemName: "cart.fill")
                    Text("상점")
                }
                .tag(Tab.shop)
            
            Text("마이페이지 화면")
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("마이페이지")
                }
                .tag(Tab.myPage)
        }
    }
}

#Preview {
    ContentView()
}
