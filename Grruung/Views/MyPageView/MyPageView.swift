//
//  CheonTestView.swift
//  Grruung
//
//  Created by subin on 5/28/25.
//

import SwiftUI

struct MyPageView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 사용자 정보
                    ProfileSection()
                    
                    // 서비스 섹션
                    SeviceGrid()
                    
                    // 설정 섹션
                    SettingsSection()
                }
                .padding()
            }
            .scrollContentBackground(.hidden) // 기본 배경을 숨기고
            .background(
                LinearGradient(colors: [Color(hex: "#FFF5D2"), Color(hex: "FFE38B")], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
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
                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                
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

// MARK: - 서비스 섹션

struct SeviceItem: Identifiable {
    let id = UUID()
    let title: String
    let iconName: String
}

struct SeviceGrid: View {
    let items: [SeviceItem] = [
        .init(title: "상점", iconName: "storefront.fill"),
        .init(title: "애완동물", iconName: "pawprint.fill"),
        .init(title: "동산", iconName: "leaf.fill"),
        .init(title: "들려준 이야기", iconName: "message.fill"),
        .init(title: "이벤트", iconName: "gift.fill"),
    ]
    
    let columns = Array(repeating: GridItem(.flexible()), count: 3)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("서비스")
                .font(.headline)
                .bold()
                .padding(.horizontal)
            
            LazyVGrid(columns: columns, spacing: 15) {
                ForEach(items) { item in
                    NavigationLink {
                        SeviceDestination(for: item)
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
            //            .background(
            //                RoundedRectangle(cornerRadius: 12)
            //                    .stroke(Color.gray.opacity(0.4), lineWidth: 1))
        }
    }
}
// MARK: - 액션 처리 메서드

@ViewBuilder
private func SeviceDestination(for item: SeviceItem) -> some View {
    switch item.title {
    case "상점":
        StoreView()
    case "애완동물":
        HomeView()
    case "동산":
        CharDexView()
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
        .init(title: "공지사항", iconName: "megaphone"),
        .init(title: "고객센터", iconName: "headset"),
        .init(title: "평가 및 리뷰", iconName: "hand.thumbsup"),
        .init(title: "약관 및 정책", iconName: "info.circle")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("설정")
                .font(.headline)
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
            //            .background(
            //                RoundedRectangle(cornerRadius: 12)
            //                    .stroke(Color.gray.opacity(0.4), lineWidth: 1))
        }
    }
}

// MARK: - 액션 처리 메서드

@ViewBuilder
private func settingsDestination(for item: SettingsItem) -> some View {
    switch item.title {
    case "알림":
        MyPageAlarmView()
    case "공지사항":
        NoticeView()
    case "고객센터":
        Text("질문 및 피드백 화면")
    case "평가 및 리뷰":
        Text("App Store 링크 또는 리뷰 화면")
    case "약관 및 정책":
        Text("앱 정보 화면")
    default:
        Text("준비 중")
    }
}

// MARK: - Preview

#Preview {
    MyPageView()
}

