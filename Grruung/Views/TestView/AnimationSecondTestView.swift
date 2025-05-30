//
//  AnimationSecondTestView.swift
//  Grruung
//
//  Created by NoelMacMini on 5/29/25.
//

import SwiftUI

struct AnimationSecondTestView: View {
    // MARK: - 상태 변수들
    @State private var selectedCharacter: PetSpecies = .quokka // 기본값: 쿼카
    @State private var selectedPhase: CharacterPhase = .egg    // 기본값: 운석
    @StateObject private var eggControl = EggControl() // EggControl 인스턴스
    
    // 홈뷰와 비슷한 상태바 더미 데이터
    let stats: [(icon: String, color: Color, value: CGFloat)] = [
        ("fork.knife", Color.orange, 0.7),    // 포만감
        ("heart.fill", Color.red, 0.9),       // 애정도
        ("bolt.fill", Color.yellow, 0.8)      // 체력
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 레벨 프로그레스 바 (홈뷰에서 가져온 것)
                    levelProgressBar
                    
                    // 캐릭터 이미지 표시 영역
                    characterImageSection
                    
                    // 애니메이션 컨트롤 버튼들
                    animationControlSection
                    
                    // 상태 바 섹션 (홈뷰에서 가져온 것)
                    statsSection
                    
                    // 캐릭터 선택 토글 버튼
                    characterSelectionSection
                    
                    // 캐릭터 단계 선택 토글 버튼
                    phaseSelectionSection
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("애니메이션 테스트 2")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // 뷰가 나타날 때는 EggControl이 자동으로 첫 프레임을 로드함
                print("AnimationSecondTestView 나타남")
            }
            .onDisappear {
                // 뷰가 사라질 때 EggControl 정리
                eggControl.cleanup()
            }
        }
    }
    
    // MARK: - UI 컴포넌트들
    
    // 레벨 프로그레스 바 (홈뷰에서 가져옴)
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
                        .frame(width: UIScreen.main.bounds.width * 0.7 * 0.65, height: 30)
                }
            }
        }
        .padding(.top, 10)
    }
    
    // 캐릭터 이미지 표시 섹션
    private var characterImageSection: some View {
        VStack(spacing: 10) {
            // 현재 선택 정보와 애니메이션 상태 표시
            VStack(spacing: 5) {
                Text("현재 선택: \(selectedCharacter.rawValue) - \(selectedPhase.rawValue)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                // 애니메이션 상태 정보 표시
                HStack {
                    Text("프레임: \(eggControl.currentFrameIndex + 1)")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text("상태: \(eggControl.isAnimating ? "재생중" : "정지")")
                        .font(.caption)
                        .foregroundColor(eggControl.isAnimating ? .green : .red)
                }
            }
            
            ZStack {
                // 배경
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 200)
                
                // EggControl에서 현재 프레임 표시
                if let currentFrame = eggControl.currentFrame {
                    Image(uiImage: currentFrame)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 180)
                        .padding()
                } else {
                    // 이미지가 없을 때
                    VStack {
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("이미지를 찾을 수 없습니다")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 2)
    }
    
    // 애니메이션 컨트롤 섹션 추가
    private var animationControlSection: some View {
        VStack(spacing: 15) {
            Text("애니메이션 컨트롤")
                .font(.headline)
                .padding(.leading, 5)
            
            HStack(spacing: 20) {
                // 재생/정지 버튼
                Button(action: {
                    eggControl.toggleAnimation()
                }) {
                    HStack {
                        Image(systemName: eggControl.isAnimating ? "pause.fill" : "play.fill")
                        Text(eggControl.isAnimating ? "정지" : "재생")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(eggControl.isAnimating ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                }
                
                // 정지 버튼 (처음으로 돌아가기)
                Button(action: {
                    eggControl.stopAnimation()
                }) {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("정지")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(15)
    }
    
    // 상태 바 섹션 (홈뷰에서 가져옴)
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
    
    // 캐릭터 선택 섹션
    private var characterSelectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("캐릭터 선택")
                .font(.headline)
                .padding(.leading, 5)
            
            // 캐릭터 선택 토글 버튼들
            HStack(spacing: 15) {
                ForEach(PetSpecies.allCases.filter { $0 != .Undefined }, id: \.self) { character in
                    Button(action: {
                        selectedCharacter = character
                        print("선택된 캐릭터: \(character.rawValue)")
                    }) {
                        Text(character.rawValue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedCharacter == character
                                ? Color.blue
                                : Color.gray.opacity(0.2)
                            )
                            .foregroundColor(
                                selectedCharacter == character
                                ? .white
                                : .primary
                            )
                            .cornerRadius(20)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
    
    // 캐릭터 단계 선택 섹션
    private var phaseSelectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("성장 단계 선택")
                .font(.headline)
                .padding(.leading, 5)
            
            // 성장 단계 선택 토글 버튼들 (2줄로 배치)
            VStack(spacing: 10) {
                // 첫 번째 줄
                HStack(spacing: 10) {
                    phaseButton(.egg)
                    phaseButton(.infant)
                    phaseButton(.child)
                }
                
                // 두 번째 줄
                HStack(spacing: 10) {
                    phaseButton(.adolescent)
                    phaseButton(.adult)
                    phaseButton(.elder)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
    
    // MARK: - 헬퍼 함수
    
    // 개별 단계 버튼 헬퍼 함수
    private func phaseButton(_ phase: CharacterPhase) -> some View {
        Button(action: {
            selectedPhase = phase
            print("선택된 단계: \(phase.rawValue)")
            // 현재는 egg만 구현되어 있으므로 egg가 아닌 경우 알림
            if phase != .egg {
                print("아직 \(phase.rawValue) 단계는 구현되지 않았습니다")
            }
        }) {
            Text(phase.rawValue)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    selectedPhase == phase
                    ? Color.green
                    : Color.gray.opacity(0.2)
                )
                .foregroundColor(
                    selectedPhase == phase
                    ? .white
                    : .primary
                )
                .cornerRadius(15)
        }
    }
}

#Preview {
    AnimationSecondTestView()
}
