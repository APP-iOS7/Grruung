//
//  AnimationTestView.swift
//  Grruung
//
//  Created by NoelMacMini on 5/12/25.
//

import SwiftUI
import SwiftData

struct AnimationTestView: View {
    @StateObject private var animationTestViewModel = AnimationTestViewModel()
    
    // 현재 선택된 설정
    @State private var selectedCharacterType = "egg"
    @State private var selectedAnimationType = "eggbasic"
    
    // 애니메이션 설정
    @State private var currentFrameIndex = 0
    @State private var isPlaying = false
    @State private var isReversed = false
    @State private var framesPerSecond: Double = 24.0
    @State private var animationMode = AnimationMode.loop
    
    // 로드된 애니메이션 프레임
    @State private var animationFrames: [UIImage] = []
    
    // 애니메이션 타이머
    @State private var animationTimer: Timer?
    
    // 캐릭터 타입 옵션
    let characterTypes = ["egg", "quokka", "lion"]
    
    // 각 캐릭터 타입별 애니메이션 타입 옵션
    let animationOptions: [String: [String]] = [
        "egg": ["eggbasic", "eggbreak", "egghatch"],
        "quokka": ["normal", "sleep", "play"],
        "lion": ["normal", "angry", "happy"]
    ]
    
    // 애니메이션 모드
    enum AnimationMode: String, CaseIterable, Identifiable {
        case loop = "반복"
        case pingpong = "핑퐁"
        case oneshot = "한번만"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // 캐릭터 타입 선택
                Picker("캐릭터 타입", selection: $selectedCharacterType) {
                    ForEach(characterTypes, id: \.self) { type in
                        Text(type.capitalized).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .onChange(of: selectedCharacterType) { _, newValue in
                    // 캐릭터 변경 시 첫 번째 애니메이션 타입 자동 선택
                    if let firstType = animationOptions[newValue]?.first {
                        selectedAnimationType = firstType
                    }
                    // 애니메이션 정지 및 초기화
                    stopAnimation()
                    loadSelectedAnimation()
                }
                
                // 애니메이션 타입 선택
                Picker("애니메이션 타입", selection: $selectedAnimationType) {
                    if let types = animationOptions[selectedCharacterType] {
                        ForEach(types, id: \.self) { type in
                            Text(type.capitalized).tag(type)
                        }
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: selectedAnimationType) { _, _ in
                    // 애니메이션 정지 및 초기화
                    stopAnimation()
                    loadSelectedAnimation()
                }
                
                // 로딩 및 에러 메시지
                if animationTestViewModel.isLoading {
                    ProgressView(value: animationTestViewModel.progress, total: 1.0) {
                        Text(animationTestViewModel.message)
                            .font(.caption)
                    }
                    .padding()
                } else if let errorMessage = animationTestViewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                // 애니메이션 표시 영역
                ZStack {
                    Color(.systemGray6)
                        .cornerRadius(16)
                    
                    if animationFrames.isEmpty {
                        Text("프레임 없음")
                            .foregroundColor(.gray)
                    } else if currentFrameIndex < animationFrames.count {
                        Image(uiImage: animationFrames[currentFrameIndex])
                            .resizable()
                            .scaledToFit()
                            .padding()
                    }
                }
                .frame(height: 300)
                .padding()
                
                // 프레임 정보와 슬라이더
                if !animationFrames.isEmpty {
                    VStack {
                        Text("프레임: \(currentFrameIndex + 1) / \(animationFrames.count)")
                            .padding(.bottom, 4)
                        
                        Slider(value: Binding(
                            get: { Double(currentFrameIndex) },
                            set: { newValue in
                                currentFrameIndex = Int(newValue)
                            }
                        ), in: 0...Double(animationFrames.count - 1), step: 1)
                        .padding(.horizontal)
                    }
                    .padding(.bottom)
                }
                
                // 애니메이션 컨트롤
                VStack {
                    // 속도 조절 및 모드 선택
                    HStack {
                        Text("FPS: \(Int(framesPerSecond))")
                            .frame(width: 80, alignment: .leading)
                        
                        Slider(value: $framesPerSecond, in: 1...60, step: 1)
                            .onChange(of: framesPerSecond) { _, _ in
                                if isPlaying {
                                    // 속도 변경 시 타이머 재시작
                                    startAnimation()
                                }
                            }
                    }
                    .padding(.horizontal)
                    
                    // 애니메이션 모드 선택
                    Picker("모드", selection: $animationMode) {
                        ForEach(AnimationMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    
                    // 재생 컨트롤 버튼
                    HStack(spacing: 30) {
                        // 이전 프레임
                        Button(action: previousFrame) {
                            Image(systemName: "backward.frame")
                                .font(.title)
                        }
                        .disabled(animationFrames.isEmpty || currentFrameIndex <= 0)
                        
                        // 재생/일시정지
                        Button(action: togglePlayback) {
                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 44))
                        }
                        .disabled(animationFrames.isEmpty)
                        
                        // 다음 프레임
                        Button(action: nextFrame) {
                            Image(systemName: "forward.frame")
                                .font(.title)
                        }
                        .disabled(animationFrames.isEmpty || currentFrameIndex >= animationFrames.count - 1)
                    }
                    .padding(.bottom)
                }
                
                // 캐시 관리 버튼
                HStack(spacing: 20) {
                    // 다운로드 버튼
                    Button(action: downloadSelectedAnimation) {
                        Label("다운로드", systemImage: "arrow.down.circle")
                    }
                    .disabled(animationTestViewModel.isLoading)
                    
                    // 로드 버튼
                    Button(action: loadSelectedAnimation) {
                        Label("로드", systemImage: "arrow.clockwise.circle")
                    }
                    .disabled(animationTestViewModel.isLoading)
                    
                    // 삭제 버튼
                    Button(action: clearSelectedAnimation) {
                        Label("삭제", systemImage: "trash.circle")
                    }
                    .disabled(animationTestViewModel.isLoading || animationFrames.isEmpty)
                }
                .padding()
                
                // 캐시 정보
                if !animationFrames.isEmpty {
                    let totalSize = animationTestViewModel.getTotalSize(
                        characterType: selectedCharacterType,
                        animationType: selectedAnimationType
                    )
                    
                    Text("캐시 크기: \(formatFileSize(totalSize))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("애니메이션 테스트")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            animationTestViewModel.clearAllCache()
                            animationFrames = []
                            currentFrameIndex = 0
                        }) {
                            Label("모든 캐시 삭제", systemImage: "trash")
                        }
                        
                        Button(action: {
                            animationTestViewModel.clearOldCache(olderThanDays: 7)
                            loadSelectedAnimation()
                        }) {
                            Label("오래된 캐시 삭제 (7일)", systemImage: "clock.arrow.circlepath")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .onAppear {
                // 뷰가 나타날 때 애니메이션 로드
                loadSelectedAnimation()
            }
            .onDisappear {
                // 뷰가 사라질 때 타이머와 리소스 정리
                stopAnimation()
                animationTestViewModel.cleanup()
            }
        }
    }
    
    // MARK: - 사용자 작업 메서드
    
    // 선택한 애니메이션 다운로드
    private func downloadSelectedAnimation() {
        stopAnimation()
        animationTestViewModel.downloadAnimation(
            characterType: selectedCharacterType,
            animationType: selectedAnimationType
        )
    }
    
    // 선택한 애니메이션 로드
    private func loadSelectedAnimation() {
        // 기존 애니메이션 중지
        stopAnimation()
        
        // 모든 프레임 로드
        animationFrames = animationTestViewModel.loadAllAnimationFrames(
            characterType: selectedCharacterType,
            animationType: selectedAnimationType
        )
        
        // 인덱스 초기화
        currentFrameIndex = 0
    }
    
    // 선택한 애니메이션 캐시 삭제
    private func clearSelectedAnimation() {
        stopAnimation()
        animationTestViewModel.clearCache(
            characterType: selectedCharacterType,
            animationType: selectedAnimationType
        )
        animationFrames = []
        currentFrameIndex = 0
    }
    
    // MARK: - 애니메이션 제어 메서드
    
    // 재생/일시정지 토글
    private func togglePlayback() {
        if isPlaying {
            stopAnimation()
        } else {
            startAnimation()
        }
    }
    
    // 애니메이션 시작
    private func startAnimation() {
        // 이미 재생 중이면 타이머 중지
        stopAnimation()
        
        // 프레임이 없으면 무시
        guard !animationFrames.isEmpty else { return }
        
        // 마지막 프레임에서 재시작하려면 처음으로 이동
        if currentFrameIndex >= animationFrames.count - 1 && !isReversed {
            currentFrameIndex = 0
        } else if currentFrameIndex <= 0 && isReversed {
            currentFrameIndex = animationFrames.count - 1
        }
        
        // 재생 상태 설정
        isPlaying = true
        
        // 타이머 생성 (FPS에 맞는 간격)
        let timeInterval = 1.0 / framesPerSecond
        animationTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { _ in
            // 애니메이션 프레임 업데이트
            updateAnimationFrame()
        }
    }
    
    // 애니메이션 중지
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        isPlaying = false
    }
    
    // 애니메이션 프레임 업데이트
    private func updateAnimationFrame() {
        guard !animationFrames.isEmpty else { return }
        
        switch animationMode {
        case .loop:
            // 반복 모드
            currentFrameIndex = (currentFrameIndex + 1) % animationFrames.count
            
        case .pingpong:
            // 핑퐁 모드
            if isReversed {
                currentFrameIndex -= 1
                
                // 처음 프레임에 도달하면 방향 전환
                if currentFrameIndex <= 0 {
                    currentFrameIndex = 0
                    isReversed = false
                }
            } else {
                currentFrameIndex += 1
                
                // 마지막 프레임에 도달하면 방향 전환
                if currentFrameIndex >= animationFrames.count - 1 {
                    currentFrameIndex = animationFrames.count - 1
                    isReversed = true
                }
            }
            
        case .oneshot:
            // 한번만 재생 모드
            if currentFrameIndex < animationFrames.count - 1 {
                currentFrameIndex += 1
            } else {
                // 마지막 프레임에 도달하면 정지
                stopAnimation()
            }
        }
    }
    
    // 이전 프레임으로 이동
    private func previousFrame() {
        if currentFrameIndex > 0 {
            currentFrameIndex -= 1
        }
    }
    
    // 다음 프레임으로 이동
    private func nextFrame() {
        if currentFrameIndex < animationFrames.count - 1 {
            currentFrameIndex += 1
        }
    }
    
    // 파일 크기 포맷팅
    private func formatFileSize(_ byteCount: Int) -> String {
        if byteCount < 1024 {
            return "\(byteCount) 바이트"
        } else if byteCount < 1024 * 1024 {
            let kb = Double(byteCount) / 1024.0
            return String(format: "%.1f KB", kb)
        } else {
            let mb = Double(byteCount) / (1024.0 * 1024.0)
            return String(format: "%.1f MB", mb)
        }
    }
}

#Preview {
    AnimationTestView()
}
