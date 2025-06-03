//
//  EvolutionView.swift
//  Grruung
//
//  Created by NoelMacMini on 6/4/25.
//

import SwiftUI

struct EvolutionView: View {
    // 전달받은 캐릭터 정보
    let character: GRCharacter
    
    // 화면 닫기용
    @Environment(\.dismiss) private var dismiss
    
    // 진화 상태 관리
    @State private var evolutionStep: EvolutionStep = .preparing
    @State private var downloadProgress: Double = 0.0
    @State private var statusMessage: String = ""
    
    // 진화 단계 열거형
    enum EvolutionStep {
        case preparing      // 준비 중
        case downloading    // 다운로드 중
        case hatching      // 부화 중 (메타데이터 저장)
        case completed     // 완료
        case unavailable   // 지원하지 않는 캐릭터
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // 상단 제목
                Text(getScreenTitle())
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 중앙 캐릭터 이미지 영역
                characterImageSection
                
                // 진행률 표시 영역
                progressSection
                
                // 상태 메시지
                Text(statusMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                // 하단 버튼
                bottomButton
            }
            .padding()
            .onAppear {
                setupInitialState()
            }
            .navigationTitle("진화")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(evolutionStep == .downloading || evolutionStep == .hatching)
        }
    }
    
    // MARK: - UI 컴포넌트들
    
    private var characterImageSection: some View {
        ZStack {
            // 배경 원
            Circle()
                .fill(Color.gray.opacity(0.1))
                .frame(width: 200, height: 200)
            
            // 캐릭터 이미지 (일단 임시 이미지)
            if evolutionStep == .completed {
                // 완료되면 부화된 캐릭터 표시 (다음 단계에서 구현)
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
            } else {
                // 진행 중에는 알 이미지 표시
                Image(systemName: "oval.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.brown)
            }
        }
    }
    
    private var progressSection: some View {
        VStack(spacing: 15) {
            if evolutionStep == .downloading || evolutionStep == .hatching {
                // 진행률 바
                ProgressView(value: downloadProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(height: 10)
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                
                // 퍼센트 표시
                Text("\(Int(downloadProgress * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
        }
    }
    
    private var bottomButton: some View {
        Group {
            switch evolutionStep {
            case .preparing:
                Button("부화 시작") {
                    startEvolution()
                }
                .buttonStyle(.borderedProminent)
                
            case .downloading, .hatching:
                // 진행 중에는 버튼 비활성화
                Button("진행 중...") { }
                    .disabled(true)
                    .buttonStyle(.bordered)
                
            case .completed:
                Button("완료") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                
            case .unavailable:
                Button("확인") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .font(.body)
        .padding(.horizontal, 40)
    }
    
    // MARK: - 헬퍼 메서드들
    
    private func getScreenTitle() -> String {
        switch evolutionStep {
        case .preparing:
            return "부화 준비"
        case .downloading, .hatching:
            return "부화 중"
        case .completed:
            return "부화 완료!"
        case .unavailable:
            return "지원 예정"
        }
    }
    
    private func setupInitialState() {
        // 캐릭터 종류에 따른 초기 상태 설정
        if character.species == .quokka {
            evolutionStep = .preparing
            statusMessage = "쿼카로 부화할 준비가 되었습니다!"
        } else {
            evolutionStep = .unavailable
            statusMessage = "이 캐릭터는 아직 부화를 진행할 수 없습니다.\n(업데이트 예정)"
        }
    }
    
    private func startEvolution() {
        guard character.species == .quokka else { return }
        
        // 1단계: 다운로드 시작
        evolutionStep = .downloading
        statusMessage = "부화에 필요한 데이터를 받아오는 중..."
        
        // 임시로 진행률 시뮬레이션 (다음 단계에서 실제 다운로드로 교체)
        simulateProgress()
    }
    
    // 임시 진행률 시뮬레이션 (다음 단계에서 실제 다운로드로 교체)
    private func simulateProgress() {
        downloadProgress = 0.0
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            downloadProgress += 0.02
            
            if downloadProgress >= 0.5 && evolutionStep == .downloading {
                evolutionStep = .hatching
                statusMessage = "곧 부화가 완료됩니다..."
            }
            
            if downloadProgress >= 1.0 {
                timer.invalidate()
                evolutionStep = .completed
                statusMessage = "부화가 완료되었습니다! 귀여운 쿼카가 태어났어요!"
            }
        }
    }
}

// MARK: - 프리뷰
#Preview {
    let sampleCharacter = GRCharacter(
        species: .quokka,
        name: "테스트쿼카",
        imageName: "Quokka",
        birthDate: Date()
    )
    
    return EvolutionView(character: sampleCharacter)
}
