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
