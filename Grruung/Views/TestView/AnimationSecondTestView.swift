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
    
    // 컨트롤 인스턴스
    @StateObject private var eggControl = EggControl() // EggControl 인스턴스
    @StateObject private var quokkaControl = QuokkaControl() // QuokkaControl 인스턴스
    @StateObject private var testController = TestController() // 새로운 TestController
    
    @Environment(\.modelContext) private var modelContext // SwiftData 환경
    
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
                    
                    // TestController 전용 테스트 섹션 (quokka + infant일 때만 표시)
                     if selectedCharacter == .quokka && selectedPhase == .infant {
                         testControllerSection
                     }
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("애니메이션 테스트 2")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // QuokkaControl에 SwiftData 컨텍스트 설정
                quokkaControl.setModelContext(modelContext)
                testController.setModelContext(modelContext)
                // 뷰가 나타날 때는 EggControl이 자동으로 첫 프레임을 로드함
                print("AnimationSecondTestView 나타남")
            }
            .onDisappear {
                // 뷰가 사라질 때 모든 컨트롤 정리
                eggControl.cleanup()
                quokkaControl.cleanup()
                testController.cleanup()
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
                // 선택된 캐릭터에 따라 다른 상태 정보 표시
                // TestController가 활성화된 경우 TestController 상태 표시
                if selectedCharacter == .quokka && selectedPhase == .infant {
                    HStack {
                        Text("TestController 프레임: \(testController.currentFrameIndex + 1)")
                            .font(.caption)
                            .foregroundColor(.purple)
                        
                        Text("상태: \(testController.isAnimating ? "재생중" : "정지")")
                            .font(.caption)
                            .foregroundColor(testController.isAnimating ? .green : .red)
                        
                        Text("로드됨: \(testController.loadedFrameCount)개")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                } else if selectedCharacter == .quokka && selectedPhase != .egg {
                    // 쿼카 + egg가 아닌 경우
                    HStack {
                        Text("프레임: \(quokkaControl.currentFrameIndex + 1)")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Text("상태: \(quokkaControl.isAnimating ? "재생중" : "정지")")
                            .font(.caption)
                            .foregroundColor(quokkaControl.isAnimating ? .green : .red)
                    }
                } else {
                    // egg 단계이거나 다른 캐릭터
                    HStack {
                        Text("프레임: \(eggControl.currentFrameIndex + 1)")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Text("상태: \(eggControl.isAnimating ? "재생중" : "정지")")
                            .font(.caption)
                            .foregroundColor(eggControl.isAnimating ? .green : .red)
                    }
                }
            }
            
            ZStack {
                // 배경
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 200)
                
                // 선택된 캐릭터에 따라 다른 컨트롤에서 이미지 가져오기
                if selectedCharacter == .quokka && selectedPhase == .infant {
                    // TestController 사용 (quokka + infant)
                    if let currentFrame = testController.currentFrame {
                        Image(uiImage: currentFrame)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 180)
                            .padding()
                    } else {
                        placeholderImage
                    }
                } else if selectedCharacter == .quokka && selectedPhase != .egg {
                    // 쿼카 + egg가 아닌 경우 QuokkaControl 사용
                    if let currentFrame = quokkaControl.currentFrame {
                        Image(uiImage: currentFrame)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 180)
                            .padding()
                    } else {
                        placeholderImage
                    }
                } else {
                    // egg 단계이거나 다른 캐릭터는 EggControl 사용
                    if let currentFrame = eggControl.currentFrame {
                        Image(uiImage: currentFrame)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 180)
                            .padding()
                    } else {
                        placeholderImage
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 2)
    }
        
    // 플레이스홀더 이미지
    private var placeholderImage: some View {
        VStack {
            Image(systemName: "photo")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text("프레임을 로드할 수 없습니다")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    // 애니메이션 컨트롤 섹션 추가 - 선택된 캐릭터에 따라 다른 컨트롤 사용
    private var animationControlSection: some View {
        VStack(spacing: 15) {
            Text("애니메이션 컨트롤")
                .font(.headline)
                .padding(.leading, 5)
            
            let isCurrentlyAnimating: Bool = {
                if selectedCharacter == .quokka && selectedPhase == .infant {
                    return testController.isAnimating
                } else if selectedCharacter == .quokka && selectedPhase != .egg {
                    return quokkaControl.isAnimating
                } else {
                    return eggControl.isAnimating
                }
            }()
            
            HStack(spacing: 20) {
                // 재생/정지 버튼
                Button(action: {
                    if selectedCharacter == .quokka && selectedPhase == .infant {
                        testController.toggleAnimation()
                    } else if selectedCharacter == .quokka && selectedPhase != .egg {
                        quokkaControl.toggleAnimation()
                    } else {
                        eggControl.toggleAnimation()
                    }
                }) {
                    HStack {
                        Image(systemName: isCurrentlyAnimating ? "pause.fill" : "play.fill")
                        Text(isCurrentlyAnimating ? "정지" : "재생")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(isCurrentlyAnimating ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                }
                
                // 정지 버튼
                Button(action: {
                    if selectedCharacter == .quokka && selectedPhase == .infant {
                        testController.stopAnimation()
                    } else if selectedCharacter == .quokka && selectedPhase != .egg {
                        quokkaControl.stopAnimation()
                    } else {
                        eggControl.stopAnimation()
                    }
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
                        // TODO: 나중에 다른 캐릭터 컨트롤러로 전환하는 로직 추가 예정
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
    
    // MARK: - 새로 추가된 TestController 전용 섹션
    private var testControllerSection: some View {
        VStack(spacing: 15) {
            Text("TestController 테스트 (Quokka Infant Normal)")
                .font(.headline)
                .foregroundColor(.purple)
                .padding(.leading, 5)
            
            // 다운로드 진행률 표시 (다운로드 중일 때만)
            if testController.isDownloading {
                VStack(spacing: 8) {
                    ProgressView(value: testController.downloadProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    Text(testController.downloadMessage)
                        .font(.caption)
                        .foregroundColor(.purple)
                }
                .padding(.horizontal)
            } else {
                // 상태 메시지 (다운로드 중이 아닐 때)
                Text(testController.downloadMessage)
                    .font(.caption)
                    .foregroundColor(.purple)
                    .padding(.horizontal)
            }
            
            // 테스트 버튼들
            VStack(spacing: 10) {
                HStack(spacing: 15) {
                    // 다운로드 버튼
                    Button(action: {
                        Task {
                            await testController.downloadAnimation()
                        }
                    }) {
                        HStack {
                            Image(systemName: testController.isDataDownloaded()
                                ? "checkmark.circle.fill" : "arrow.down.circle")
                            Text(testController.isDataDownloaded()
                                ? "다운로드 완료" : "다운로드")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(testController.isDataDownloaded()
                            ? Color.green.opacity(0.7) : Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                    }
                    .disabled(testController.isDownloading)
                    
                    Spacer()
                }
                
                HStack(spacing: 15) {
                    // 메타데이터 생성 버튼
                    Button(action: {
                        Task {
                            await testController.generateMetadataFromExistingFiles()
                        }
                    }) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                            Text("메타데이터 생성")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                    }
                    
                    Spacer()
                }
                
                HStack { // 새 테스트 버튼을 위한 HStack 또는 기존 VStack에 추가
                    Button(action: {
                        // TestController의 새 함수 호출
                        Task {
                            await testController.testDirectFileLoad()
                        }
                    }) {
                        Text("프레임1 직접 로드")
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.orange) // 다른 버튼과 구분되는 색상
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                    Spacer()
                }
                .padding(.top, 5) // 간격 조절
                
                HStack(spacing: 15) {
                    // 로드 버튼 (새로 추가)
                    Button(action: {
                        Task {
                            await testController.loadAnimationFromSwiftData()
                        }
                    }) {
                        HStack {
                            Image(systemName: "folder.circle")
                            Text("로드")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                    }
                    .disabled(testController.isDownloading || !testController.isDataDownloaded())
                    
                    // 재생 버튼
                    Button(action: {
                        testController.startAnimation()
                    }) {
                        HStack {
                            Image(systemName: "play.circle")
                            Text("재생")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(testController.loadedFrameCount > 0 ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                    }
                    .disabled(testController.loadedFrameCount == 0)
                    
                    Spacer()
                }
                
                HStack(spacing: 15) {
                    // 상태 정보 표시
                    VStack(alignment: .leading, spacing: 5) {
                        Text("상태 정보:")
                            .font(.caption)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 15) {
                            // 수정: TestController용 statusIndicator 사용
                            testStatusIndicator(
                                title: "다운로드됨",
                                isActive: testController.isDataDownloaded(),
                                color: .green
                            )
                            
                            testStatusIndicator(
                                title: "로드됨",
                                isActive: testController.loadedFrameCount > 0,
                                color: .blue
                            )
                            
                            testStatusIndicator(
                                title: "재생중",
                                isActive: testController.isAnimating,
                                color: .orange
                            )
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(15)
    }
    
    // MARK: - 헬퍼 함수
    
    // 개별 단계 버튼 헬퍼 함수
    private func phaseButton(_ phase: CharacterPhase) -> some View {
        Button(action: {
            selectedPhase = phase
            print("=== 단계 변경 ===")
            print("선택된 단계: \(phase.rawValue)")
            print("선택된 캐릭터: \(selectedCharacter.rawValue)")
            
            // 애니메이션 정지
            eggControl.stopAnimation()
            quokkaControl.stopAnimation()
            
            // 쿼카이고 egg가 아닌 경우 QuokkaControl 설정
            if selectedCharacter == .quokka && phase != .egg {
                print("QuokkaControl 설정 중...")
                quokkaControl.setPhase(phase)
            } else {
                print("EggControl 사용")
            }
            print("===============")
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
    
    // MARK: - 다운로드 버튼 섹션
    private var downloadButtonsSection: some View {
        VStack(spacing: 15) {
            Text("애니메이션 다운로드")
                .font(.headline)
                .padding(.leading, 5)
            
            // 다운로드 진행률 표시 (다운로드 중일 때만)
            if quokkaControl.isDownloading {
                VStack(spacing: 8) {
                    ProgressView(value: quokkaControl.downloadProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    Text(quokkaControl.downloadMessage)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(.horizontal)
            }
            
            // 디버깅 버튼 추가 (삭제 예정)
            HStack(spacing: 15) {
                Button(action: {
                    quokkaControl.debugSwiftDataContents()
                }) {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("SwiftData 내용 확인")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                }
                
                Button("파일시스템 확인") {
                    quokkaControl.debugFileSystemContents()
                }
                .buttonStyle(.bordered)
                
                Button("SwiftData 확인") {
                    quokkaControl.debugSwiftDataDatabase()
                }
                .buttonStyle(.bordered)
                
                Spacer()
            }
            
            // 다운로드 버튼들
            VStack(spacing: 10) {
                // Normal 애니메이션 다운로드 버튼
                HStack(spacing: 15) {
                    Button(action: {
                        quokkaControl.downloadAnimationType(.normal)
                    }) {
                        HStack {
                            Image(systemName: quokkaControl.isAnimationTypeDownloaded(.normal)
                                ? "checkmark.circle.fill" : "arrow.down.circle")
                            Text(quokkaControl.isAnimationTypeDownloaded(.normal)
                                ? "노멀 다운완료" : "노멀 다운로드")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(quokkaControl.isAnimationTypeDownloaded(.normal)
                            ? Color.green.opacity(0.7) : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                    }
                    .disabled(quokkaControl.isAnimationTypeDownloaded(.normal) || quokkaControl.isDownloading)
                    Spacer()
                }
                // 전체 애니메이션 다운로드 버튼
                HStack(spacing: 15) {
                    Button(action: {
                        quokkaControl.downloadAllAnimationTypes()
                    }) {
                        HStack {
                            Image(systemName: quokkaControl.areAllAnimationTypesDownloaded()
                                ? "checkmark.circle.fill" : "arrow.down.circle.fill")
                            Text(quokkaControl.areAllAnimationTypesDownloaded()
                                ? "전체 다운완료" : "전체 다운로드")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(quokkaControl.areAllAnimationTypesDownloaded()
                            ? Color.green.opacity(0.7) : Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                    }
                    .disabled(quokkaControl.areAllAnimationTypesDownloaded() || quokkaControl.isDownloading)
                    
                    Spacer()
                }
                
                // 전체 타입 삭제 버튼
                HStack(spacing: 15) {
                    Button(action: {
                        quokkaControl.deleteAllAnimationData()
                    }) {
                        HStack {
                            Image(systemName: "trash.circle.fill")
                            Text("전체 타입 삭제")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                    }
                    .disabled(quokkaControl.isDownloading)
                    
                    Spacer()
                }
            }
            
            // 현재 상태 정보 표시
            VStack(alignment: .leading, spacing: 5) {
                Text("다운로드 상태:")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                // 상태를 미리 계산하여 반복 호출 방지
                let normalStatus = quokkaControl.isAnimationTypeDownloaded(.normal)
                let sleepingStatus = quokkaControl.isAnimationTypeDownloaded(.sleeping)
                let eatingStatus = quokkaControl.isAnimationTypeDownloaded(.eating)
                
                HStack {
                    quokkaStatusIndicator(type: .normal, isDownloaded: normalStatus)
                    quokkaStatusIndicator(type: .sleeping, isDownloaded: sleepingStatus)
                    quokkaStatusIndicator(type: .eating, isDownloaded: eatingStatus)
                }
            }
            .padding(.top, 10)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(15)
    }
    
    // 수정: TestController용 상태 표시 인디케이터 (함수명 변경)
    private func testStatusIndicator(title: String, isActive: Bool, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isActive ? color : Color.gray)
                .font(.caption)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(isActive ? color : Color.gray)
        }
    }
    
    // 수정: QuokkaControl용 상태 표시 인디케이터 (함수명 변경)
    private func quokkaStatusIndicator(type: QuokkaControl.AnimationType, isDownloaded: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: isDownloaded ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isDownloaded ? Color.green : Color.gray)
                .font(.caption)
            
            Text(type.displayName)
                .font(.caption2)
                .foregroundColor(isDownloaded ? Color.green : Color.gray)
        }
    }
}

#Preview {
    AnimationSecondTestView()
}
