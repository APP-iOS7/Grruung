//
//  SettingView.swift
//  Grruung
//
//  Created by NoelMacMini on 5/1/25.
//

import SwiftUI

struct SettingView: View {
    @EnvironmentObject private var authService: AuthService
    
    var body: some View {
        NavigationStack {
            List {
                NavigationLink(destination: AnimationTestView()) {
                    Text("고지용 테스트 뷰")
                        .foregroundStyle(.blue)
                }
                NavigationLink(destination: AnimationSecondTestView()) {
                    Text("애니메이션 테스트 2")
                        .foregroundStyle(.green)
                }
                
//                NavigationLink(destination: KimTestView()) {
//                    Text("김준수 테스트 뷰")
//                        .foregroundStyle(.blue)
//                }
                NavigationLink(destination: NoTestView()) {
                    Text("노성경 테스트 뷰")
                        .foregroundStyle(.blue)
                }
//                NavigationLink(destination: ParkTestView()) {
//                    Text("박민우 테스트 뷰")
//                        .foregroundStyle(.blue)
//                }
//                NavigationLink(destination: SimTestView()) {
//                    Text("심연아 테스트 뷰")
//                        .foregroundStyle(.blue)
//                }
//                NavigationLink(destination: CheonTestView()) {
//                    Text("천수빈 테스트 뷰")
//                        .foregroundStyle(.blue)
                
                Button(action: {
                    authService.signOut()
                }) {
                    Text("로그아웃")
                        .foregroundStyle(.red)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("설정")
                        .font(.headline)
                }
            }
        }
    }
}

#Preview {
    SettingView()
}
