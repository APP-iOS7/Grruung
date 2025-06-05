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
        let phaseString = phaseToString(currentPhase) // 영어 변환 함수 사용
        let characterType = "quokka"
        
        print("SwiftData에서 프레임 로드 시도:")
        print("  - characterType: \(characterType)")
        print("  - phaseString: \(phaseString)")
        print("  - animationType: \(currentAnimationType)")
        
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
            
            // 임시 배열에 프레임들 로드
            var tempFrames: [UIImage] = []
            
            // 각 메타데이터에서 이미지 로드
            for metadata in metadataList {
                print("이미지 로드 시도: \(metadata.filePath)")
                
                if let image = loadImageFromPath(metadata.filePath) {
                    tempFrames.append(image)
                    print("이미지 로드 성공: 프레임 \(metadata.frameIndex)")
                } else {
                    print("이미지 로드 실패: \(metadata.filePath)")
                    // 파일 존재 여부 확인
                    let fileExists = FileManager.default.fileExists(atPath: metadata.filePath)
                    print("   파일 존재 여부: \(fileExists)")
                }
            }
            
            // ✅ 메인 스레드에서 UI 업데이트
            DispatchQueue.main.async {
                self.animationFrames = tempFrames
                
                if !self.animationFrames.isEmpty {
                    self.currentFrame = self.animationFrames[0]
                    self.currentFrameIndex = 0
                    print("UI 업데이트 완료: \(self.animationFrames.count)개 프레임")
                } else {
                    print("로드된 프레임이 없음")
                }
            }
            
            // 변경사항 저장
            try context.save()
            
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
        
        // --- 디버깅 섹션 시작 ---
        print("=== 이미지 로드 시도 ===")
        print("상대 경로: \(filePath)")
        print("전체 경로: \(imageURL.path)")
        
        // 파일 존재 여부 확인
        let fileExists = FileManager.default.fileExists(atPath: imageURL.path)
        print("파일 존재: \(fileExists)")
        
        if fileExists {
            // 파일 크기 확인
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: imageURL.path)
                if let fileSize = attributes[.size] as? Int {
                    print("파일 크기: \(fileSize) 바이트")
                }
            } catch {
                print("파일 속성 확인 실패: \(error)")
            }
        }
        
        // --- 디버깅 섹션 끝 ---
        
        guard let imageData = try? Data(contentsOf: imageURL) else {
            print("이미지 데이터 로드 실패: \(filePath)")
            return nil
        }
        
        guard let image = UIImage(data: imageData) else {
            print("❌ UIImage 변환 실패: \(filePath)")
            return nil
        }
        
        print("✅ 이미지 로드 성공: \(image.size.width)x\(image.size.height)")
        print("=====================")
        
        return image
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
    
    // MARK: - Firebase Storage 다운로드 기능
    
    // 특정 애니메이션 타입 다운로드 (예: normal만)
    func downloadAnimationType(_ animationType: AnimationType) {
        guard let context = modelContext else {
            print("SwiftData 컨텍스트가 설정되지 않음")
            return
        }
        
        // 다운로드 시작
        isDownloading = true
        downloadProgress = 0.0
        downloadMessage = "\(animationType.displayName) 애니메이션 다운로드 중..."
        
        print("Firebase에서 \(animationType.rawValue) 애니메이션 다운로드 시작")
        
        // Firebase Storage 경로 설정
        let phaseString = phaseToString(currentPhase)
        let characterType = "quokka"
        let basePath = "animations/\(characterType)/\(phaseString)/\(animationType.rawValue)"
        
        // 최대 프레임 수
        let actualFrameCount = getCurrentTotalFrameCount(for: animationType)
        var downloadedFrames = 0
        let totalFramesToDownload = actualFrameCount
        
        print("다운로드할 프레임 수: \(totalFramesToDownload)")
        
        if totalFramesToDownload == 0 {
            DispatchQueue.main.async {
                self.isDownloading = false
                self.downloadMessage = "다운로드할 프레임이 없습니다"
            }
            return
        }
        
        // 각 프레임 다운로드
        for frameIndex in 1...totalFramesToDownload {
            let fileName = "\(characterType)_\(phaseString)_\(animationType.rawValue)_\(frameIndex).png"
            let firebasePath = "\(basePath)/\(fileName)"
            
            self.downloadFrame(
                firebasePath: firebasePath,
                fileName: fileName,
                characterType: characterType,
                phase: self.currentPhase,
                animationType: animationType.rawValue,
                frameIndex: frameIndex,
                context: context
            ) { success in
                downloadedFrames += 1
                
                DispatchQueue.main.async {
                    self.downloadProgress = Double(downloadedFrames) / Double(totalFramesToDownload)
                    
                    if downloadedFrames == totalFramesToDownload {
                        self.isDownloading = false
                        self.downloadMessage = "\(animationType.displayName) 다운로드 완료!"
                        print("다운로드 완료: \(downloadedFrames)개 프레임")
                        
                        // 다운로드 완료 후 애니메이션 다시 로드
                        self.loadAnimationFrames()
                    } else {
                        self.downloadMessage = "\(animationType.displayName) 다운로드 중... (\(downloadedFrames)/\(totalFramesToDownload))"
                    }
                }
            }
        }
    }
    
    // 모든 애니메이션 타입 다운로드 (normal, sleeping, eating 전체)
    func downloadAllAnimationTypes() {
        guard let context = modelContext else {
            print("SwiftData 컨텍스트가 설정되지 않음")
            return
        }
        
        isDownloading = true
        downloadProgress = 0.0
        downloadMessage = "전체 애니메이션 다운로드 중..."
        
        let allTypes = AnimationType.allCases
        var completedTypes = 0
        let totalTypes = allTypes.count
        
        for animationType in allTypes {
            downloadAnimationTypeInternal(animationType, context: context) { [weak self] success in
                completedTypes += 1
                
                DispatchQueue.main.async {
                    self?.downloadProgress = Double(completedTypes) / Double(totalTypes)
                    
                    if completedTypes == totalTypes {
                        self?.isDownloading = false
                        self?.downloadMessage = "전체 다운로드 완료!"
                        print("모든 애니메이션 타입 다운로드 완료")
                        
                        // 다운로드 완료 후 현재 애니메이션 다시 로드
                        self?.loadAnimationFrames()
                    } else {
                        self?.downloadMessage = "전체 다운로드 중... (\(completedTypes)/\(totalTypes) 타입 완료)"
                    }
                }
            }
        }
    }
    
    // 개별 애니메이션 타입 다운로드 (내부용)
    private func downloadAnimationTypeInternal(_ animationType: AnimationType, context: ModelContext, completion: @escaping (Bool) -> Void) {
        let phaseString = phaseToString(currentPhase)
        let characterType = "quokka"
        let basePath = "animations/\(characterType)/\(phaseString)/\(animationType.rawValue)"
        
        let actualFrameCount = getCurrentTotalFrameCount(for: animationType) // 수정: getTotalFrameCount 사용
        
        if actualFrameCount == 0 {
            completion(true) // 프레임이 없어도 완료로 처리
            return
        }
        
        var downloadedFrames = 0
        let totalFramesToDownload = actualFrameCount
        
        for frameIndex in 1...actualFrameCount {
            let fileName = "\(characterType)_\(phaseString)_\(animationType.rawValue)_\(frameIndex).png"
            let firebasePath = "\(basePath)/\(fileName)"
            
            self.downloadFrame(
                firebasePath: firebasePath,
                fileName: fileName,
                characterType: characterType,
                phase: self.currentPhase,
                animationType: animationType.rawValue,
                frameIndex: frameIndex,
                context: context
            ) { success in
                downloadedFrames += 1
                
                if downloadedFrames == totalFramesToDownload {
                    completion(true)
                }
            }
        }
    }
    
    // Firebase에서 프레임 수 확인 (수정됨) - 지금은 사용하지 않음 (지금은 일단 프레임 수 수동으로 계산해서 반영)
    private func checkFrameCount(basePath: String, maxFrames: Int, completion: @escaping (Int) -> Void) {
        // ✅ 수정: 현재 phase와 애니메이션 타입에 따라 실제 프레임 수 반환
        let animationType = AnimationType(rawValue: currentAnimationType) ?? .normal
        let actualFrameCount = getCurrentTotalFrameCount(for: animationType)
        
        print("성장단계: \(phaseToString(currentPhase)), 애니메이션 타입: \(currentAnimationType), 프레임 수: \(actualFrameCount)")
        completion(actualFrameCount)
    }
    
    // 개별 프레임 다운로드 및 SwiftData 저장
    private func downloadFrame(
        firebasePath: String,
        fileName: String,
        characterType: String,
        phase: CharacterPhase,
        animationType: String,
        frameIndex: Int,
        context: ModelContext,
        completion: @escaping (Bool) -> Void
    ) {
        let storageRef = storage.reference().child(firebasePath)
        
        print("=== 프레임 다운로드 시작 ===")
        print("Firebase 경로: \(firebasePath)")
        print("파일명: \(fileName)")
        print("프레임 번호: \(frameIndex)")
        
        storageRef.getData(maxSize: 5 * 1024 * 1024) { [weak self] data, error in
            guard let self = self else {
                completion(false)
                return
            }
            
            if let error = error {
                print("Firebase 다운로드 실패: \(firebasePath) - \(error)")
                completion(false)
                return
            }
            
            guard let imageData = data else {
                print("이미지 데이터가 없음: \(firebasePath)")
                completion(false)
                return
            }
            
            print("✅ Firebase 다운로드 성공: \(imageData.count) 바이트")
            
            // Documents 폴더에 이미지 저장
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let localPath = "animations/\(characterType)/\(self.phaseToString(phase))/\(animationType)/\(fileName)"
            let fullURL = documentsPath.appendingPathComponent(localPath)
            
            print("로컬 저장 경로: \(fullURL.path)")
            
            // 디렉토리 생성
            let directoryURL = fullURL.deletingLastPathComponent()
            do {
                try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            } catch {
                print("❌ 디렉토리 생성 실패: \(error)")
            }
            
            do {
                // 파일 저장
                try imageData.write(to: fullURL)
                print("✅ 파일 저장 성공: \(fullURL.path)")
                
                // 파일 존재 확인
                let fileExists = FileManager.default.fileExists(atPath: fullURL.path)
                print("파일 존재 확인: \(fileExists)")
                
                // ✅ 메타데이터 생성 전 로그
                print("=== 메타데이터 생성 중 ===")
                // 중요: phase를 영어로 저장하도록 수정
                let englishPhase = self.phaseToString(phase)  // 영어 변환
                print("영어 phase: \(englishPhase)")
                
                // SwiftData에 메타데이터 저장
                let metadata = GRAnimationMetadata(
                    characterType: characterType,
                    phase: phase,  // 이건 초기화용
                    animationType: animationType,
                    frameIndex: frameIndex,
                    filePath: localPath,
                    fileSize: imageData.count
                )
                
                print("생성된 메타데이터 초기값:")
                print("  - phase (초기): \(metadata.phase)")
                
                // 저장 후 영어로 덮어쓰기
                metadata.phase = englishPhase
                print("  - phase (수정 후): \(metadata.phase)")
                
                print("=== SwiftData 저장 시도 ===")
                print("사용 중인 context: \(context)")
                
                print("=== SwiftData 저장 정보 ===")
                print("characterType: \(metadata.characterType)")
                print("phase(저장될 값): \(metadata.phase)")
                print("animationType: \(metadata.animationType)")
                print("frameIndex: \(metadata.frameIndex)")
                print("filePath: \(metadata.filePath)")
                print("========================")
                
                // ✅ 저장 전에 context 상태 확인
                print("context.hasChanges: \(context.hasChanges)")
                
                context.insert(metadata)
                print("✅ context.insert 완료")
                print("context.hasChanges (insert 후): \(context.hasChanges)")
                
                try context.save()
                print("✅ context.save() 완료")
                
                // ✅ 저장 직후 바로 조회해보기
                let testDescriptor = FetchDescriptor<GRAnimationMetadata>(
                    predicate: #Predicate { meta in
                        meta.characterType == characterType &&
                        meta.phase == englishPhase &&
                        meta.animationType == animationType &&
                        meta.frameIndex == frameIndex
                    }
                )
                
                let testResults = try context.fetch(testDescriptor)
                print("저장 직후 조회 결과: \(testResults.count)개")
                
                if let savedMetadata = testResults.first {
                    print("저장된 메타데이터 확인:")
                    print("  - characterType: \(savedMetadata.characterType)")
                    print("  - phase: \(savedMetadata.phase)")
                    print("  - animationType: \(savedMetadata.animationType)")
                    print("  - frameIndex: \(savedMetadata.frameIndex)")
                }
                
                print("✅ SwiftData 저장 완료: \(fileName)")
                completion(true)
                
            } catch {
                print("파일 저장 실패: \(fileName) - \(error)")
                completion(false)
            }
        }
    }
    
    // MARK: - 다운로드 상태 확인 기능
    
    // 각 성장 단계 + 애니메이션 타입별 총 프레임 수 정의
    private func getTotalFrameCount(for phase: CharacterPhase, animationType: AnimationType) -> Int {
        switch (phase, animationType) {
        // infant 단계
        case (.infant, .normal): return 122
        case (.infant, .sleeping): return 1
        case (.infant, .eating): return 1
        
        // child 단계
        case (.child, .normal): return 80    // 새로 추가된 경우
        case (.child, .sleeping): return 20
        case (.child, .eating): return 25
        
        // adolescent 단계
        case (.adolescent, .normal): return 60
        case (.adolescent, .sleeping): return 15
        case (.adolescent, .eating): return 18
        
        // adult 단계
        case (.adult, .normal): return 70
        case (.adult, .sleeping): return 12
        case (.adult, .eating): return 20
        
        // elder 단계
        case (.elder, .normal): return 90
        case (.elder, .sleeping): return 25
        case (.elder, .eating): return 30
        
        // egg는 Bundle에서 처리하므로 여기서는 0 반환
        case (.egg, _): return 0
        }
    }

    // 편의 메서드: 현재 phase와 animationType 기준으로 프레임 수 가져오기
    private func getCurrentTotalFrameCount(for animationType: AnimationType) -> Int {
        return getTotalFrameCount(for: currentPhase, animationType: animationType)
    }
    
    // 특정 애니메이션 타입이 완전히 다운로드되었는지 확인
    func isAnimationTypeDownloaded(_ animationType: AnimationType) -> Bool {
        guard let context = modelContext else {
            print("❌ ModelContext가 없음")
            return false
        }
        
        let phaseString = phaseToString(currentPhase)
        let characterType = "quokka"
        let animationTypeString = animationType.rawValue // 수정: animationType.rawValue를 미리 추출 (#Predicate 에러 방지)
        
        // 현재 phase + animationType에 맞는 마지막 프레임 번호 사용
        let lastFrameIndex = getCurrentTotalFrameCount(for: animationType)
        
        // 현재 phase + animationType에 맞는 총 프레임 수 (디버깅용)
        let expectedFrameCount = getCurrentTotalFrameCount(for: animationType)
        
        print("=== 다운로드 상태 확인 ===")
        print("characterType: \(characterType)")
        print("currentPhase: \(currentPhase.rawValue)")
        print("phaseString: \(phaseString)")
        print("animationType: \(animationTypeString)")
        print("마지막 프레임 번호: \(lastFrameIndex)")
        
        // egg 단계는 Bundle에서 처리하므로 항상 true 반환
        if currentPhase == .egg {
            print("✅ egg 단계 - Bundle에서 처리")
            return true
        }
        
        // 모든 프레임 수를 세어서 확인
        let descriptor = FetchDescriptor<GRAnimationMetadata>(
            predicate: #Predicate { metadata in
                metadata.characterType == characterType &&
                metadata.phase == phaseString &&
                metadata.animationType == animationTypeString
            }
        )
        
        do {
            let results = try context.fetch(descriptor)
            // let isDownloaded = !results.isEmpty

            // -- 디버깅 섹션 시작 --
            let actualFrameCount = results.count
            print("실제 저장된 프레임 수: \(actualFrameCount)")
            print("저장된 프레임 번호들: \(results.map { $0.frameIndex }.sorted())")
            
            // ✅ 실제 프레임 수가 예상 프레임 수와 같으면 다운로드 완료
            let isDownloaded = actualFrameCount == expectedFrameCount
            
            if !isDownloaded {
                print("⚠️ 다운로드 미완료: \(actualFrameCount)/\(expectedFrameCount)")
            } else {
                print("✅ 다운로드 완료: \(actualFrameCount)/\(expectedFrameCount)")
            }
            print("=================================")
            
            print("조회 결과 개수: \(results.count)")
            if let firstResult = results.first {
                print("발견된 메타데이터:")
                print("  - characterType: \(firstResult.characterType)")
                print("  - phase: \(firstResult.phase)")
                print("  - animationType: \(firstResult.animationType)")
                print("  - frameIndex: \(firstResult.frameIndex)")
                print("  - filePath: \(firstResult.filePath)")
                
                // 실제 파일 존재 여부도 확인
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fullPath = documentsPath.appendingPathComponent(firstResult.filePath).path
                let fileExists = FileManager.default.fileExists(atPath: fullPath)
                print("  - 실제 파일 존재: \(fileExists)")
            }
            
            print("\(phaseString)/\(animationType.rawValue) 다운로드 상태: \(isDownloaded)")
            print("=========================")
            // -- 디버깅 섹션 끝 --
            
            return isDownloaded
        } catch {
            print("다운로드 상태 확인 실패: \(error)")
            return false
        }
    }
    
    // 모든 애니메이션 타입이 다운로드되었는지 확인
    func areAllAnimationTypesDownloaded() -> Bool {
        return AnimationType.allCases.allSatisfy { isAnimationTypeDownloaded($0) }
    }
    
    // MARK: - SwiftData 삭제 기능
    
    // 현재 성장 단계의 모든 애니메이션 데이터 삭제
    func deleteAllAnimationData() {
        guard let context = modelContext else {
            print("SwiftData 컨텍스트가 설정되지 않음")
            return
        }
        
        let phaseString = phaseToString(currentPhase)
        let characterType = "quokka"
        
        let descriptor = FetchDescriptor<GRAnimationMetadata>(
            predicate: #Predicate { metadata in
                metadata.characterType == characterType &&
                metadata.phase == phaseString
            }
        )
        
        do {
            let metadataToDelete = try context.fetch(descriptor)
            print("삭제할 메타데이터 수: \(metadataToDelete.count)")
            
            // 파일 삭제
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            for metadata in metadataToDelete {
                let fileURL = documentsPath.appendingPathComponent(metadata.filePath)
                try? FileManager.default.removeItem(at: fileURL)
                print("파일 삭제: \(metadata.filePath)")
            }
            
            // SwiftData에서 메타데이터 삭제
            for metadata in metadataToDelete {
                context.delete(metadata)
            }
            
            try context.save()
            
            // 현재 애니메이션 프레임들도 초기화
            animationFrames.removeAll()
            currentFrame = nil
            
            print("모든 애니메이션 데이터 삭제 완료")
            
        } catch {
            print("데이터 삭제 실패: \(error)")
        }
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
    
    // MARK: - 디버깅용 임시 함수 (삭제 예정)
    // QuokkaControl.swift에 임시 디버깅 함수 추가
    func debugSwiftDataContents() {
        guard let context = modelContext else {
            print("❌ ModelContext가 없음")
            return
        }
        
        print("=== SwiftData 전체 내용 확인 ===")
        
        do {
            // 모든 quokka 메타데이터 조회
            let descriptor = FetchDescriptor<GRAnimationMetadata>(
                predicate: #Predicate { metadata in
                    metadata.characterType == "quokka"
                },
                sortBy: [SortDescriptor(\.phase), SortDescriptor(\.animationType), SortDescriptor(\.frameIndex)]
            )
            
            let allMetadata = try context.fetch(descriptor)
            print("총 저장된 메타데이터 개수: \(allMetadata.count)")
            
            // phase별로 그룹화해서 출력
            let groupedByPhase = Dictionary(grouping: allMetadata) { $0.phase }
            
            for (phase, metadataList) in groupedByPhase.sorted(by: { $0.key < $1.key }) {
                print("\n--- Phase: \(phase) ---")
                
                let groupedByAnimation = Dictionary(grouping: metadataList) { $0.animationType }
                
                for (animationType, frames) in groupedByAnimation.sorted(by: { $0.key < $1.key }) {
                    let frameIndices = frames.map { $0.frameIndex }.sorted()
                    let minFrame = frameIndices.min() ?? 0
                    let maxFrame = frameIndices.max() ?? 0
                    print("  \(animationType): \(frames.count)개 프레임 (범위: \(minFrame)~\(maxFrame))")
                    
                    // 처음 몇 개와 마지막 몇 개 프레임 번호 출력
                    if frameIndices.count > 10 {
                        let first5 = Array(frameIndices.prefix(5))
                        let last5 = Array(frameIndices.suffix(5))
                        print("    시작: \(first5)")
                        print("    끝: \(last5)")
                    } else {
                        print("    전체: \(frameIndices)")
                    }
                }
            }
            
            print("=============================")
            
        } catch {
            print("❌ SwiftData 내용 확인 실패: \(error)")
        }
    }
    
    // 저장된 파일의 메타데이터 확인
    func debugSwiftDataDatabase() {
        guard let context = modelContext else {
            print("❌ ModelContext가 없음")
            return
        }
        
        print("=== SwiftData 데이터베이스 상세 확인 ===")
        
        do {
            // 모든 애니메이션 메타데이터 가져오기 (조건 없이)
            let allDescriptor = FetchDescriptor<GRAnimationMetadata>()
            let allMetadata = try context.fetch(allDescriptor)
            
            print("전체 메타데이터 개수: \(allMetadata.count)")
            
            if allMetadata.isEmpty {
                print("⚠️ SwiftData에 메타데이터가 하나도 없습니다!")
                
                // 다른 가능한 이유들 확인
                print("\n--- 가능한 원인들 ---")
                print("1. 메타데이터 저장이 실패했을 수 있음")
                print("2. 다른 ModelContext를 사용하고 있을 수 있음")
                print("3. 데이터베이스 파일이 삭제되었을 수 있음")
                print("4. 백그라운드 스레드에서 저장 시 동기화 문제")
                
            } else {
                // 각 메타데이터의 상세 정보 출력
                for (index, metadata) in allMetadata.enumerated() {
                    print("\n--- 메타데이터 #\(index + 1) ---")
                    print("ID: \(metadata.id)")
                    print("characterType: '\(metadata.characterType)'")
                    print("phase: '\(metadata.phase)'")
                    print("animationType: '\(metadata.animationType)'")
                    print("frameIndex: \(metadata.frameIndex)")
                    print("filePath: '\(metadata.filePath)'")
                    print("fileSize: \(metadata.fileSize)")
                    print("downloadDate: \(metadata.downloadDate)")
                    print("lastAccessed: \(metadata.lastAccessed)")
                    print("isDownloaded: \(metadata.isDownloaded)")
                    
                    // 실제 파일 존재 여부 확인
                    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let fullPath = documentsPath.appendingPathComponent(metadata.filePath).path
                    let fileExists = FileManager.default.fileExists(atPath: fullPath)
                    print("실제 파일 존재: \(fileExists)")
                    
                    if !fileExists {
                        print("⚠️ 메타데이터는 있지만 실제 파일이 없음!")
                    }
                }
            }
            
            print("=====================================")
            
        } catch {
            print("❌ SwiftData 조회 실패: \(error)")
        }
    }
    
    // 파일 시스템 직접 확인
    func debugFileSystemContents() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let animationsPath = documentsPath.appendingPathComponent("animations")
        
        print("=== 파일 시스템 내용 확인 ===")
        print("Documents 경로: \(documentsPath.path)")
        print("Animations 경로: \(animationsPath.path)")
        
        // animations 폴더 존재 여부 확인
        let animationsExists = FileManager.default.fileExists(atPath: animationsPath.path)
        print("animations 폴더 존재: \(animationsExists)")
        
        if animationsExists {
            // 재귀적으로 모든 파일 탐색
            exploreDirectory(at: animationsPath.path, depth: 0)
        }
        
        print("============================")
    }

    private func exploreDirectory(at path: String, depth: Int) {
        let indent = String(repeating: "  ", count: depth)
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: path)
            
            for item in contents.sorted() {
                let itemPath = (path as NSString).appendingPathComponent(item)
                var isDirectory: ObjCBool = false
                
                if FileManager.default.fileExists(atPath: itemPath, isDirectory: &isDirectory) {
                    if isDirectory.boolValue {
                        print("\(indent)📁 \(item)/")
                        exploreDirectory(at: itemPath, depth: depth + 1)
                    } else {
                        // 파일 정보 출력
                        do {
                            let attributes = try FileManager.default.attributesOfItem(atPath: itemPath)
                            let fileSize = attributes[.size] as? Int ?? 0
                            let modificationDate = attributes[.modificationDate] as? Date ?? Date()
                            
                            let formatter = DateFormatter()
                            formatter.dateFormat = "HH:mm:ss"
                            let timeString = formatter.string(from: modificationDate)
                            
                            print("\(indent)📄 \(item) (\(formatFileSize(fileSize)), \(timeString))")
                        } catch {
                            print("\(indent)📄 \(item) (크기 확인 실패)")
                        }
                    }
                }
            }
        } catch {
            print("\(indent)❌ 디렉토리 읽기 실패: \(error)")
        }
    }

    private func formatFileSize(_ bytes: Int) -> String {
        if bytes < 1024 {
            return "\(bytes)B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1fKB", Double(bytes) / 1024.0)
        } else {
            return String(format: "%.1fMB", Double(bytes) / (1024.0 * 1024.0))
        }
    }
}
