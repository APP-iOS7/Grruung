//
//  CheonTestView.swift
//  Grruung
//
//  Created by subin on 5/28/25.
//

import SwiftUI

struct CheonTestView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 사용자 정보
                    ProfileSection()
                    
                    // 추천 섹션
                    RecommendedGrid()
                    
                    // 설정 섹션
                    SettingsSection()
                }
                .padding()
            }
        }
    }
}

// MARK: - 프로필 섹션

struct ProfileSection: View {
    var body: some View {
        NavigationLink {
            ProfileDetailView()
        } label: {
            HStack(spacing: 30) {
                Image("CatLion")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("냥냥이")
                        .font(.title2)
                        .bold()
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 추천 섹션

struct RecommendedItem: Identifiable {
    let id = UUID()
    let title: String
    let iconName: String
}

struct RecommendedGrid: View {
    let items: [RecommendedItem] = [
        .init(title: "상점", iconName: "storefront.fill"),
        .init(title: "애완동물", iconName: "pawprint.fill"),
        .init(title: "동산", iconName: "leaf.fill"),
        .init(title: "들려준 이야기", iconName: "message.fill"),
        .init(title: "이벤트", iconName: "gift.fill"),
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
                    NavigationLink {
                        recommendedDestination(for: item)
                    } label: {
                        VStack {
                            Image(systemName: item.iconName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.black)
                                .padding()
                            
                            Text(item.title)
                                .font(.caption)
                                .foregroundColor(.black)
                        }
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
// MARK: - 액션 처리 메서드

@ViewBuilder
private func recommendedDestination(for item: RecommendedItem) -> some View {
    switch item.title {
    case "상점":
        StoreView()
    case "애완동물":
        HomeView()
    default:
        Text("준비 중")
    }
}

// MARK: - 설정 섹션

struct SettingsItem: Identifiable {
    let id = UUID()
    let title: String
    let iconName: String
}

struct SettingsSection: View {
    let settings: [SettingsItem] = [
        .init(title: "알림", iconName: "bell"),
        .init(title: "인증 관리", iconName: "checkmark.shield"),
        .init(title: "질문&피드백", iconName: "questionmark.message"),
        .init(title: "평가 및 리뷰", iconName: "hand.thumbsup"),
        .init(title: "정보", iconName: "info.circle")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("설정")
                .font(.title2)
                .bold()
                .padding(.horizontal)
                .padding(.top)
            
            VStack {
                ForEach(settings) { item in
                    NavigationLink {
                        settingsDestination(for: item)
                    } label: {
                        HStack {
                            Image(systemName: item.iconName)
                                .foregroundColor(.black)
                                .frame(width: 24)
                            
                            Text(item.title)
                                .foregroundColor(.black)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1))
        }
    }
}

// MARK: - 액션 처리 메서드

@ViewBuilder
private func settingsDestination(for item: SettingsItem) -> some View {
    switch item.title {
    case "알림":
        Text("알림 설정 화면")
    case "인증 관리":
        Text("인증 관리 화면")
    case "질문&피드백":
        Text("질문 및 피드백 화면")
    case "평가 및 리뷰":
        Text("App Store 링크 또는 리뷰 화면")
    case "정보":
        Text("앱 정보 화면")
    default:
        Text("준비 중")
    }
}

// MARK: - Preview

#Preview {
    CheonTestView()
}
