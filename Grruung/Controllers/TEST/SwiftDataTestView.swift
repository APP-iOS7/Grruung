//
//  SwiftDataTestView.swift
//  Grruung
//
//  Created by NoelMacMini on 6/2/25.
//

import SwiftUI
import SwiftData

// SwiftData 테스트용 뷰
struct SwiftDataTestView: View {
    // 환경 변수들은 수정 필요 없음
    @Environment(\.modelContext) private var modelContext
    @Query private var imageModels: [ImageTestModel]
    @State private var debugMessage: String = ""
    
    // 로드된 데이터를 보여주기 위한 상태 변수 추가
    @State private var loadedData: [ImageTestModel] = []
    @State private var isDataLoaded: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                // 상단, 중간 부분은 수정 필요 없음
                Text("저장된 이미지 데이터: \(imageModels.count)개")
                    .font(.headline)
                    .padding()
                
                // 로드된 데이터 개수도 표시
                Text("로드된 데이터: \(loadedData.count)개")
                    .font(.subheadline)
                    .foregroundColor(.green)
                
                if !debugMessage.isEmpty {
                    Text(debugMessage)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding()
                }
                
                // 중간: 테스트 버튼들
                VStack(spacing: 15) {
                    HStack(spacing: 10) {
                        Button("데이터 추가") {
                            addSampleDataWithDebug()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("데이터 로드") {
                            loadDataFromSwiftData()
                        }
                        .buttonStyle(.borderedProminent)
                        .foregroundColor(.green)
                    }
                    
                    HStack(spacing: 10) {
                        Button("새로고침") {
                            refreshData()
                        }
                        .buttonStyle(.bordered)
                        
                        // 새로 추가: 디버깅 버튼
                        Button("디버깅") {
                            debugModelContext()
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.purple)
                    }
                    
                    HStack(spacing: 10) {
                        Button("모든 삭제") {
                            deleteAllDataWithDebug()
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    }
                }
                .padding()
                
                // 하단: 저장된 데이터 목록 표시
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        // @Query로 자동 로드되는 데이터
                        Text("@Query 자동 로드 데이터:")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(imageModels) { model in
                            dataRow(model: model, source: "자동")
                        }
                        
                        // 수동으로 로드한 데이터
                        if isDataLoaded {
                            Text("수동 로드 데이터:")
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.top)
                            
                            ForEach(loadedData) { model in
                                dataRow(model: model, source: "수동")
                            }
                        }
                    }
                }
            }
            .navigationTitle("SwiftData 테스트")
        }
    }
                
    // 데이터 행을 표시하는 재사용 가능한 뷰
    @ViewBuilder
    private func dataRow(model: ImageTestModel, source: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("\(model.characterType) - \(model.phaseType)")
                    .font(.headline)
                Spacer()
                Text("[\(source)]")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(source == "자동" ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                    .cornerRadius(4)
            }
            Text("애니메이션: \(model.animationType)")
                .font(.caption)
            Text("프레임: \(model.frameIndex)")
                .font(.caption)
            Text("다운로드: \(model.isDownloaded ? "완료" : "대기중")")
                .font(.caption)
                .foregroundColor(model.isDownloaded ? .green : .orange)
            Text("파일경로: \(model.filePath)")
                .font(.caption2)
                .foregroundColor(.gray)
            Text("생성시간: \(model.createdAt.formatted(date: .omitted, time: .shortened))")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    // 함수들에서도 날짜 포맷 수정
    private func addSampleDataWithDebug() {
        do {
            let currentTime = Date()
            let sampleData = ImageTestModel(
                characterType: "quokka",
                phaseType: "infant",
                animationType: "normal",
                frameIndex: Int.random(in: 1...10),
                filePath: "/test/path/quokka_infant_normal_\(Int.random(in: 1...10)).png",
                isDownloaded: Bool.random()
            )
            
            modelContext.insert(sampleData)
            try modelContext.save()
            
            // 날짜 포맷 수정
            debugMessage = "데이터 저장 성공! 시간: \(currentTime.formatted(date: .omitted, time: .shortened))"
            print("✅ SwiftData 저장 성공: \(sampleData.characterType)")
            
        } catch {
            debugMessage = "저장 실패: \(error.localizedDescription)"
            print("❌ SwiftData 저장 실패: \(error)")
        }
    }
    
    // 새로 추가: 수동으로 데이터 로드하는 함수
    // 기존 loadDataFromSwiftData 함수를 더 강화
    private func loadDataFromSwiftData() {
        print("🔄 수동 로드 시작...")
        debugModelContext() // 디버깅 함수 호출
        
        do {
            let descriptor = FetchDescriptor<ImageTestModel>()
            let fetchedData = try modelContext.fetch(descriptor)
            
            loadedData = fetchedData
            isDataLoaded = true
            
            debugMessage = "수동 로드 성공! \(fetchedData.count)개 데이터"
            print("🔄 SwiftData 수동 로드 성공: \(fetchedData.count)개")
            
            for (index, data) in fetchedData.enumerated() {
                print("  [\(index+1)] \(data.characterType) - \(data.phaseType) - 생성: \(data.createdAt)")
            }
            
        } catch {
            debugMessage = "로드 실패: \(error.localizedDescription)"
            print("❌ SwiftData 로드 실패: \(error)")
        }
    }
    
    // 나머지 함수들은 수정 필요 없음
    private func refreshData() {
        debugMessage = "새로고침 완료. 총 \(imageModels.count)개 데이터"
        print("🔄 데이터 새로고침: \(imageModels.count)개")
        
        // 수동 로드 데이터도 새로고침
        if isDataLoaded {
            loadDataFromSwiftData()
        }
    }
    
    private func deleteAllDataWithDebug() {
        do {
            let deleteCount = imageModels.count
            for model in imageModels {
                modelContext.delete(model)
            }
            try modelContext.save()
            
            // 수동 로드 데이터도 초기화
            loadedData.removeAll()
            isDataLoaded = false
            
            debugMessage = "\(deleteCount)개 데이터 삭제 완료"
            print("🗑️ 데이터 삭제 완료: \(deleteCount)개")
        } catch {
            debugMessage = "삭제 실패: \(error.localizedDescription)"
            print("❌ 데이터 삭제 실패: \(error)")
        }
    }
    
    // 새로운 디버깅 함수 추가
    private func debugModelContext() {
        do {
            // 현재 ModelContext 상태 확인
            print("🔍 ModelContext 디버깅 시작")
            print("   - ModelContext 존재: \(modelContext != nil)")
            
            // 다른 방법으로 데이터 가져오기 시도
            let allModels = try modelContext.fetch(FetchDescriptor<ImageTestModel>())
            print("   - 전체 데이터 개수: \(allModels.count)")
            
            // 저장된 모든 모델 타입 확인
            let descriptor = FetchDescriptor<ImageTestModel>()
            let results = try modelContext.fetch(descriptor)
            
            print("   - FetchDescriptor 결과: \(results.count)개")
            
            if results.isEmpty {
                print("   ⚠️ 데이터가 실제로 저장되지 않았거나 다른 컨테이너에 저장됨")
            } else {
                for (index, result) in results.enumerated() {
                    print("   [\(index+1)] \(result.characterType) - \(result.createdAt)")
                }
            }
            
            debugMessage = "디버깅 완료 - 자세한 내용은 콘솔 확인"
            
        } catch {
            print("❌ ModelContext 디버깅 실패: \(error)")
            debugMessage = "디버깅 실패: \(error.localizedDescription)"
        }
    }
}

#Preview {
    SwiftDataTestView()
        .modelContainer(for: ImageTestModel.self, inMemory: true)
}
