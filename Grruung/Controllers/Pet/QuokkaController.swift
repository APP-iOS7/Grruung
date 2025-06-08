//
//  QuokkaController.swift
//  Grruung
//
//  Created by NoelMacMini on 6/2/25.
//

import SwiftUI
import SwiftData
import FirebaseStorage

// 간단한 쿼카 애니메이션 컨트롤러
@MainActor
class QuokkaController: ObservableObject {
    
    // MARK: - Published 프로퍼티들 (UI 업데이트용)
    @Published var currentFrame: UIImage? = nil         // 현재 표시할 프레임
    @Published var isAnimating: Bool = false            // 애니메이션 재생 중인지
    @Published var currentFrameIndex: Int = 0           // 현재 프레임 번호
    @Published var currentAnimationType: String = "normal"  // 현재 재생 중인 애니메이션 타입
    
    // 다운로드 관련
    @Published var isDownloading: Bool = false          // 다운로드 중인지
    @Published var downloadProgress: Double = 0.0       // 다운로드 진행률 (0.0 ~ 1.0)
    @Published var downloadMessage: String = ""         // 상태 메시지
    
    // MARK: - 비공개 프로퍼티들
    private var animationFrames: [UIImage] = []         // 로드된 애니메이션 프레임들
    private var animationTimer: Timer?                  // 애니메이션 타이머
    private var isReversing: Bool = false               // 역순 재생 중인지
    
    private let storage = Storage.storage()             // Firebase Storage
    private var modelContext: ModelContext?             // SwiftData 컨텍스트
    private let frameRate: Double = 24.0                // 초당 프레임 수
    
    // MARK: - 수면 애니메이션 관련 프로퍼티
    @Published var isSleepMode: Bool = false               // 수면 모드 여부
    private var sleepAnimationStep: Int = 0                // 수면 애니메이션 단계 (0: normal, 1: sleep1Start, 2: sleep2Pingpong)

    
    // MARK: - 고정 설정 (quokka만 처리)
    private let characterType = "quokka"
    
    // MARK: - 애니메이션 타입별 프레임 수 (infant 단계만)
    private let frameCountMap: [String: Int] = [
        "normal": 122,
        "sleeping": 1,  // 임시 값
        "eating": 1,     // 임시 값
        "sleep1Start": 204,
        "sleep2Pingpong": 60,
        "sleep3mouth": 54,
        "sleep4WakeUp": 173
    ]
    
    // 단계별 애니메이션 타입 매핑
    private func getAnimationTypesForPhase(_ phase: CharacterPhase) -> [String] {
        switch phase {
        case .egg:
            return ["normal"] // egg는 Bundle에 있으니 실제로는 사용 안함
        case .infant:
            return ["normal", "sleeping", "eating", "sleep1Start", "sleep2Pingpong", "sleep3mouth", "sleep4WakeUp"]
        case .child, .adolescent, .adult, .elder:
            return ["normal", "sleeping", "eating"] // 기본 애니메이션만
        }
    }
    
    // MARK: - SwiftData 컨텍스트 설정
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        print("✅ QuokkaController: SwiftData 컨텍스트 설정 완료")
    }
    
    // MARK: - 첫 번째 프레임만 로드 (기본 표시용)
    func loadFirstFrame(phase: CharacterPhase, animationType: String = "normal") {
        // egg 단계는 Bundle에서 로드
        if phase == .egg {
            currentFrame = UIImage(named: "egg_normal_1")
            return
        }
        
        // 다른 단계는 SwiftData에서 첫 번째 프레임만 로드
        loadSingleFrameFromSwiftData(phase: phase, animationType: animationType, frameIndex: 1)
    }
    
    // MARK: - SwiftData에서 특정 프레임 하나만 로드
    private func loadSingleFrameFromSwiftData(phase: CharacterPhase, animationType: String, frameIndex: Int) {
        guard let context = modelContext else {
            print("❌ SwiftData 컨텍스트가 없음")
            return
        }
        
        let phaseString = phase.toEnglishString()
        
        // 특정 프레임 하나만 조회
        let descriptor = FetchDescriptor<GRAnimationMetadata>(
            predicate: #Predicate { metadata in
                metadata.characterType == "quokka" &&
                metadata.phase == phaseString &&
                metadata.animationType == animationType &&
                metadata.frameIndex == frameIndex
            }
        )
        
        do {
            let results = try context.fetch(descriptor)
            if let metadata = results.first {
                // 파일에서 이미지 로드
                if let image = loadImageFromPath(metadata.filePath) {
                    currentFrame = image
                    currentFrameIndex = frameIndex - 1 // 0부터 시작하도록
                    print("✅ 첫 번째 프레임 로드 성공: \(metadata.filePath)")
                } else {
                    print("❌ 이미지 파일 로드 실패: \(metadata.filePath)")
                }
            } else {
                print("❌ 메타데이터를 찾을 수 없음: \(phaseString)/\(animationType)/\(frameIndex)")
            }
        } catch {
            print("❌ SwiftData 조회 실패: \(error)")
        }
    }
    
    // MARK: - 파일 경로에서 이미지 로드
    private func loadImageFromPath(_ filePath: String) -> UIImage? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imageURL = documentsPath.appendingPathComponent(filePath)
        
        // 파일 존재 확인
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            print("❌ 파일이 존재하지 않음: \(imageURL.path)")
            return nil
        }
        
        // 이미지 데이터 로드
        guard let imageData = try? Data(contentsOf: imageURL),
              let image = UIImage(data: imageData) else {
            print("❌ 이미지 로드 실패: \(filePath)")
            return nil
        }
        
        return image
    }
    
    // 전체 애니메이션 프레임 로드 (노멀 상태)
    func loadAnimationFrames(animationType: String = "normal") {
        guard let context = modelContext else {
            print("❌ SwiftData 컨텍스트가 없음")
            return
        }
        
        currentAnimationType = animationType
        
        // 현재는 infant 단계로 고정, 나중에 phase 매개변수 추가 가능
        let phaseString = "infant"
        
        // 모든 프레임 조회 (frameIndex로 정렬)
        let descriptor = FetchDescriptor<GRAnimationMetadata>(
            predicate: #Predicate { metadata in
                metadata.characterType == "quokka" &&
                metadata.phase == phaseString &&
                metadata.animationType == animationType
            },
            sortBy: [SortDescriptor(\.frameIndex)]
        )
        
        do {
            let metadataList = try context.fetch(descriptor)
            print("📥 \(animationType) 프레임 \(metadataList.count)개 발견")
            
            // 프레임들을 순서대로 로드
            var loadedFrames: [UIImage] = []
            for metadata in metadataList {
                if let image = loadImageFromPath(metadata.filePath) {
                    loadedFrames.append(image)
                }
            }
            
            animationFrames = loadedFrames
            
            if !animationFrames.isEmpty {
                currentFrame = animationFrames[0]
                currentFrameIndex = 0
                print("✅ \(animationFrames.count)개 \(animationType) 프레임 로드 완료")
            }
            
        } catch {
            print("❌ \(animationType) 프레임 로드 실패: \(error)")
        }
    }
    
    /// 기존 메타데이터에서 프레임들을 로드합니다
    private func loadExistingFramesFromMetadata(_ metadataList: [GRAnimationMetadata]) async {
        await MainActor.run {
            downloadMessage = "기존 데이터 로드 중..."
            downloadProgress = 0.2
        }
        
        // 메타데이터를 프레임 인덱스 순으로 정렬
        let sortedMetadata = metadataList.sorted { $0.frameIndex < $1.frameIndex }
        var loadedFrames: [UIImage] = []
        
        for (index, metadata) in sortedMetadata.enumerated() {
            // Documents 폴더에서 이미지 로드
            if let image = loadImageFromDocuments(fileName: URL(fileURLWithPath: metadata.filePath).lastPathComponent) {
                loadedFrames.append(image)
            } else {
                print("⚠️ 프레임 \(metadata.frameIndex) 로드 실패: \(metadata.filePath)")
            }
            
            // 진행률 업데이트 (20% ~ 80%)
            let progress = 0.2 + (Double(index + 1) / Double(sortedMetadata.count)) * 0.6
            await MainActor.run {
                downloadProgress = progress
                downloadMessage = "기존 데이터 로드 중... (\(index + 1)/\(sortedMetadata.count))"
            }
        }
        
        // 로드된 프레임들을 설정
        await MainActor.run {
            self.animationFrames = loadedFrames
            
            // 첫 번째 프레임을 현재 프레임으로 설정
            if !loadedFrames.isEmpty {
                self.currentFrame = loadedFrames[0]
            }
            
            downloadProgress = 0.9
            downloadMessage = "데이터 설정 완료"
        }
        
        print("✅ 기존 메타데이터에서 \(loadedFrames.count)개 프레임 로드 완료")
    }

    /// Documents 폴더에서 이미지를 로드합니다
    private func loadImageFromDocuments(fileName: String) -> UIImage? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        guard let imageData = try? Data(contentsOf: fileURL),
              let image = UIImage(data: imageData) else {
            return nil
        }
        
        return image
    }
    
    // MARK: - 다운로드 상태 확인
    // 다운로드 여부 확인
    func isPhaseDataDownloaded(phase: CharacterPhase) -> Bool {
        guard let context = modelContext, phase != .egg else {
            return phase == .egg // egg는 Bundle에 있으므로 항상 true
        }
        
        let phaseString = phase.toEnglishString()
        let animationTypes = getAnimationTypesForPhase(phase)
        
        // 모든 애니메이션 타입이 완전히 다운로드되었는지 확인
        for animationType in animationTypes {
            let expectedFrameCount = frameCountMap[animationType] ?? 0
            
            let descriptor = FetchDescriptor<GRAnimationMetadata>(
                predicate: #Predicate { metadata in
                    metadata.characterType == "quokka" &&
                    metadata.phase == phaseString &&
                    metadata.animationType == animationType
                }
            )
            
            do {
                let results = try context.fetch(descriptor)
                if results.count < expectedFrameCount {
                    print("❌ \(animationType) 다운로드 미완료: \(results.count)/\(expectedFrameCount)")
                    return false
                }
            } catch {
                print("❌ 다운로드 상태 확인 실패: \(error)")
                return false
            }
        }
        
        print("✅ \(phaseString) 단계 모든 데이터 다운로드 완료")
        return true
    }
    
    // MARK: - 데이터 완전성 확인
    /// [HomeViewModel] checkAnimationDataCompleteness 메서드에 사용
    func isPhaseDataComplete(phase: CharacterPhase, evolutionStatus: EvolutionStatus) -> Bool {
        guard let context = modelContext, phase != .egg else {
            return phase == .egg // egg는 Bundle에 있으므로 항상 완전함
        }
        
        let phaseString = phase.toEnglishString()
        
        // 진화 상태에 따라 필요한 애니메이션 타입 결정
        let requiredAnimationTypes = getRequiredAnimationTypes(
            phase: phase,
            evolutionStatus: evolutionStatus
        )
        
        // 각 애니메이션 타입의 완전성 확인
        for animationType in requiredAnimationTypes {
            if !isAnimationTypeComplete(
                phase: phaseString,
                animationType: animationType
            ) {
                print("❌ 미완료 애니메이션: \(animationType)")
                return false
            }
        }
        
        print("✅ 모든 애니메이션 데이터 완료: \(phaseString)")
        return true
    }
    
    // 진화 상태에 따른 필요 애니메이션 타입 반환
    /// [QuokkaController] isPhaseDataComplete 메서드에 사용
    private func getRequiredAnimationTypes(
        phase: CharacterPhase,
        evolutionStatus: EvolutionStatus
    ) -> [String] {
        // 기본 애니메이션들
        var required = ["normal", "sleeping", "eating"]
        
        // infant 단계에서 수면 애니메이션 추가
        if phase == .infant {
            required.append(contentsOf: [
                "sleep1Start",
                "sleep2Pingpong",
                "sleep3mouth",
                "sleep4WakeUp"
            ])
        }
        
        return required
    }
    
    // 특정 애니메이션 타입의 완전성 확인
    /// [QuokkaController] isPhaseDataComplete 메서드에 사용
    private func isAnimationTypeComplete(
        phase: String,
        animationType: String
    ) -> Bool {
        guard let context = modelContext else { return false }
        
        let expectedFrameCount = frameCountMap[animationType] ?? 0
        
        let descriptor = FetchDescriptor<GRAnimationMetadata>(
            predicate: #Predicate { metadata in
                metadata.characterType == "quokka" &&
                metadata.phase == phase &&
                metadata.animationType == animationType
            }
        )
        
        do {
            let results = try context.fetch(descriptor)
            return results.count >= expectedFrameCount
        } catch {
            print("❌ 완전성 확인 실패: \(error)")
            return false
        }
    }
    
    // 메타데이터에 해당하는 실제 파일들이 존재하는지 확인
    private func checkIfFilesExist(_ metadataList: [GRAnimationMetadata]) -> Bool {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // 처음 10개 파일만 샘플 체크 (성능상 이유)
        let sampleMetadata = Array(metadataList.prefix(10))
        
        for metadata in sampleMetadata {
            let fileURL = documentsDirectory.appendingPathComponent(metadata.filePath)
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                print("❌ 샘플 파일 없음: \(metadata.filePath)")
                return false
            }
        }
        
        print("✅ 샘플 파일들 존재 확인됨")
        return true
    }
    
    // MARK: - 정리 함수
    func cleanup() {
        stopAnimation()
        isAnimating = false
        animationFrames.removeAll()
        currentFrame = nil
        print("🧹 QuokkaController 정리 완료")
    }
}

// MARK: - 다운로드 기능
extension QuokkaController {
    // MARK: - Infant 단계 모든 데이터 다운로드
    func downloadInfantData() async {
        guard let context = modelContext else {
            await MainActor.run {
                updateDownloadState(message: "SwiftData 컨텍스트가 설정되지 않음")
            }
            return
        }
        
        let characterType = "quokka"
        let phase = CharacterPhase.infant
        let phaseString = "infant"
        let animationTypes = ["normal", "sleep1Start", "sleep2Pingpong", "sleep3mouth", "sleep4WakeUp"]
        
        do {
            // 모든 애니메이션 타입에 대해 확인
            var needsDownload = false
            var totalExpectedFrames = 0
            var existingFrameCount = 0
            
            // 기존 메타데이터 확인 및 검증 (각 애니메이션 타입별로 확인)
            for animationType in animationTypes {
                let expectedFrameCount = frameCountMap[animationType] ?? 0
                totalExpectedFrames += expectedFrameCount
                
                let phaseString = BundleAnimationLoader.phaseToString(phase)
                let predicate = #Predicate<GRAnimationMetadata> { metadata in
                    metadata.characterType == characterType &&
                    metadata.phase == phaseString &&
                    metadata.animationType == animationType
                }
                let fetchDescriptor = FetchDescriptor<GRAnimationMetadata>(predicate: predicate)
                let existingMetadata = try context.fetch(fetchDescriptor)
                
                let actualCount = existingMetadata.count
                existingFrameCount += actualCount
                
                print("📊 \(animationType): \(actualCount)/\(expectedFrameCount)개 프레임")
                
                // 프레임 수가 다르거나 파일이 없으면 다운로드 필요
                if actualCount != expectedFrameCount {
                    needsDownload = true
                    print("❌ \(animationType) 프레임 수 불일치")
                } else if !checkIfFilesExist(existingMetadata) {
                    needsDownload = true
                    print("❌ \(animationType) 파일 없음")
                }
            }
            
            // 다운로드가 필요하지 않으면 기존 데이터 로드
            if !needsDownload {
                print("✅ 모든 애니메이션 데이터 완료 - 로드만 진행")
                
                await MainActor.run {
                    downloadMessage = "이미 다운로드됨 - 로드 중..."
                    downloadProgress = 0.8
                }
                
                // normal 애니메이션 로드
                let normalPredicate = #Predicate<GRAnimationMetadata> { metadata in
                    metadata.characterType == characterType &&
                    metadata.phase == phaseString &&
                    metadata.animationType == "normal"
                }
                let normalDescriptor = FetchDescriptor<GRAnimationMetadata>(predicate: normalPredicate)
                let normalMetadata = try context.fetch(normalDescriptor)
                
                await loadExistingFramesFromMetadata(normalMetadata)
                
                await MainActor.run {
                    downloadProgress = 1.0
                    downloadMessage = "로드 완료!"
                }
                return
            }

            // 다운로드가 필요하면 기존 메타데이터 모두 삭제
            print("🗑️ 불완전한 데이터 정리 중...")
            for animationType in animationTypes {
                let phaseString = BundleAnimationLoader.phaseToString(phase)
                let predicate = #Predicate<GRAnimationMetadata> { metadata in
                    metadata.characterType == characterType &&
                    metadata.phase == phaseString &&
                    metadata.animationType == animationType
                }
                let fetchDescriptor = FetchDescriptor<GRAnimationMetadata>(predicate: predicate)
                let existingMetadata = try context.fetch(fetchDescriptor)
                
                for metadata in existingMetadata {
                    context.delete(metadata)
                }
            }
            try context.save()
            
            
            // 다운로드 시작
            await MainActor.run {
                updateDownloadState(isDownloading: true, progress: 0.0, message: "부화에 필요한 데이터를 받아오는 중...")
            }
            
            let animationTypes = ["normal", "sleeping", "eating", "sleep1Start", "sleep2Pingpong", "sleep3mouth", "sleep4WakeUp"]
            var totalFramesToDownload = 0
            
            // 총 프레임 수 계산
            for animationType in animationTypes {
                totalFramesToDownload += frameCountMap[animationType] ?? 0
            }
            
            print("📥 Infant 데이터 병렬 다운로드 시작 - 총 \(totalFramesToDownload)개 프레임")
            
            // 병렬 다운로드를 위한 TaskGroup 사용
            await withTaskGroup(of: Bool.self) { taskGroup in
                var completedFrames = 0
                
                // 모든 프레임을 병렬로 다운로드
                for animationType in animationTypes {
                    let frameCount = frameCountMap[animationType] ?? 0
                    
                    for frameIndex in 1...frameCount {
                        taskGroup.addTask { [weak self] in
                            guard let self = self else { return false }
                            
                            return await self.downloadSingleFrame(
                                animationType: animationType,
                                frameIndex: frameIndex,
                                context: context
                            )
                        }
                    }
                }
                
                // 완료된 작업들 수집 및 진행률 업데이트
                for await success in taskGroup {
                    if success {
                        completedFrames += 1
                    }
                    
                    // 진행률 업데이트 (메인 스레드에서)
                    let progress = Double(completedFrames) / Double(totalFramesToDownload)
                    let message = completedFrames < totalFramesToDownload * 3 / 4
                    ? "부화에 필요한 데이터를 받아오는 중..."
                    : "곧 부화가 완료됩니다..."
                    
                    await MainActor.run {
                        updateDownloadState(progress: progress, message: message)
                    }
                }
            }
            
            // 다운로드 완료
            await MainActor.run {
                updateDownloadState(
                    isDownloading: false,
                    progress: 1.0,
                    message: "부화가 완료되었습니다! 귀여운 쿼카가 태어났어요!"
                )
                
                // 첫 번째 프레임 로드
                loadFirstFrame(phase: .infant, animationType: "normal")
            }
            
            print("✅ Infant 데이터 병렬 다운로드 완료")
        } catch {
            await MainActor.run {
                downloadMessage = "다운로드 실패: \(error.localizedDescription)"
            }
            print("❌ 다운로드 실패: \(error)")
        }
    }
    
    // MARK: - 개별 프레임 다운로드
    private func downloadSingleFrame(
        animationType: String,
        frameIndex: Int,
        context: ModelContext
    ) async -> Bool {
        
        let fileName = "quokka_infant_\(animationType)_\(frameIndex).png"
        let firebasePath = "animations/quokka/infant/\(animationType)/\(fileName)"
        let storageRef = storage.reference().child(firebasePath)
        
        do {
            // Firebase에서 데이터 다운로드
            let data = try await storageRef.data(maxSize: 5 * 1024 * 1024) // 5MB 제한
            
            // 로컬 파일 경로 설정
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let localPath = "animations/quokka/infant/\(animationType)/\(fileName)"
            let fullURL = documentsPath.appendingPathComponent(localPath)
            
            // 디렉토리 생성
            let directoryURL = fullURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            
            // 파일 저장
            try data.write(to: fullURL)
            
            // SwiftData 저장을 별도 Task로 처리 (동시성 문제 방지)
            await MainActor.run {
                let metadata = GRAnimationMetadata(
                    characterType: "quokka",
                    phase: .infant,
                    animationType: animationType,
                    frameIndex: frameIndex,
                    filePath: localPath,
                    fileSize: data.count,
                    totalFramesInAnimation: frameCountMap[animationType] ?? 0
                )
                
                context.insert(metadata)
                do {
                    try context.save()
                } catch {
                    print("❌ 메타데이터 저장 실패: \(error)")
                }
            }
            
            print("✅ 프레임 다운로드 성공: \(fileName)")
            return true
            
        } catch {
            print("❌ 프레임 다운로드 실패: \(fileName) - \(error)")
            return false
        }
    }

    // MARK: - 다운로드 상태 업데이트 (메인 스레드에서 실행)
    @MainActor
    private func updateDownloadState(
        isDownloading: Bool? = nil,
        progress: Double? = nil,
        message: String? = nil
    ) {
        if let isDownloading = isDownloading {
            self.isDownloading = isDownloading
        }
        if let progress = progress {
            self.downloadProgress = progress
        }
        if let message = message {
            self.downloadMessage = message
        }
    }
    
    // MARK: - 진화 완료 처리
    @MainActor
    func completeEvolution() {
        // 진화 완료 후 첫 번째 프레임 로드
        loadFirstFrame(phase: .infant, animationType: "normal")
        
        // 상태 메시지 업데이트
        downloadMessage = "진화가 완료되었습니다!"
        downloadProgress = 1.0
        isDownloading = false
        
        print("🎉 진화 완료 - Infant 단계로 전환")
    }
    
    
    // MARK: - 애니메이션 재생
    // 핑퐁 애니메이션 시작
    func startPingPongAnimation() {
        guard !animationFrames.isEmpty, !isAnimating else {
            print("❌ 애니메이션 시작 불가: 프레임(\(animationFrames.count)), 재생중(\(isAnimating))")
            return
        }
        
        isAnimating = true
        isReversing = false
        currentFrameIndex = 0
        
        print("🎬 핑퐁 애니메이션 시작 - \(animationFrames.count)개 프레임")
        
        // 타이머 시작 (24fps = 약 0.042초 간격)
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / frameRate, repeats: true) { [weak self] _ in
            self?.updatePingPongFrame()
        }
    }
    
    // 핑퐁 애니메이션 정지
    func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        isAnimating = false
        isReversing = false
        
        print("⏹️ 애니메이션 정지")
    }
    
    // 핑퐁 프레임 업데이트
    private func updatePingPongFrame() {
        guard !animationFrames.isEmpty else { return }
        
        // 현재 프레임 이미지 업데이트
        currentFrame = animationFrames[currentFrameIndex]
        
        // 다음 프레임 인덱스 계산
        if isReversing {
            // 역순 재생 중 (122 → 1)
            currentFrameIndex -= 1
            
            // 첫 번째 프레임에 도달하면 정순으로 전환
            if currentFrameIndex <= 0 {
                currentFrameIndex = 0
                isReversing = false
                print("🔄 정순 재생으로 전환")
            }
        } else {
            // 정순 재생 중 (1 → 122)
            currentFrameIndex += 1
            
            // 마지막 프레임에 도달하면 역순으로 전환
            if currentFrameIndex >= animationFrames.count - 1 {
                currentFrameIndex = animationFrames.count - 1
                isReversing = true
                print("🔄 역순 재생으로 전환")
            }
        }
        
        // 디버깅용 로그 (매 30프레임마다)
        if currentFrameIndex % 30 == 0 {
            print("🎬 현재 프레임: \(currentFrameIndex + 1)/\(animationFrames.count) (\(isReversing ? "역순" : "정순"))")
        }
    }
    
    // 애니메이션 토글 (재생/정지)
    func toggleAnimation() {
        if isAnimating {
            stopAnimation()
        } else {
            startPingPongAnimation()
        }
    }
    
    // MARK: - 메타데이터 관리 메서드 (삭제 구현)
    /// 모든 애니메이션 메타데이터를 삭제합니다 (디버그용)
    func clearAllMetadata() {
        guard let modelContext = modelContext else {
            print("❌ SwiftData 컨텍스트가 설정되지 않음")
            return
        }
        
        do {
            // 모든 메타데이터 조회
            let fetchDescriptor = FetchDescriptor<GRAnimationMetadata>()
            let allMetadata = try modelContext.fetch(fetchDescriptor)
            
            print("🗑️ 총 \(allMetadata.count)개 메타데이터 삭제 시작")
            
            // 모든 메타데이터 삭제
            for metadata in allMetadata {
                modelContext.delete(metadata)
            }
            
            // 변경사항 저장
            try modelContext.save()
            
            print("✅ 모든 메타데이터 삭제 완료")
            
        } catch {
            print("❌ 메타데이터 삭제 실패: \(error)")
        }
    }

    /// 특정 캐릭터/단계/애니메이션의 메타데이터만 삭제
    func clearSpecificMetadata(characterType: String, phase: CharacterPhase, animationType: String) {
        guard let modelContext = modelContext else {
            print("❌ SwiftData 컨텍스트가 설정되지 않음")
            return
        }
        
        do {
            // 특정 조건의 메타데이터 조회
            let phaseString = BundleAnimationLoader.phaseToString(phase)
            let predicate = #Predicate<GRAnimationMetadata> { metadata in
                metadata.characterType == characterType &&
                metadata.phase == phaseString &&
                metadata.animationType == animationType
            }
            
            let fetchDescriptor = FetchDescriptor<GRAnimationMetadata>(predicate: predicate)
            let specificMetadata = try modelContext.fetch(fetchDescriptor)
            
            print("🗑️ \(characterType) \(phaseString) \(animationType) 메타데이터 \(specificMetadata.count)개 삭제")
            
            // 해당 메타데이터들 삭제
            for metadata in specificMetadata {
                modelContext.delete(metadata)
            }
            
            try modelContext.save()
            
            print("✅ 특정 메타데이터 삭제 완료")
            
        } catch {
            print("❌ 특정 메타데이터 삭제 실패: \(error)")
        }
    }
}

// MARK: - 수면 애니메이션
extension QuokkaController {
    // MARK: - 수면 애니메이션 시작
    func startSleepAnimation() {
        print("[QuokkaController] 수면 애니메이션 시작 요청")
        print("[QuokkaController] 현재 상태 - isAnimating: \(isAnimating), isSleepMode: \(isSleepMode)")
        
        // 기존 애니메이션 정지
        stopAnimation()
        
        isSleepMode = true
        sleepAnimationStep = 1
        
        // sleep1Start 애니메이션 로드 및 재생
        loadAndPlaySleepStartAnimation()
    }
    
    // MARK: - 수면 애니메이션 종료 (깨우기)
    func stopSleepAnimation() {
        print("[QuokkaController] 수면 애니메이션 종료 요청 - normal로 복귀")
        
        // 수면 모드 해제
        isSleepMode = false
        sleepAnimationStep = 0
        currentAnimationType = "normal"
        
        // 기존 애니메이션 정지
        stopAnimation()
        
        // normal 애니메이션으로 복귀
        loadAnimationFrames(animationType: "normal")
        startPingPongAnimation()
    }
    
    // MARK: - sleep1Start 애니메이션 로드 및 재생
    private func loadAndPlaySleepStartAnimation() {
        guard let context = modelContext else {
            print("❌ SwiftData 컨텍스트가 없음")
            return
        }
        
        currentAnimationType = "sleep1Start"
        
        // sleep1Start 프레임들 로드
        let descriptor = FetchDescriptor<GRAnimationMetadata>(
            predicate: #Predicate { metadata in
                metadata.characterType == "quokka" &&
                metadata.phase == "infant" &&
                metadata.animationType == "sleep1Start"
            },
            sortBy: [SortDescriptor(\.frameIndex)]
        )
        
        do {
            let metadataList = try context.fetch(descriptor)
            print("📥 sleep1Start 프레임 \(metadataList.count)개 로드")
            
            var loadedFrames: [UIImage] = []
            for metadata in metadataList {
                if let image = loadImageFromPath(metadata.filePath) {
                    loadedFrames.append(image)
                }
            }
            
            animationFrames = loadedFrames
            
            if !animationFrames.isEmpty {
                currentFrame = animationFrames[0]
                currentFrameIndex = 0
                
                // sleep1Start 애니메이션 시작 (한 번만 재생)
                startSleepStartAnimation()
            }
            
        } catch {
            print("❌ sleep1Start 로드 실패: \(error)")
        }
    }
    
    // MARK: - sleep1Start 애니메이션 재생 (한 번만)
    private func startSleepStartAnimation() {
        guard !animationFrames.isEmpty else { return }
        
        isAnimating = true
        currentFrameIndex = 0
        
        print("🎬 sleep1Start 애니메이션 시작 - \(animationFrames.count)개 프레임")
        
        // 타이머 시작 (한 번만 재생)
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / frameRate, repeats: true) { [weak self] _ in
            self?.updateSleepStartFrame()
        }
    }
    
    // MARK: - sleep1Start 프레임 업데이트
    private func updateSleepStartFrame() {
        guard !animationFrames.isEmpty else { return }
        
        // 현재 프레임 이미지 업데이트
        currentFrame = animationFrames[currentFrameIndex]
        
        // 다음 프레임으로 이동
        currentFrameIndex += 1
        
        // 마지막 프레임에 도달하면 sleep2Pingpong으로 전환
        if currentFrameIndex >= animationFrames.count {
            print("✅ sleep1Start 완료 - sleep2Pingpong으로 전환")
            
            // 타이머 정지
            animationTimer?.invalidate()
            animationTimer = nil
            isAnimating = false
            
            // sleep2Pingpong 애니메이션으로 전환
            sleepAnimationStep = 2
            loadAndPlaySleep2PingpongAnimation()
        }
        
        // MARK: - sleep2Pingpong 애니메이션 로드 및 재생
        func loadAndPlaySleep2PingpongAnimation() {
            guard let context = modelContext else {
                print("❌ SwiftData 컨텍스트가 없음")
                return
            }
            
            currentAnimationType = "sleep2Pingpong"
            
            // sleep2Pingpong 프레임들 로드
            let descriptor = FetchDescriptor<GRAnimationMetadata>(
                predicate: #Predicate { metadata in
                    metadata.characterType == "quokka" &&
                    metadata.phase == "infant" &&
                    metadata.animationType == "sleep2Pingpong"
                },
                sortBy: [SortDescriptor(\.frameIndex)]
            )
            
            do {
                let metadataList = try context.fetch(descriptor)
                print("📥 sleep2Pingpong 프레임 \(metadataList.count)개 로드")
                
                var loadedFrames: [UIImage] = []
                for metadata in metadataList {
                    if let image = loadImageFromPath(metadata.filePath) {
                        loadedFrames.append(image)
                    }
                }
                
                animationFrames = loadedFrames
                
                if !animationFrames.isEmpty {
                    currentFrame = animationFrames[0]
                    currentFrameIndex = 0
                    
                    // sleep2Pingpong 핑퐁 애니메이션 시작
                    startPingPongAnimation()
                }
                
            } catch {
                print("❌ sleep2Pingpong 로드 실패: \(error)")
            }
        }
    }
    
    

}


