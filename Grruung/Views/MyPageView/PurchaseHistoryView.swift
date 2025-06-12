//
//  PurchaseHistoryView.swift
//  Grruung
//
//  Created by KimJunsoo on 6/12/25.
//

import SwiftUI
import FirebaseFirestore

// MARK: - 결제 기록 모델
struct PurchaseRecord: Identifiable {
    let id: String
    let itemName: String
    let itemImage: String
    let quantity: Int
    let price: Int
    let currencyType: ItemCurrencyType
    let purchaseDate: Date
    let isRealMoney: Bool
    
    init(id: String = UUID().uuidString,
         itemName: String,
         itemImage: String,
         quantity: Int,
         price: Int,
         currencyType: ItemCurrencyType,
         purchaseDate: Date,
         isRealMoney: Bool = true) {
        self.id = id
        self.itemName = itemName
        self.itemImage = itemImage
        self.quantity = quantity
        self.price = price
        self.currencyType = currencyType
        self.purchaseDate = purchaseDate
        self.isRealMoney = isRealMoney
    }
    
    // Firestore 데이터로부터 생성
    static func fromFirestore(id: String, data: [String: Any]) -> PurchaseRecord? {
        guard
            let itemName = data["itemName"] as? String,
            let itemImage = data["itemImage"] as? String,
            let quantity = data["quantity"] as? Int,
            let price = data["price"] as? Int,
            let currencyTypeRaw = data["currencyType"] as? String,
            let currencyType = ItemCurrencyType(rawValue: currencyTypeRaw),
            let timestamp = data["purchaseDate"] as? Timestamp,
            let isRealMoney = data["isRealMoney"] as? Bool
        else {
            return nil
        }
        
        return PurchaseRecord(
            id: id,
            itemName: itemName,
            itemImage: itemImage,
            quantity: quantity,
            price: price,
            currencyType: currencyType,
            purchaseDate: timestamp.dateValue(),
            isRealMoney: isRealMoney
        )
    }
}

// MARK: - 구매 내역 화면
struct PurchaseHistoryView: View {
    @EnvironmentObject private var userInventoryViewModel: UserInventoryViewModel
    @EnvironmentObject private var authService: AuthService
    @State private var isLoading = false
    @State private var purchaseRecords: [PurchaseRecord] = []
    @State private var selectedTab: PurchaseTab = .all
    
    enum PurchaseTab: String, CaseIterable {
        case all = "전체"
        case diamond = "다이아 구매"
        case petUnlock = "펫 해금"
    }
    
    private let db = Firestore.firestore()
    
    var body: some View {
        VStack(spacing: 0) {
            // 탭 선택 부분
            HStack(spacing: 10) {
                ForEach(PurchaseTab.allCases, id: \.self) { tab in
                    TabButton(
                        title: tab.rawValue,
                        isSelected: selectedTab == tab,
                        action: { selectedTab = tab }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider()
                .padding(.vertical, 5)
            
            // 로딩 및 내용 표시
            if isLoading {
                ProgressView("데이터를 불러오는 중...")
                    .padding()
                    .frame(maxHeight: .infinity)
            } else if filteredRecords.isEmpty {
                VStack {
                    Spacer()
                    Text("구매 내역이 없습니다")
                        .foregroundColor(.gray)
                    Spacer()
                }
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredRecords) { record in
                        PurchaseHistoryItem(record: record)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("결제 내역")
        .onAppear {
            loadData()
        }
        .refreshable {
            loadData()
        }
    }
    
    // MARK: - 내부 메서드
    
    // 필터링된 아이템
    private var filteredRecords: [PurchaseRecord] {
        switch selectedTab {
        case .all:
            return purchaseRecords
        case .diamond:
            return purchaseRecords.filter { $0.itemName.contains("다이아") }
        case .petUnlock:
            return purchaseRecords.filter { $0.itemName.contains("동산 잠금해제") }
        }
    }
    
    // 데이터 로드
    private func loadData() {
        isLoading = true
        purchaseRecords = []
        
        // 실제 유저 ID 또는 테스트 ID
        let userId = authService.currentUserUID.isEmpty ? "23456" : authService.currentUserUID
        print("🔄 결제 내역 로드 시작 - 사용자 ID: \(userId)")
        
        // 결제 기록 컬렉션 참조
        let purchaseRecordsRef = db.collection("users").document(userId).collection("purchaseRecords")
        
        // Firestore에서 구매 기록 가져오기
        purchaseRecordsRef.order(by: "purchaseDate", descending: true).getDocuments { snapshot, error in
            if let error = error {
                print("❌ 결제 기록 불러오기 실패: \(error.localizedDescription)")
                self.isLoading = false
                return
            }
            
            let documentCount = snapshot?.documents.count ?? 0
            print("📊 결제 기록 조회 결과 - 문서 수: \(documentCount)")
            
            // 문서가 있으면 기록 변환
            if let documents = snapshot?.documents, !documents.isEmpty {
                // 간단한 중복 제거 (동일한 문서 ID는 한 번만 처리)
                var processedIds = Set<String>()
                var records: [PurchaseRecord] = []
                
                for document in documents {
                    let id = document.documentID
                    
                    // 이미 처리한 ID면 건너뛰기
                    if processedIds.contains(id) {
                        continue
                    }
                    
                    processedIds.insert(id)
                    
                    if let record = PurchaseRecord.fromFirestore(id: id, data: document.data()) {
                        records.append(record)
                    }
                }
                
                // 날짜순 정렬
                let sortedRecords = records.sorted(by: { $0.purchaseDate > $1.purchaseDate })
                
                DispatchQueue.main.async {
                    self.purchaseRecords = sortedRecords
                    self.isLoading = false
                    print("✅ 최종 표시할 결제 기록 수: \(sortedRecords.count)")
                }
            } else {
                // 문서가 없으면 빈 배열 설정
                DispatchQueue.main.async {
                    self.purchaseRecords = []
                    self.isLoading = false
                    print("ℹ️ 결제 기록이 없습니다.")
                }
            }
        }
    }
}

// MARK: - 보조 뷰

// 탭 버튼
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .regular)
                .padding(.vertical, 8)
                .padding(.horizontal, 15)
                .foregroundColor(isSelected ? .white : .primary)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color(.systemGray6))
                )
        }
    }
}

// 구매 내역 항목
struct PurchaseHistoryItem: View {
    let record: PurchaseRecord
    
    var body: some View {
        HStack(spacing: 15) {
            // 아이템 이미지
            if record.itemImage.contains("diamond_") {
                Image(systemName: "diamond.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.cyan)
                    .padding(8)
                    .background(Color.cyan.opacity(0.2))
                    .cornerRadius(10)
            } else if record.itemImage.contains("charDex_unlock_ticket") {
                Image(systemName: "ticket.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.purple)
                    .padding(8)
                    .background(Color.purple.opacity(0.2))
                    .cornerRadius(10)
            } else {
                Image(systemName: "cart.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.blue)
                    .padding(8)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(10)
            }
            
            // 아이템 정보
            VStack(alignment: .leading, spacing: 5) {
                Text(record.itemName)
                    .fontWeight(.medium)
                
                HStack {
                    // 아이템 수량
                    Text("\(record.quantity)개")
                        .font(.footnote)
                        .foregroundColor(.black)
                        .padding(.vertical, 3)
                        .padding(.horizontal, 8)
                        .background(Color(.systemGray5))
                        .cornerRadius(5)
                    
                    Spacer()
                    
                    // 구매 날짜
                    Text(formattedDate(record.purchaseDate))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // 날짜 포매팅
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
}

