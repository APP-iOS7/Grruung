//
//  alertView.swift
//  Grruung
//
//  Created by 심연아 on 5/7/25.
//

import SwiftUI

struct AlertView: View {
    @Binding var isPresented: Bool // 팝업 제어용
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // 아이콘
                Circle()
                    .fill(Color.cyan)
                    .frame(width: 75, height: 75)
                    .overlay(
                        Image(systemName: "ticket.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    )
                
                // 제목
                Text("[10 주얼]")
                    .font(.headline)
                    .foregroundColor(.black)
                
                // 설명
                Text("구매할까요?")
                    .font(.subheadline)
                    .foregroundColor(.black.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // 버튼들
                HStack(spacing: 12) {
                    // YES 버튼
                    AnimatedCancelButton {
                        withAnimation {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                isPresented = false
                            }
                        }
                    }
                    // NO 버튼
                    AnimatedConfirmButton {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            isPresented = false
                        }
                    }
                }
                .frame(height: 50)
                .padding(.horizontal)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(20)
            .padding(.horizontal, 30)
            .frame(maxWidth: 300)
        }
    }
}

//
//#Preview {
//    AlertView()
//}
