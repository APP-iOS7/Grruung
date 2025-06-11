//
//  HealthCareView.swift
//  Grruung
//
//  Created by KimJunsoo on 6/10/25.
//

import SwiftUI

struct HealthCareView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: HomeViewModel
    @Binding var isPresented: Bool
    
    @State private var selectedTab = 0
    
    // MARK: - Body
    var body: some View {
        // 오버레이 배경
        ZStack {
            // 반투명 배경 (탭 시 닫힘)
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        isPresented = false
                    }
                }
            
            // 메인 컨텐츠 컨테이너
            VStack(spacing: 0) {
                // 헤더
                HStack {
                    Text("건강 & 청결 관리")
                        .font(.headline)
                        .bold()
                    
                    Spacer()
                    
                    Button {
                        withAnimation {
                            isPresented = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // 탭 선택 바
                HStack(spacing: 20) {
                    tabButton("건강관리", index: 0)
                    tabButton("청결관리", index: 1)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                Divider()
                    .padding(.vertical, 5)
                
                // 탭 콘텐츠
                if selectedTab == 0 {
                    healthCareContent
                } else {
                    cleanCareContent
                }
                
                Spacer(minLength: 20)
            }
            .frame(width: UIScreen.main.bounds.width * 0.85, height: UIScreen.main.bounds.height * 0.7)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 20)
        }
        .transition(.opacity)
    }
    
    // MARK: - 건강 관리 탭 콘텐츠
    private var healthCareContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 현재 건강 상태 표시
                statusCard(
                    title: "현재 건강 상태",
                    value: viewModel.healthyValue,
                    maxValue: 100,
                    icon: "heart.fill",
                    color: .red
                )
                
                // 건강 관리 액션 버튼들
                VStack(alignment: .leading, spacing: 10) {
                    Text("건강 관리 액션")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            actionButton(
                                title: "병원 방문",
                                icon: "cross.fill",
                                description: "건강 상태 완전 회복",
                                cost: "골드 500",
                                action: { performHealthAction("hospital") }
                            )
                            
                            actionButton(
                                title: "약 먹이기",
                                icon: "pills.fill",
                                description: "건강 상태 30 회복",
                                cost: "골드 100",
                                action: { performHealthAction("medicine") }
                            )
                            
                            actionButton(
                                title: "영양제",
                                icon: "drop.fill",
                                description: "건강 상태 10 회복",
                                cost: "골드 50",
                                action: { performHealthAction("vitamin") }
                            )
                            
                            actionButton(
                                title: "건강 체크",
                                icon: "stethoscope",
                                description: "건강 상태 확인",
                                cost: "골드 20",
                                action: { performHealthAction("checkup") }
                            )
                        }
                        .padding(.horizontal)
                    }
                }
                
                // 건강 관련 팁
                tipCard(
                    tip: "펫의 건강 상태가 30 미만으로 떨어지면 활동량 회복이 느려집니다.",
                    icon: "exclamationmark.triangle.fill"
                )
            }
            .padding(.horizontal)
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - 청결 관리 탭 콘텐츠
    private var cleanCareContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 현재 청결 상태 표시
                statusCard(
                    title: "현재 청결 상태",
                    value: viewModel.cleanValue,
                    maxValue: 100,
                    icon: "shower.fill",
                    color: .blue
                )
                
                // 청결 관리 액션 버튼들
                VStack(alignment: .leading, spacing: 10) {
                    Text("청결 관리 액션")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            actionButton(
                                title: "미용실 방문",
                                icon: "scissors",
                                description: "청결 상태 완전 회복",
                                cost: "골드 400",
                                action: { performCleanAction("salon") }
                            )
                            
                            actionButton(
                                title: "목욕시키기",
                                icon: "bathtub.fill",
                                description: "청결 상태 40 회복",
                                cost: "골드 80",
                                action: { performCleanAction("bath") }
                            )
                            
                            actionButton(
                                title: "빗질하기",
                                icon: "comb.fill",
                                description: "청결 상태 15 회복",
                                cost: "골드 30",
                                action: { performCleanAction("brush") }
                            )
                            
                            actionButton(
                                title: "손발 씻기",
                                icon: "hand.wave.fill",
                                description: "청결 상태 5 회복",
                                cost: "골드 10",
                                action: { performCleanAction("washHands") }
                            )
                        }
                        .padding(.horizontal)
                    }
                }
                
                // 청결 관련 팁
                tipCard(
                    tip: "펫의 청결 상태가 20 미만으로 떨어지면 건강 상태가 서서히 감소합니다.",
                    icon: "exclamationmark.triangle.fill"
                )
            }
            .padding(.horizontal)
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - 컴포넌트
    
    // 탭 버튼
    private func tabButton(_ title: String, index: Int) -> some View {
        Button {
            withAnimation {
                selectedTab = index
            }
        } label: {
            VStack(spacing: 8) {
                Text(title)
                    .fontWeight(selectedTab == index ? .bold : .regular)
                    .foregroundColor(selectedTab == index ? .primary : .gray)
                
                Rectangle()
                    .fill(selectedTab == index ? Color.primary : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // 상태 카드
    private func statusCard(title: String, value: Int, maxValue: Int, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(value)/\(maxValue)")
                    .fontWeight(.bold)
            }
            
            // 상태 게이지 바
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 배경 바
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                    
                    // 상태 바
                    RoundedRectangle(cornerRadius: 8)
                        .fill(getStatusColor(value: value, maxValue: maxValue))
                        .frame(width: geometry.size.width * CGFloat(value) / CGFloat(maxValue), height: 12)
                }
            }
            .frame(height: 12)
            
            // 상태 메시지
            Text(getStatusMessage(value: value, isHealth: icon == "heart.fill"))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
    
    // 액션 버튼
    private func actionButton(title: String, icon: String, description: String, cost: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.8))
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                Text(title)
                    .font(.caption)
                    .bold()
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text(cost)
                    .font(.caption2)
                    .foregroundColor(.orange)
                    .fontWeight(.bold)
            }
            .frame(width: 90, height: 140)
            .padding(8)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        }
    }
    
    // 팁 카드
    private func tipCard(tip: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(icon == "exclamationmark.triangle.fill" ? .orange : .blue)
                .frame(width: 24, height: 24)
            
            Text(tip)
                .font(.footnote)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - 헬퍼 메서드
    
    // 상태에 따른 색상 계산
    private func getStatusColor(value: Int, maxValue: Int) -> Color {
        let percentage = Double(value) / Double(maxValue)
        
        if percentage < 0.3 {
            return .red
        } else if percentage < 0.7 {
            return .orange
        } else {
            return .green
        }
    }
    
    // 상태에 따른 메시지
    private func getStatusMessage(value: Int, isHealth: Bool) -> String {
        let percentage = Double(value) / 100.0
        
        if isHealth {
            if percentage < 0.3 {
                return "위험: 즉시 치료가 필요합니다!"
            } else if percentage < 0.5 {
                return "주의: 건강 상태가 좋지 않습니다."
            } else if percentage < 0.7 {
                return "양호: 조금 더 관리가 필요합니다."
            } else {
                return "건강: 상태가 좋습니다."
            }
        } else {
            if percentage < 0.3 {
                return "불결: 청결 관리가 시급합니다!"
            } else if percentage < 0.5 {
                return "지저분: 청결 상태가 좋지 않습니다."
            } else if percentage < 0.7 {
                return "보통: 조금 더 관리가 필요합니다."
            } else {
                return "깨끗: 청결 상태가 좋습니다."
            }
        }
    }
    
    // 건강 관련 액션 처리
    private func performHealthAction(_ actionId: String) {
        var healthValue = 0
        var goldCost = 0
        
        switch actionId {
        case "hospital":
            healthValue = 100 // 완전 회복
            goldCost = 500
        case "medicine":
            healthValue = 30
            goldCost = 100
        case "vitamin":
            healthValue = 10
            goldCost = 50
        case "checkup":
            healthValue = 0 // 체크만 하고 회복은 없음
            goldCost = 20
        default:
            return
        }
        
        // TODO: 골드 차감 로직 추가
        // 실제 액션 수행
        if actionId == "checkup" {
            // 건강 체크만 수행 (상태 메시지만 업데이트)
            viewModel.statusMessage = "건강 상태 확인 결과: \(viewModel.healthyValue)/100"
        } else {
            // 회복 액션 수행
            if let character = viewModel.character {
                // 캐릭터 상태 업데이트
                viewModel.updateCharacterHealthStatus(healthValue: healthValue)
                viewModel.statusMessage = "건강 상태가 회복되었습니다!"
            }
        }
        
        // 액션 수행 후 닫기
        if actionId != "checkup" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation {
                    isPresented = false
                }
            }
        }
    }
    
    // 청결 관련 액션 처리
    private func performCleanAction(_ actionId: String) {
        var cleanValue = 0
        var goldCost = 0
        
        switch actionId {
        case "salon":
            cleanValue = 100 // 완전 회복
            goldCost = 400
        case "bath":
            cleanValue = 40
            goldCost = 80
        case "brush":
            cleanValue = 15
            goldCost = 30
        case "washHands":
            cleanValue = 5
            goldCost = 10
        default:
            return
        }
        
        // TODO: 골드 차감 로직 추가
        // 실제 액션 수행
        if let character = viewModel.character {
            // 캐릭터 상태 업데이트
            viewModel.updateCharacterCleanStatus(cleanValue: cleanValue)
            viewModel.statusMessage = "청결 상태가 개선되었습니다!"
        }
        
        // 액션 수행 후 닫기
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                isPresented = false
            }
        }
    }
}
