//
//  EggControl.swift
//  Grruung
//
//  Created by NoelMacMini on 5/30/25.
//

import SwiftUI

// 운석(Egg) 애니메이션을 컨트롤하는 클래스
class EggControl: ObservableObject {
    
    // MARK: - Published 프로퍼티들 (UI가 자동으로 업데이트됨)
    @Published var currentFrame: UIImage? = nil  // 현재 표시할 프레임
    @Published var isAnimating: Bool = false     // 애니메이션 재생 중인지 여부
    @Published var currentFrameIndex: Int = 0    // 현재 프레임 번호 (0부터 시작)
    
    // MARK: - 비공개 프로퍼티들
    private var animationFrames: [UIImage] = []  // 로드된 모든 애니메이션 프레임들
    private var animationTimer: Timer?           // 애니메이션 타이머
    private var animationType: String = "normal" // 현재 애니메이션 타입 (normal, break, hatch 등)
    
    // MARK: - 애니메이션 설정
    private let totalFrames = 241  // egg_normal_1.png ~ egg_normal_241.png
    private var frameRate: Double = 24.0  // 초당 프레임 수 (나중에 조절 가능)
    
    // MARK: - 초기화
    init() {
        // 기본 애니메이션 타입으로 프레임 로드
        loadAnimationFrames(animationType: "normal")
    }
    
    // MARK: - 애니메이션 프레임 로드 함수
    private func loadAnimationFrames(animationType: String) {
        // 현재 애니메이션 타입 저장
        self.animationType = animationType
        
        // 기존 프레임들 초기화
        animationFrames.removeAll()
        
        // 1번부터 241번까지 이미지 로드
        for frameNumber in 1...totalFrames {
            let imageName = "egg_\(animationType)_\(frameNumber)"
            
            // Bundle에서 이미지 찾기
            if let image = UIImage(named: imageName) {
                animationFrames.append(image)
                print("이미지 로드 성공: \(imageName)")
            } else {
                print("이미지 로드 실패: \(imageName)")
                // 이미지가 없으면 로드 중단
                break
            }
        }
        
        print("총 \(animationFrames.count)개 프레임 로드 완료")
        
        // 첫 번째 프레임을 현재 프레임으로 설정
        if !animationFrames.isEmpty {
            currentFrame = animationFrames[0]
            currentFrameIndex = 0
        }
    }
}
