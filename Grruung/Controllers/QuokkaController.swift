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
    
    // 다운로드 관련
    @Published var isDownloading: Bool = false          // 다운로드 중인지
    @Published var downloadProgress: Double = 0.0       // 다운로드 진행률 (0.0 ~ 1.0)
    @Published var downloadMessage: String = ""         // 상태 메시지
    
    // MARK: - 비공개 프로퍼티들
    private var animationFrames: [UIImage] = []         // 로드된 애니메이션 프레임들
    private let storage = Storage.storage()             // Firebase Storage
    private var modelContext: ModelContext?             // SwiftData 컨텍스트
    private let frameRate: Double = 24.0                // 초당 프레임 수
    
    // MARK: - 고정 설정 (quokka만 처리)
    private let characterType = "quokka"
    
    // MARK: - 애니메이션 타입별 프레임 수 (infant 단계만)
    private let frameCountMap: [String: Int] = [
        "normal": 122,
        "sleeping": 50,  // 예시 값
        "eating": 80     // 예시 값
    ]
    
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
    
    // MARK: - 다운로드 상태 확인
    func isPhaseDataDownloaded(phase: CharacterPhase) -> Bool {
        guard let context = modelContext, phase != .egg else {
            return phase == .egg // egg는 Bundle에 있으므로 항상 true
        }
        
        let phaseString = phase.toEnglishString()
        let animationTypes = ["normal", "sleeping", "eating"]
        
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
    
    // MARK: - 정리 함수
    func cleanup() {
        isAnimating = false
        animationFrames.removeAll()
        currentFrame = nil
        print("🧹 QuokkaController 정리 완료")
    }
}

// MARK: - 다운로드 기능
extension QuokkaController {
    // TODO: 다운로드 로직
    // - downloadInfantData()
    // - downloadSpecificAnimationType()
}

