//
//  HomeView.swift
//  Grruung
//
//  Created by NoelMacMini on 5/1/25.
//

import SwiftUI

struct HomeView: View {
    // MARK: - Properties
    @EnvironmentObject private var authService: AuthService
    @State private var progressValue: CGFloat = 0.65 // 진행률을 동적으로 관리
    @State private var showStoreView: Bool = false
    
    let buttons = ["backpack.fill", "cart.fill", "mountain.2.fill"]
    let icons = ["book.fill", "microphone.fill", "lock.fill"]
    
    // 캐릭터 상태 정보를 구조체로 관리
    let stats: [(icon: String, color: Color, value: CGFloat)] = [
        ("fork.knife", Color.orange, 0.7),
        ("heart.fill", Color.red, 0.9),
        ("bolt.fill", Color.yellow, 0.8)]
    
    // 하단 아이템 정보
    let lockedItems: [(isLocked: Bool, icon: String?, name: String)] = [
        (true, nil, "잠금1"),
        (true, nil, "잠금2"),
        (true, nil, "잠금3"),
        (true, nil, "잠금4")]
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 레벨 프로그레스 바
                levelProgressBar
                
                // 메인 캐릭터 섹션
                characterSection
                
                Spacer()
                
                // 상태 바 섹션
                statsSection
                
                Spacer()
                
                // 아이템 그리드
                itemsGrid
            }
            .padding()
            .navigationTitle("나의 캐릭터")
            .toolbar {
            }
        }
    }
    
    // MARK: - UI Components
    
    // 레벨 프로그레스 바
    private var levelProgressBar: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("레벨 2")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                ZStack(alignment: .leading) {
                    // 배경 바
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 30)
                    
                    // 진행 바
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: "6159A0"))
                        .frame(width: UIScreen.main.bounds.width * 0.7 * progressValue, height: 30)
                }
            }
        }
        .padding(.top, 10)
    }
    
    // 캐릭터 섹션
    private var characterSection: some View {
        HStack {
            // 왼쪽 버튼들
            VStack(spacing: 15) {
                ForEach(buttons, id: \.self) { button in
                    iconButton(systemName: button)
                }
            }
            
            Spacer()
            
            // 캐릭터 이미지
            Image("CatLion")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 200)
            
            Spacer()
            
            // 오른쪽 버튼들
            VStack(spacing: 15) {
                ForEach(icons, id: \.self) { icon in
                    iconButton(systemName: icon)
                }
            }
        }
    }
    
    // 상태 바 섹션
    private var statsSection: some View {
        VStack(spacing: 12) {
            ForEach(stats, id: \.icon) { stat in
                HStack(spacing: 15) {
                    // 아이콘
                    Image(systemName: stat.icon)
                        .foregroundColor(stat.color)
                        .frame(width: 30)
                    
                    // 상태 바
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .frame(height: 12)
                            .foregroundColor(Color.gray.opacity(0.1))
                        
                        RoundedRectangle(cornerRadius: 10)
                            .frame(width: UIScreen.main.bounds.width * 0.5 * stat.value, height: 12)
                            .foregroundColor(stat.color)
                    }
                }
            }
        }
        .padding(.vertical)
    }
    
    // 아이템 그리드
    private var itemsGrid: some View {
        HStack(spacing: 15) {
            ForEach(lockedItems.indices, id: \.self) { index in
                let item = lockedItems[index]
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: 75, height: 75)
                        .foregroundColor(Color.gray.opacity(0.1))
                    
                    if item.isLocked {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray)
                    } else {
                        VStack(spacing: 5) {
                            Image(systemName: item.icon ?? "")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                            
                            Text(item.name)
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .onTapGesture {
                    print("\(item.name) 아이템 선택됨")
                }
            }
        }
    }
    
    // 아이콘 버튼
    @ViewBuilder
    func iconButton(systemName: String) -> some View {
        if systemName == "cart.fill" {
            NavigationLink(destination: StoreView() .environmentObject(AuthService())) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: 60, height: 60)
                        .foregroundColor(Color.gray.opacity(0.2))
                    Image(systemName: systemName)
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                }
            }
        } else if systemName == "backpack.fill" {
            NavigationLink(destination: userInventoryView()
                .environmentObject(AuthService())) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: 60, height: 60)
                        .foregroundColor(Color.gray.opacity(0.2))
                    Image(systemName: systemName)
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                }
            }
        } else if systemName == "mountain.2.fill" {
            NavigationLink(destination: CharDexView()) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: 60, height: 60)
                        .foregroundColor(Color.gray.opacity(0.2))
                    Image(systemName: systemName)
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                }
            }
        } else {
            Button(action: {
                print("\(systemName) 버튼 클릭")
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: 60, height: 60)
                        .foregroundColor(Color.gray.opacity(0.2))
                    Image(systemName: systemName)
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                }
            }
        }
    }
}


// MARK: - Preview
#Preview {
    HomeView()
}
