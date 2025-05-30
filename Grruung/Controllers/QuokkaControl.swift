//
//  QuokkaControl.swift
//  Grruung
//
//  Created by NoelMacMini on 5/31/25.
//

import SwiftUI
import SwiftData
import FirebaseStorage

// 쿼카 애니메이션을 컨트롤하는 클래스 (Firebase Storage + SwiftData 사용)
class QuokkaControl: ObservableObject {
    
    // MARK: - Published 프로퍼티들
    @Published var currentFrame: UIImage? = nil     // 현재 표시할 프레임
    @Published var isAnimating: Bool = false        // 애니메이션 재생 중인지 여부
    @Published var currentFrameIndex: Int = 0       // 현재 프레임 번호
    @Published var isDownloading: Bool = false      // 다운로드 중인지 여부
    @Published var downloadProgress: Double = 0.0   // 다운로드 진행률
    @Published var downloadMessage: String = ""     // 다운로드 상태 메시지
    
    // MARK: - 비공개 프로퍼티들
    private var animationFrames: [UIImage] = []     // 로드된 애니메이션 프레임들
    private var animationTimer: Timer?              // 애니메이션 타이머
    private var currentPhase: CharacterPhase = .infant // 현재 성장 단계
    private var currentAnimationType: String = "normal" // 현재 애니메이션 타입
    private var frameRate: Double = 24.0            // 초당 프레임 수
    
    // MARK: - Firebase Storage 및 SwiftData 관련
    private let storage = Storage.storage()         // Firebase Storage 인스턴스
    private var modelContext: ModelContext?         // SwiftData 컨텍스트
    
    // MARK: - 애니메이션 타입들
    enum AnimationType: String, CaseIterable {
        case normal = "normal"
        case sleeping = "sleeping"
        case eating = "eating"
        
        var displayName: String {
            switch self {
            case .normal: return "기본"
            case .sleeping: return "잠자기"
            case .eating: return "먹기"
            }
        }
    }
    
    // MARK: - 초기화
    init() {
        // 기본값으로 첫 번째 프레임 설정
        loadFirstFrame()
    }
    
    // MARK: - SwiftData 컨텍스트 설정
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        print("QuokkaControl: SwiftData 컨텍스트 설정 완료")
    }
    
    // MARK: - 성장 단계 변경
    func setPhase(_ phase: CharacterPhase) {
        // 애니메이션 정지
        stopAnimation()
        
        // 새로운 단계 설정
        currentPhase = phase
        
        // 새로운 단계의 첫 프레임 로드
        loadFirstFrame()
        
        print("성장 단계 변경: \(phase.rawValue)")
    }
    
    // MARK: - 애니메이션 타입 변경
    func setAnimationType(_ type: String) {
        // 애니메이션 정지
        stopAnimation()
        
        // 새로운 타입 설정
        currentAnimationType = type
        
        // 새로운 타입의 프레임들 로드
        loadAnimationFrames()
        
        print("애니메이션 타입 변경: \(type)")
    }
    
    // MARK: - 첫 번째 프레임 로드 (Bundle 또는 SwiftData에서)
    private func loadFirstFrame() {
        // egg 단계는 Bundle에서 로드
        if currentPhase == .egg {
            let imageName = "egg_normal_1"
            currentFrame = UIImage(named: imageName)
            return
        }
        
        // 다른 단계는 SwiftData에서 로드 시도
        loadFrameFromSwiftData(frameIndex: 1) { [weak self] image in
            DispatchQueue.main.async {
                self?.currentFrame = image
                self?.currentFrameIndex = 0
            }
        }
    }
    
    // MARK: - 전체 애니메이션 프레임들 로드
    private func loadAnimationFrames() {
        // 기존 프레임들 초기화
        animationFrames.removeAll()
        
        // egg 단계는 Bundle에서 로드
        if currentPhase == .egg {
            loadEggFramesFromBundle()
            return
        }
        
        // 다른 단계는 SwiftData에서 로드
        loadFramesFromSwiftData()
    }
    
    // MARK: - Bundle에서 egg 프레임들 로드
    private func loadEggFramesFromBundle() {
        for frameNumber in 1...241 {
            let imageName = "egg_normal_\(frameNumber)"
            if let image = UIImage(named: imageName) {
                animationFrames.append(image)
            } else {
                break
            }
        }
        
        if !animationFrames.isEmpty {
            currentFrame = animationFrames[0]
            currentFrameIndex = 0
        }
        
        print("Bundle에서 \(animationFrames.count)개 egg 프레임 로드 완료")
    }
    
    // MARK: - SwiftData에서 프레임들 로드
    private func loadFramesFromSwiftData() {
        guard let context = modelContext else {
            print("SwiftData 컨텍스트가 설정되지 않음")
            return
        }
        
        // 현재 설정에 맞는 애니메이션 메타데이터 조회
        let phaseString = phaseToString(currentPhase)
        let characterType = "quokka"
        
        let descriptor = FetchDescriptor<GRAnimationMetadata>(
            predicate: #Predicate { metadata in
                metadata.characterType == characterType &&
                metadata.phase == phaseString &&
                metadata.animationType == currentAnimationType
            },
            sortBy: [SortDescriptor(\.frameIndex)]
        )
        
        do {
            let metadataList = try context.fetch(descriptor)
            print("SwiftData에서 \(metadataList.count)개 메타데이터 발견")
            
            // 각 메타데이터에서 이미지 로드
            for metadata in metadataList {
                if let image = loadImageFromPath(metadata.filePath) {
                    animationFrames.append(image)
                }
            }
            
            if !animationFrames.isEmpty {
                currentFrame = animationFrames[0]
                currentFrameIndex = 0
            }
            
            print("SwiftData에서 \(animationFrames.count)개 프레임 로드 완료")
            
        } catch {
            print("SwiftData에서 프레임 로드 실패: \(error)")
        }
    }
    
    // MARK: - SwiftData에서 특정 프레임 로드 (첫 프레임용)
    private func loadFrameFromSwiftData(frameIndex: Int, completion: @escaping (UIImage?) -> Void) {
        guard let context = modelContext else {
            completion(nil)
            return
        }
        
        let phaseString = phaseToString(currentPhase)
        let characterType = "quokka"
        
        let descriptor = FetchDescriptor<GRAnimationMetadata>(
            predicate: #Predicate { metadata in
                metadata.characterType == characterType &&
                metadata.phase == phaseString &&
                metadata.animationType == currentAnimationType &&
                metadata.frameIndex == frameIndex
            }
        )
        
        do {
            let metadataList = try context.fetch(descriptor)
            if let metadata = metadataList.first {
                let image = loadImageFromPath(metadata.filePath)
                completion(image)
            } else {
                completion(nil)
            }
        } catch {
            print("특정 프레임 로드 실패: \(error)")
            completion(nil)
        }
    }
    
    // MARK: - 파일 경로에서 이미지 로드
    private func loadImageFromPath(_ filePath: String) -> UIImage? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imageURL = documentsPath.appendingPathComponent(filePath)
        
        guard let imageData = try? Data(contentsOf: imageURL) else {
            print("이미지 데이터 로드 실패: \(filePath)")
            return nil
        }
        
        return UIImage(data: imageData)
    }
    
    // MARK: - 애니메이션 재생 함수
    func startAnimation() {
        // 이미 재생 중이면 중단
        guard !isAnimating else { return }
        
        // 프레임이 없으면 재생할 수 없음
        guard !animationFrames.isEmpty else {
            print("재생할 프레임이 없습니다")
            return
        }
        
        print("쿼카 애니메이션 시작 - 총 \(animationFrames.count)개 프레임")
        
        // 재생 상태로 변경
        isAnimating = true
        
        // 타이머 간격 계산
        let timeInterval = 1.0 / frameRate
        
        // 타이머 시작
        animationTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { [weak self] _ in
            self?.updateFrame()
        }
    }
    
    // MARK: - 애니메이션 정지 함수
    func stopAnimation() {
        print("쿼카 애니메이션 정지")
        
        // 타이머 중지 및 해제
        animationTimer?.invalidate()
        animationTimer = nil
        
        // 재생 상태 해제
        isAnimating = false
    }
    
    // MARK: - 프레임 업데이트 함수
    private func updateFrame() {
        // 다음 프레임으로 이동
        currentFrameIndex += 1
        
        // 마지막 프레임에 도달하면 처음으로 돌아가기 (루프)
        if currentFrameIndex >= animationFrames.count {
            currentFrameIndex = 0
        }
        
        // 현재 프레임 이미지 업데이트
        currentFrame = animationFrames[currentFrameIndex]
        
        // 디버깅용 로그 (매 10프레임마다 출력)
        if currentFrameIndex % 10 == 0 {
            print("쿼카 현재 프레임: \(currentFrameIndex + 1)/\(animationFrames.count)")
        }
    }
    
    // MARK: - 애니메이션 재생/정지 토글 함수
    func toggleAnimation() {
        if isAnimating {
            stopAnimation()
        } else {
            startAnimation()
        }
    }
    
    // MARK: - 정리 함수
    func cleanup() {
        stopAnimation()
        print("QuokkaControl 정리 완료")
    }
    
    // MARK: - 성장 단계를 문자열로 변환
    private func phaseToString(_ phase: CharacterPhase) -> String {
        switch phase {
        case .egg: return "egg"
        case .infant: return "infant"
        case .child: return "child"
        case .adolescent: return "adolescent"
        case .adult: return "adult"
        case .elder: return "elder"
        }
    }
}
