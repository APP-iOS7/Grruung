//
//  ContentView.swift
//  Grruung
//
//  Created by NoelMacMini on 4/30/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var characterDexViewModel: CharacterDexViewModel
    
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
            Task {
                // 앱 시작 시 자동으로 로그인 상태 확인
                authService.checkAuthState()
                
                // UID가 세팅됐다고 가정하고 사용
                if authService.currentUserUID != "" {
                    await characterDexViewModel.initialize(userId: authService.currentUserUID)
                } else {
                    print("❌ 로그인된 사용자 없음, 동산뷰 초기화 안 됨")
                }
            }
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

#Preview {
    ContentView()
}
