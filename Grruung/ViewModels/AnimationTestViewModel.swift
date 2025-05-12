//
//  AnimationTestViewModel.swift
//  Grruung
//
//  Created by NoelMacMini on 5/12/25.
//

import SwiftUI
import SwiftData
import FirebaseStorage
import Combine

class AnimationTestViewModel: ObservableObject {
    // Firebase Storage 참조
    private let storage = Storage.storage().reference()
    
    // 메모리 캐시
    private let imageCache = NSCache<NSString, UIImage>()
    
    // 진행 상태
    @Published var isLoading = false
    @Published var progress: Double = 0
    @Published var message: String = ""
    @Published var errorMessage: String? = nil
    
    // SwiftData 컨텍스트
    private var modelContext: ModelContext?
    
    // 캐시 디렉토리 URL
    private let cacheDirectoryURL: URL
    
    // 취소 토큰
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // 캐시 제한 해제
        imageCache.countLimit = 0
        imageCache.totalCostLimit = 0
        
        // 캐시 디렉토리 설정
        if let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            cacheDirectoryURL = cachesDirectory.appendingPathComponent("animations", isDirectory: true)
            
            // 디렉토리 생성
            try? FileManager.default.createDirectory(at: cacheDirectoryURL,
                                                     withIntermediateDirectories: true)
        } else {
            // Fallback - 보통 여기까지 오지 않습니다
            cacheDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("animations", isDirectory: true)
        }
        
        // SwiftData 초기화
        setupSwiftData()
    }
    
    // SwiftData 설정
    private func setupSwiftData() {
        do {
            let schema = Schema([GRAnimationMetadata.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContext = ModelContext(container)
        } catch {
            errorMessage = "SwiftData 초기화 실패: \(error.localizedDescription)"
            print("SwiftData 초기화 실패: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Firebase에서 애니메이션 다운로드
    
    /// 특정 캐릭터의 애니메이션 타입 다운로드
    func downloadAnimation(characterType: String, animationType: String) {
        guard let modelContext = modelContext else {
            errorMessage = "데이터 컨텍스트 초기화 실패"
            return
        }
        
        isLoading = true
        progress = 0
        message = "다운로드 준비 중..."
        errorMessage = nil
        
        // 다운로드할 폴더 경로
        let animationPath = "animations/\(characterType)/\(animationType)"
        let folderRef = storage.child(animationPath)
        
        // 폴더 내 모든 파일 목록 가져오기
        folderRef.listAll { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "파일 목록 가져오기 실패: \(error.localizedDescription)"
                    self.isLoading = false
                }
                return
            }
            
            guard let result = result, !result.items.isEmpty else {
                DispatchQueue.main.async {
                    self.errorMessage = "애니메이션 파일 없음: \(animationPath)"
                    self.isLoading = false
                }
                return
            }
            
            // 파일명 기준으로 정렬 (숫자 순서대로)
            let sortedItems = result.items.sorted { item1, item2 in
                // 파일명에서 숫자 추출하여 정렬
                let name1 = item1.name.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
                let name2 = item2.name.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
                
                if let num1 = Int(name1), let num2 = Int(name2) {
                    return num1 < num2
                }
                return item1.name < item2.name
            }
            
            // 다운로드할 총 파일 수
            let totalFiles = sortedItems.count
            var downloadedFiles = 0
            
            DispatchQueue.main.async {
                self.message = "애니메이션 프레임 \(totalFiles)개 다운로드 중..."
            }
            
            // 캐릭터 애니메이션 타입 폴더 경로
            let animationDirectory = self.cacheDirectoryURL
                .appendingPathComponent(characterType, isDirectory: true)
                .appendingPathComponent(animationType, isDirectory: true)
            
            // 폴더 생성
            try? FileManager.default.createDirectory(at: animationDirectory,
                                                     withIntermediateDirectories: true)
            
            // 각 이미지 파일 다운로드
            for (index, item) in sortedItems.enumerated() {
                // 저장할 파일 이름 결정 (Firebase 파일명 그대로 사용)
                let fileName = item.name
                
                // 프레임 인덱스 추출 (파일명에서 숫자 부분)
                let frameIndexString = fileName.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
                let frameIndex = Int(frameIndexString) ?? (index + 1)
                
                // 로컬 저장 경로
                let localURL = animationDirectory.appendingPathComponent(fileName)
                
                // 파일 이미 존재하는지 확인
                if FileManager.default.fileExists(atPath: localURL.path) {
                    // 이미 존재하는 파일 메타데이터 업데이트
                    self.updateMetadata(
                        characterType: characterType,
                        animationType: animationType,
                        frameIndex: frameIndex,
                        filePath: localURL.path
                    )
                    
                    // 카운트 증가 및 진행률 업데이트
                    downloadedFiles += 1
                    let progress = Double(downloadedFiles) / Double(totalFiles)
                    
                    DispatchQueue.main.async {
                        self.progress = progress
                        self.message = "다운로드 중... (\(downloadedFiles)/\(totalFiles))"
                        
                        // 모든 파일 처리 완료
                        if downloadedFiles == totalFiles {
                            self.message = "다운로드 완료! \(totalFiles)개 프레임"
                            self.isLoading = false
                        }
                    }
                    continue
                }
                
                // Firebase에서 파일 다운로드
                let downloadTask = item.write(toFile: localURL)
                
                // 진행률 업데이트
                downloadTask.observe(.progress) { snapshot in
                    let fileProgress = (snapshot.progress?.fractionCompleted ?? 0)
                    let overallProgress = (Double(downloadedFiles) + fileProgress) / Double(totalFiles)
                    
                    DispatchQueue.main.async {
                        self.progress = overallProgress
                    }
                }
                
                // 완료 처리
                downloadTask.observe(.success) { snapshot in
                    do {
                        // 파일 크기 확인
                        let fileAttributes = try FileManager.default.attributesOfItem(atPath: localURL.path)
                        let fileSize = fileAttributes[.size] as? Int ?? 0
                        
                        // 메타데이터 저장
                        self.saveMetadata(
                            characterType: characterType,
                            animationType: animationType,
                            frameIndex: frameIndex,
                            filePath: localURL.path,
                            fileSize: fileSize
                        )
                        
                        // 선택적으로 메모리 캐시에 추가
                        if let image = UIImage(contentsOfFile: localURL.path) {
                            let cacheKey = self.getCacheKey(
                                characterType: characterType,
                                animationType: animationType,
                                frameIndex: frameIndex
                            )
                            self.imageCache.setObject(image, forKey: cacheKey as NSString)
                        }
                        
                        // 진행 카운터 업데이트
                        downloadedFiles += 1
                        
                        DispatchQueue.main.async {
                            self.message = "다운로드 중... (\(downloadedFiles)/\(totalFiles))"
                            
                            // 모든 파일 다운로드 완료
                            if downloadedFiles == totalFiles {
                                self.message = "다운로드 완료! \(totalFiles)개 프레임"
                                self.isLoading = false
                            }
                        }
                    } catch {
                        print("파일 크기 확인 오류: \(error.localizedDescription)")
                        
                        // 오류가 있어도 진행 카운터 업데이트
                        downloadedFiles += 1
                    }
                }
                
                // 오류 처리
                downloadTask.observe(.failure) { snapshot in
                    print("다운로드 실패: \(item.name), 오류: \(snapshot.error?.localizedDescription ?? "알 수 없음")")
                    
                    // 오류가 있어도 진행 카운터 업데이트
                    downloadedFiles += 1
                    
                    // 만약 모든 처리가 완료되었다면 전체 종료
                    if downloadedFiles == totalFiles {
                        DispatchQueue.main.async {
                            self.message = "다운로드 완료 (일부 파일 오류)"
                            self.isLoading = false
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 이미지 로드 메서드
    
    /// 특정 애니메이션 프레임 이미지 로드
    func loadAnimationFrame(characterType: String, animationType: String, frameIndex: Int) -> UIImage? {
        // 1. 메모리 캐시 확인
        let cacheKey = getCacheKey(characterType: characterType, animationType: animationType, frameIndex: frameIndex)
        if let cachedImage = imageCache.object(forKey: cacheKey as NSString) {
            // 메타데이터 접근 시간 업데이트
            updateLastAccessedTime(characterType: characterType, animationType: animationType, frameIndex: frameIndex)
            return cachedImage
        }
        
        // 2. 파일 시스템에서 로드
        guard let filePath = getFilePath(characterType: characterType, animationType: animationType, frameIndex: frameIndex),
              let image = UIImage(contentsOfFile: filePath) else {
            return nil
        }
        
        // 메모리 캐시에 추가
        imageCache.setObject(image, forKey: cacheKey as NSString)
        
        // 메타데이터 접근 시간 업데이트
        updateLastAccessedTime(characterType: characterType, animationType: animationType, frameIndex: frameIndex)
        
        return image
    }
    
    /// 애니메이션의 모든 프레임 로드 (특정 캐릭터와 애니메이션 타입의)
    func loadAllAnimationFrames(characterType: String, animationType: String) -> [UIImage] {
        guard let modelContext = modelContext else { return [] }
        
        do {
            // 특정 캐릭터와 애니메이션 타입의 모든 메타데이터 쿼리
            let descriptor = FetchDescriptor<GRAnimationMetadata>(
                predicate: #Predicate {
                    $0.characterType == characterType && $0.animationType == animationType
                },
                sortBy: [SortDescriptor(\.frameIndex)]
            )
            
            let metadataItems = try modelContext.fetch(descriptor)
            
            // 각 프레임 로드
            var frames: [UIImage] = []
            for metadata in metadataItems {
                if let image = UIImage(contentsOfFile: metadata.filePath) {
                    frames.append(image)
                    
                    // 메모리 캐시에 추가
                    let cacheKey = getCacheKey(
                        characterType: metadata.characterType,
                        animationType: metadata.animationType,
                        frameIndex: metadata.frameIndex
                    )
                    imageCache.setObject(image, forKey: cacheKey as NSString)
                    
                    // 마지막 접근 시간 업데이트
                    metadata.lastAccessed = Date()
                }
            }
            
            // 변경사항 저장
            try modelContext.save()
            
            return frames
        } catch {
            print("애니메이션 프레임 로드 실패: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - 유틸리티 메서드
    
    /// 캐시 키 생성
    private func getCacheKey(characterType: String, animationType: String, frameIndex: Int) -> String {
        return "\(characterType)_\(animationType)_\(frameIndex)"
    }
    
    /// 파일 경로 가져오기
    private func getFilePath(characterType: String, animationType: String, frameIndex: Int) -> String? {
        guard let modelContext = modelContext else { return nil }
        
        do {
            // 메타데이터 쿼리
            let descriptor = FetchDescriptor<GRAnimationMetadata>(
                predicate: #Predicate {
                    $0.characterType == characterType &&
                    $0.animationType == animationType &&
                    $0.frameIndex == frameIndex
                }
            )
            
            let metadataItems = try modelContext.fetch(descriptor)
            return metadataItems.first?.filePath
        } catch {
            print("파일 경로 쿼리 실패: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 메타데이터 저장
    private func saveMetadata(characterType: String, animationType: String, frameIndex: Int, filePath: String, fileSize: Int) {
        guard let modelContext = modelContext else { return }
        
        // 기존 메타데이터 확인
        do {
            let descriptor = FetchDescriptor<GRAnimationMetadata>(
                predicate: #Predicate {
                    $0.characterType == characterType &&
                    $0.animationType == animationType &&
                    $0.frameIndex == frameIndex
                }
            )
            
            let existingItems = try modelContext.fetch(descriptor)
            
            if let existingMetadata = existingItems.first {
                // 기존 메타데이터 업데이트
                existingMetadata.filePath = filePath
                existingMetadata.fileSize = fileSize
                existingMetadata.downloadDate = Date()
                existingMetadata.lastAccessed = Date()
                existingMetadata.isDownloaded = true
            } else {
                // 새 메타데이터 생성
                let metadata = GRAnimationMetadata(
                    characterType: characterType,
                    animationType: animationType,
                    frameIndex: frameIndex,
                    filePath: filePath,
                    fileSize: fileSize
                )
                
                modelContext.insert(metadata)
            }
            
            // 변경사항 저장
            try modelContext.save()
        } catch {
            print("메타데이터 저장 실패: \(error.localizedDescription)")
        }
    }
    
    /// 메타데이터 업데이트
    private func updateMetadata(characterType: String, animationType: String, frameIndex: Int, filePath: String) {
        guard let modelContext = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<GRAnimationMetadata>(
                predicate: #Predicate {
                    $0.characterType == characterType &&
                    $0.animationType == animationType &&
                    $0.frameIndex == frameIndex
                }
            )
            
            let metadataItems = try modelContext.fetch(descriptor)
            
            if let metadata = metadataItems.first {
                // 기존 메타데이터 업데이트
                metadata.filePath = filePath
                metadata.lastAccessed = Date()
                metadata.isDownloaded = true
            } else {
                // 새 메타데이터 생성 (파일 크기는 나중에 업데이트)
                let metadata = GRAnimationMetadata(
                    characterType: characterType,
                    animationType: animationType,
                    frameIndex: frameIndex,
                    filePath: filePath
                )
                
                modelContext.insert(metadata)
            }
            
            // 변경사항 저장
            try modelContext.save()
        } catch {
            print("메타데이터 업데이트 실패: \(error.localizedDescription)")
        }
    }
    
    /// 마지막 접근 시간 업데이트
    private func updateLastAccessedTime(characterType: String, animationType: String, frameIndex: Int) {
        guard let modelContext = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<GRAnimationMetadata>(
                predicate: #Predicate {
                    $0.characterType == characterType &&
                    $0.animationType == animationType &&
                    $0.frameIndex == frameIndex
                }
            )
            
            let metadataItems = try modelContext.fetch(descriptor)
            
            if let metadata = metadataItems.first {
                metadata.lastAccessed = Date()
                try modelContext.save()
            }
        } catch {
            print("접근 시간 업데이트 실패: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 캐시 관리 메서드
    
    /// 특정 애니메이션 관련 캐시 삭제
    func clearCache(characterType: String, animationType: String) {
        guard let modelContext = modelContext else { return }
        
        do {
            // 메타데이터 쿼리
            let descriptor = FetchDescriptor<GRAnimationMetadata>(
                predicate: #Predicate {
                    $0.characterType == characterType && $0.animationType == animationType
                }
            )
            
            let metadataItems = try modelContext.fetch(descriptor)
            
            // 파일 삭제 및 메타데이터 삭제
            for metadata in metadataItems {
                // 파일 시스템에서 삭제
                try? FileManager.default.removeItem(atPath: metadata.filePath)
                
                // 메모리 캐시에서 삭제
                let cacheKey = getCacheKey(
                    characterType: metadata.characterType,
                    animationType: metadata.animationType,
                    frameIndex: metadata.frameIndex
                )
                imageCache.removeObject(forKey: cacheKey as NSString)
                
                // SwiftData에서 삭제
                modelContext.delete(metadata)
            }
            
            // 변경사항 저장
            try modelContext.save()
            
            print("\(characterType)/\(animationType) 캐시 삭제 완료: \(metadataItems.count)개 항목")
        } catch {
            print("캐시 삭제 실패: \(error.localizedDescription)")
        }
    }
    
    /// 모든 캐시 삭제
    func clearAllCache() {
        guard let modelContext = modelContext else { return }
        
        do {
            // 모든 메타데이터 가져오기
            let descriptor = FetchDescriptor<GRAnimationMetadata>()
            let allMetadata = try modelContext.fetch(descriptor)
            
            // 파일 삭제 및 메타데이터 삭제
            for metadata in allMetadata {
                // 파일 시스템에서 삭제
                try? FileManager.default.removeItem(atPath: metadata.filePath)
                
                // SwiftData에서 삭제
                modelContext.delete(metadata)
            }
            
            // 메모리 캐시 비우기
            imageCache.removeAllObjects()
            
            // 변경사항 저장
            try modelContext.save()
            
            print("모든 캐시 삭제 완료: \(allMetadata.count)개 항목")
        } catch {
            print("모든 캐시 삭제 실패: \(error.localizedDescription)")
        }
    }
    
    /// 오래된 캐시 삭제 (일정 기간 이상 접근하지 않은 항목)
    func clearOldCache(olderThanDays: Int = 30) {
        guard let modelContext = modelContext else { return }
        
        // 기준 날짜 계산
        let calendar = Calendar.current
        guard let cutoffDate = calendar.date(byAdding: .day, value: -olderThanDays, to: Date()) else { return }
        
        do {
            // 오래된 메타데이터 쿼리
            let descriptor = FetchDescriptor<GRAnimationMetadata>(
                predicate: #Predicate { $0.lastAccessed < cutoffDate }
            )
            
            let oldMetadata = try modelContext.fetch(descriptor)
            
            // 파일 삭제 및 메타데이터 삭제
            for metadata in oldMetadata {
                // 파일 시스템에서 삭제
                try? FileManager.default.removeItem(atPath: metadata.filePath)
                
                // 메모리 캐시에서 삭제
                let cacheKey = getCacheKey(
                    characterType: metadata.characterType,
                    animationType: metadata.animationType,
                    frameIndex: metadata.frameIndex
                )
                imageCache.removeObject(forKey: cacheKey as NSString)
                
                // SwiftData에서 삭제
                modelContext.delete(metadata)
            }
            
            // 변경사항 저장
            try modelContext.save()
            
            print("오래된 캐시 삭제 완료: \(oldMetadata.count)개 항목")
        } catch {
            print("오래된 캐시 삭제 실패: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 정보 제공 메서드
    
    /// 특정 애니메이션 프레임 개수 가져오기
    func getFrameCount(characterType: String, animationType: String) -> Int {
        guard let modelContext = modelContext else { return 0 }
        
        do {
            // 메타데이터 쿼리
            let descriptor = FetchDescriptor<GRAnimationMetadata>(
                predicate: #Predicate {
                    $0.characterType == characterType && $0.animationType == animationType
                },
                sortBy: [SortDescriptor(\.frameIndex)]
            )
            
            let metadataItems = try modelContext.fetch(descriptor)
            return metadataItems.count
        } catch {
            print("프레임 개수 가져오기 실패: \(error.localizedDescription)")
            return 0
        }
    }
    
    /// 특정 애니메이션 총 크기 가져오기
    func getTotalSize(characterType: String, animationType: String) -> Int {
        guard let modelContext = modelContext else { return 0 }
        
        do {
            // 메타데이터 쿼리
            let descriptor = FetchDescriptor<GRAnimationMetadata>(
                predicate: #Predicate {
                    $0.characterType == characterType && $0.animationType == animationType
                }
            )
            
            let metadataItems = try modelContext.fetch(descriptor)
            let totalSize = metadataItems.reduce(0) { $0 + $1.fileSize }
            return totalSize
        } catch {
            print("애니메이션 크기 가져오기 실패: \(error.localizedDescription)")
            return 0
        }
    }
    
    /// 모든 애니메이션 목록 가져오기
    func getAllAnimations() -> [(characterType: String, animationType: String, frameCount: Int)] {
        guard let modelContext = modelContext else { return [] }
        
        do {
            // 모든 메타데이터 가져오기
            let descriptor = FetchDescriptor<GRAnimationMetadata>()
            let allMetadata = try modelContext.fetch(descriptor)
            
            // 고유한 캐릭터-애니메이션 조합 추출
            var uniqueCombinations: Set<String> = []
            var result: [(characterType: String, animationType: String, frameCount: Int)] = []
            
            for metadata in allMetadata {
                let key = "\(metadata.characterType)|\(metadata.animationType)"
                if !uniqueCombinations.contains(key) {
                    uniqueCombinations.insert(key)
                    
                    // 해당 조합의 프레임 개수 계산
                    let count = getFrameCount(
                        characterType: metadata.characterType,
                        animationType: metadata.animationType
                    )
                    
                    result.append((
                        characterType: metadata.characterType,
                        animationType: metadata.animationType,
                        frameCount: count
                    ))
                }
            }
            
            return result
        } catch {
            print("애니메이션 목록 가져오기 실패: \(error.localizedDescription)")
            return []
        }
    }
    
    // 리소스 정리
    func cleanup() {
        cancellables.removeAll()
    }
}
