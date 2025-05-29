//
//  ProfileDetailView.swift
//  Grruung
//
//  Created by subin on 5/29/25.
//

import SwiftUI

struct ProfileDetailView: View {
    var body: some View {
        ZStack(alignment: .top) {
            Color.gray.opacity(0.2)
                .ignoresSafeArea(.all)
            
            VStack(spacing: 20) {
                // 프로필 카드 영역
                VStack(spacing: 12) {
                    ZStack(alignment: .bottomTrailing) {
                        Image("CatLion")
                            .resizable()
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                            )
                        
                        // 카메라 버튼
                        Button(action: {
                            print("프로필 사진 변경")
                        }) {
                            Image(systemName: "camera.fill")
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.green)
                                .clipShape(Circle())
                        }
                        .offset(x: 7, y: 7)
                    }
                    .padding(.top)
                    
                    // 이름 편집 버튼
                    Button {
                        print("이름 편집")
                    } label: {
                        HStack(spacing: 6) {
                            Text("냥냥스")
                                .bold()
                                .foregroundColor(.black)
                            Image(systemName: "pencil")
                                .foregroundColor(.gray)
                        }
                        .frame(width: 310, height: 50)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
                .frame(width: 360, height: 300)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 17))
                .padding(.top)
                
                // 리스트 항목들
                VStack(spacing: 1) {
                    profileRow(icon: "doc.text", title: "청구서")
                    profileRow(icon: "gift.fill", title: "기프트 카드 또는 코드")
                    profileRow(icon: "link", title: "연결된 계정을 변경하기")
                    profileRow(icon: "arrow.up.arrow.down", title: "기기 데이터 마이그레이션")
                    profileRow(icon: "rectangle.portrait.and.arrow.right", title: "로그아웃")
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 17))
                .padding(.horizontal)
                
                // 계정 삭제 버튼
                Button(action: {
                    print("계정 삭제")
                }) {
                    Label("계정 삭제", systemImage: "trash")
                        .foregroundColor(.red)
                        .padding()
                }
                
                Spacer()
            }
        }
    }
// MARK: - 액션처리 메서드
    
    // 리스트 항목 뷰 재사용 컴포넌트
    @ViewBuilder
    func profileRow(icon: String, title: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 24)
            Text(title)
                .foregroundColor(.black)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
    }
}

// MARK: - Preview
#Preview {
    ProfileDetailView()
}
