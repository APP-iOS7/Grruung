//
//  alertView.swift
//  Grruung
//
//  Created by 심연아 on 5/7/25.
//

import SwiftUI

import SwiftUI

struct AlertView: View {
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
                HStack {
                    Button(action: {}) {
                        Text("Yes")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.cyan)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                    }
                    Button(action: {}) {
                        Text("No")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(20)
            .padding(.horizontal, 30)
        }
    }
}

#Preview {
    AlertView()
}
