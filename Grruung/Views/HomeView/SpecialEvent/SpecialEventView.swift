//
//  SpecialEventView.swift
//  Grruung
//
//  Created by KimJunsoo on 6/10/25.
//

import SwiftUI

struct SpecialEventView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: HomeViewModel
    @Binding var isPresented: Bool // 바인딩으로 변경
    
    @State private var currentIndex = 0
    @State private var events: [SpecialEvent] = []
    @State private var showingEventConfirmation = false
    @State private var selectedEvent: SpecialEvent?
    
    // MARK: - Init
    init(viewModel: HomeViewModel, isPresented: Binding<Bool>) {
        self.viewModel = viewModel
        self._isPresented = isPresented // 바인딩 초기화
        
        // 현재 레벨에 맞는 이벤트 목록 가져오기
        let level = viewModel.level
        _events = State(initialValue: SpecialEventManager.shared.getAvailableEvents(level: level))
    }
    
    // MARK: - Body
    var body: some View {
        // FIXME: - Start 수정내용
        // Alert 형태의 오버레이 뷰로 변경
        ZStack {
            // 배경 - 반투명 오버레이
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // 뷰 밖 영역 터치 시 닫기
                    withAnimation {
                        isPresented = false
                    }
                }
            
            // 메인 컨텐츠
            VStack(spacing: 15) {
                // 헤더
                HStack {
                    Text("특수 이벤트")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(GRColor.fontMainColor)
                    
                    Spacer()
                    
                    Button(action: {
                        // X 버튼 터치 시 닫기
                        withAnimation {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(GRColor.fontSubColor)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // 이벤트 카드
                if !events.isEmpty {
                    eventCardView
                        .padding(.vertical, 10)
                }
                
                // 이벤트 이름 및 설명
                if let event = getCurrentEvent() {
                    VStack(spacing: 10) {
                        Text(event.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(GRColor.fontMainColor)
                        
                        Text(event.description)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(GRColor.fontSubColor)
                            .padding(.horizontal)
                        
                        // 이벤트 효과 정보
                        effectsInfoView(for: event)
                            .padding(.vertical, 5)
                        
                        // 참여 버튼
                        Button(action: {
                            selectedEvent = event
                            showingEventConfirmation = true
                        }) {
                            Text(event.unlocked ? "참여하기" : "잠금됨")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(width: 180)
                                .background(
                                    Group {
                                        if event.unlocked {
                                            LinearGradient(
                                                gradient: Gradient(colors: [GRColor.buttonColor_1, GRColor.buttonColor_2]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        } else {
                                            Color.gray
                                        }
                                    }
                                )
                                .cornerRadius(10)
                        }
                        .disabled(!event.unlocked)
                        
                        // 요구 레벨 표시
                        if !event.unlocked {
                            Text("필요 레벨: \(event.requiredLevel)")
                                .font(.caption)
                                .foregroundColor(GRColor.fontSubColor)
                                .padding(.top, 5)
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(GRColor.mainColor5_1) // 밝은 배경색 사용
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            )
            .frame(width: UIScreen.main.bounds.width * 0.85, height: UIScreen.main.bounds.height * 0.6)
            .alert("이벤트 참여", isPresented: $showingEventConfirmation) {
                Button("취소", role: .cancel) {}
                Button("참여하기") {
                    participateInEvent()
                }
            } message: {
                if let event = selectedEvent {
                    Text("\(event.name)에 참여하시겠습니까? 활동력 \(event.activityCost)이 소모됩니다.")
                }
            }
            // 클릭 이벤트가 컨텐츠 내부에서만 작동하도록 함
            .contentShape(Rectangle())
            .onTapGesture {} // 빈 탭 제스처로 내부 탭이 외부로 전파되지 않도록 함
        }
        // FIXME: - END
    }
    
    // MARK: - Components
    
    /// 이벤트 카드 뷰 (이전 구현 유지)
    private var eventCardView: some View {
        // 기존 코드 유지...
        ZStack {
            // 이벤트 이미지
            if let event = getCurrentEvent() {
                // 실제 이미지가 없으므로 임시로 시스템 이미지 표시
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [GRColor.mainColor3_1, GRColor.mainColor3_2]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 280, height: 200)
                    
                    Image(systemName: event.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(GRColor.fontMainColor)
                    
                    // 잠금 상태 표시
                    if !event.unlocked {
                        ZStack {
                            Color.black.opacity(0.6)
                            Image(systemName: "lock.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.white)
                        }
                        .cornerRadius(20)
                    }
                }
            }
            
            // 이전/다음 버튼
            HStack {
                Button(action: {
                    withAnimation {
                        currentIndex = (currentIndex - 1 + events.count) % events.count
                    }
                }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(GRColor.fontMainColor)
                        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
                }
                .padding(.leading, 20)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        currentIndex = (currentIndex + 1) % events.count
                    }
                }) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(GRColor.fontMainColor)
                        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
                }
                .padding(.trailing, 20)
            }
            .frame(width: 300)
        }
    }
    
    /// 이벤트 효과 정보 뷰 (이전 구현 유지)
    private func effectsInfoView(for event: SpecialEvent) -> some View {
        // 기존 코드 유지...
        HStack(spacing: 15) {
            ForEach(getEffectInfo(for: event), id: \.icon) { effectInfo in
                VStack {
                    Image(systemName: effectInfo.icon)
                        .font(.title3)
                        .foregroundColor(effectInfo.color)
                    
                    Text(effectInfo.value > 0 ? "+\(effectInfo.value)" : "\(effectInfo.value)")
                        .font(.caption)
                        .foregroundColor(effectInfo.value > 0 ? GRColor.grColorGreen : GRColor.grColorRed)
                }
                .padding(8)
                .background(GRColor.mainColor1_1)
                .cornerRadius(8)
            }
        }
        .padding(.top, 5)
    }
    
    // MARK: - Methods
    
    /// 현재 선택된 이벤트 가져오기
    private func getCurrentEvent() -> SpecialEvent? {
        guard !events.isEmpty else { return nil }
        return events[currentIndex]
    }
    
    /// 이벤트 참여 처리
    private func participateInEvent() {
        guard let event = selectedEvent, event.unlocked else { return }
        
        // HomeViewModel의 public 메서드 호출
        let success = viewModel.participateInSpecialEvent(
            eventId: event.id,
            name: event.name,
            activityCost: event.activityCost,
            effects: event.effects,
            expGain: event.expGain,
            successMessage: event.successMessage,
            failMessage: event.failMessage
        )
        
        // 성공한 경우에만 화면 닫기
        if success {
            withAnimation {
                isPresented = false
            }
        }
    }
    
    /// 이벤트 효과 정보 가져오기 (이전 구현 유지)
    private func getEffectInfo(for event: SpecialEvent) -> [(icon: String, color: Color, value: Int)] {
        // 기존 코드 유지...
        var result: [(icon: String, color: Color, value: Int)] = []
        
        // 포만감
        if let value = event.effects["satiety"] {
            result.append(("fork.knife", GRColor.grColorOrange, value))
        }
        
        // 체력
        if let value = event.effects["stamina"] {
            result.append(("figure.run", GRColor.grColorBlue, value))
        }
        
        // 활동력 (항상 -activityCost)
        result.append(("bolt.fill", GRColor.grColorYellow, -event.activityCost))
        
        // 건강
        if let value = event.effects["healthy"] {
            result.append(("heart.fill", GRColor.grColorRed, value))
        }
        
        // 청결
        if let value = event.effects["clean"] {
            result.append(("shower.fill", GRColor.grColorOcean, value))
        }
        
        // 행복
        if let value = event.effects["happiness"] {
            result.append(("face.smiling", GRColor.grColorGreen, value))
        }
        
        return result
    }
}
