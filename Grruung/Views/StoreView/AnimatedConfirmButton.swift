//
//  AnimatedConfirmButton.swift
//  Grruung
//
//  Created by 심연아 on 5/7/25.
//

import SwiftUI

import SwiftUI

struct AnimatedConfirmButton: View {
    var onConfirm: () -> Void

    @State private var tap = false
    @State private var press = false
    @State private var alterState = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: alterState ? 20 : 0)
                .frame(width: alterState ? 500 : 0, height: alterState ? 500 : 0)
                .foregroundColor(Color.green)
                .blur(radius: alterState ? 5 : 20)
                .opacity(alterState ? 0 : 1)

            Text("Yes")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(alterState ? .clear : (tap ? Color.blue : .white))
                .frame(width: 130, height: alterState ? 130 : 50)
                .background(
                    ZStack {
                        Color.blue.opacity(0.7)
                        RoundedRectangle(cornerRadius: alterState ? 100 : 16)
                            .foregroundColor(.white)
                            .blur(radius: 2)
                            .offset(x: -2, y: -2)
                        RoundedRectangle(cornerRadius: alterState ? 100 : 16)
                            .fill(
                                LinearGradient(
                                    colors: alterState ? [.cyan, .green] : [.blue.opacity(0.6), .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .padding(2)
                            .blur(radius: 2)
                            .offset(x: 2, y: 2)
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: alterState ? 100 : 16))
                .scaleEffect(alterState ? 0 : (tap ? 0.92 : 1))
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if press { press = false }
                            tap = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                if tap {
                                    press = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        alterState = true
                                        onConfirm()
                                    }
                                }
                            }
                        }
                        .onEnded { _ in
                            if press == false {
                                tap = false
                            }
                        }
                )
                .opacity(alterState ? 0 : 1)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.5), value: alterState)
    }
}

struct AnimatedCancelButton: View {
    var onCancel: () -> Void

    var body: some View {
        Button(action: {
            withAnimation {
                // 약간의 딜레이 넣음
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    onCancel()
                }
            }
        }) {
            Text("No")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 130, height: 50)
                .background(
                    ZStack {
                        // 배경색 기본
                        Color(red: 0.85, green: 0.4, blue: 0.4)

                        // 윗부분 하이라이트 선
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.5),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1.5
                            )

                        // 입체감용 위 blur
                        RoundedRectangle(cornerRadius: 16)
                            .foregroundColor(.white)
                            .blur(radius: 2)
                            .offset(x: -2, y: -2)

                        // 입체감용 아래 blur
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.9, green: 0.5, blue: 0.5),
                                             Color(red: 0.85, green: 0.4, blue: 0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .padding(2)
                            .blur(radius: 2)
                            .offset(x: 2, y: 2)
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .scaleEffect(1.0)
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 2, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
