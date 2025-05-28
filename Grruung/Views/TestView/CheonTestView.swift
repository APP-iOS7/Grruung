//
//  CheonTestView.swift
//  Grruung
//
//  Created by subin on 5/28/25.
//

import SwiftUI

struct CheonTestView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 사용자 정보
                    ProfileSection()
                    
                    // 추천 아이콘 섹션
                    RecommendedGrid()
                    
                    // 설정 섹션
                    SettingsSection()
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
        .tabItem {
            Image(systemName: "ellipsis.circle")
            Text("더보기")
        }
    }
}

// MARK: - 프로필 섹션
struct ProfileSection: View {
    var body: some View {
        HStack(spacing: 30) {
            Image("CatLion") 
                .resizable()
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 3) {
                Text("냥냥이")
                    .font(.title2)
                    .bold()
            }
            Spacer()
        }
    }
}

// MARK: - 추천 아이콘 그리드
struct RecommendedItem: Identifiable {
    let id = UUID()
    let title: String
    let imageName: String
}

struct RecommendedGrid: View {
    let items: [RecommendedItem] = [
        .init(title: "상점", imageName: "storefront.fill"),
        .init(title: "애완동물", imageName: "pawprint.fill"),
        .init(title: "동산", imageName: "leaf.fill"),
        .init(title: "들려준 이야기", imageName: "message.fill"),
        .init(title: "이벤트", imageName: "gift.fill"),
        .init(title: "배경화면", imageName: "photo.fill"),
    ]
    
    let columns = Array(repeating: GridItem(.flexible()), count: 3)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("추천")
                .font(.title2)
                .bold()
                .padding(.horizontal)
            
            LazyVGrid(columns: columns, spacing: 15) {
                ForEach(items) { item in
                    VStack {
                        Image(systemName: item.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.gray)
                            .padding()
                        
                        Text(item.title)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1))
        }
    }
}

// MARK: - 설정 섹션
struct SettingsSection: View {
    let settings = [
        ("알림", "bell"),
        ("인증 관리", "checkmark.shield"),
        ("질문&피드백", "questionmark.message"),
        ("평가 및 리뷰", "hand.thumbsup"),
        ("정보", "info.circle"),
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("설정")
                .font(.title2)
                .bold()
                .padding(.horizontal)
                .padding(.top)
            
            VStack {
                ForEach(settings, id: \.0) { item in
                    HStack {
                        Image(systemName: item.1)
                            .foregroundColor(.accentColor)
                            .frame(width: 24)
                        Text(item.0)
                        Spacer()
                    }
                    .padding()
                    
                    // 마지막 아이템 아래는 Divider 없게 처리
                    if item.0 != settings.last?.0 {
                        Divider()
                            .padding(.horizontal)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1))
        }
    }
}

#Preview {
    CheonTestView()
}
