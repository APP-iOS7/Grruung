//
//  WritingCount.swift
//  Grruung
//
//  Created by NO SEONGGYEONG on 5/27/25.
//

import Foundation
import FirebaseFirestore

struct WritingCount: Identifiable {
    var id: String // GRUser의 ID
    var dailyCount: Int // 현재 남은 일일 기본 횟수 (최대 3)
    var additionalCount: Int // 결제로 얻은 추가 횟수
    var lastResetDate: Date // 마지막으로 dailyCount가 리셋된 날짜
    
    // 총 사용 가능 횟수
    var totalAvailableCount: Int {
        return dailyCount + additionalCount
    }
    
    // 새로운 날이 시작되었는지 확인하고 필요하면 dailyCount 리셋
    mutating func checkAndResetDaily() {
        let calendar = Calendar.current
        if !calendar.isDate(lastResetDate, inSameDayAs: Date()) {
            dailyCount = 3 // 하루에 3번으로 리셋
            lastResetDate = Date()
        }
    }
    
    // 글쓰기 시도 (성공하면 true 반환)
    mutating func tryWrite() -> Bool {
        checkAndResetDaily() // 날짜가 바뀌었는지 확인
        
        if totalAvailableCount > 0 {
            // 우선 일일 카운트 사용, 없으면 추가 카운트 사용
            if dailyCount > 0 {
                dailyCount -= 1
            } else {
                additionalCount -= 1
            }
            return true
        }
        return false
    }
    
    // 결제를 통한 추가 횟수 충전
    mutating func addPurchasedCount(count: Int = 1) {
        additionalCount += count
    }
    
    // 초기화 메서드
    init(id: String, dailyCount: Int = 3, additionalCount: Int = 0, lastResetDate: Date = Date()) {
        self.id = id
        self.dailyCount = dailyCount
        self.additionalCount = additionalCount
        self.lastResetDate = lastResetDate
    }
    
    // Firestore에 저장할 Dictionary 변환
    func toFirestoreData() -> [String: Any] {
        return [
            "dailyCount": dailyCount,
            "additionalCount": additionalCount,
            "lastResetDate": Timestamp(date: lastResetDate)
        ]
    }
    
    // Firestore에서 불러오기
    static func fromFirestore(document: DocumentSnapshot) -> WritingCount? {
        guard let data = document.data() else { return nil }
        
        return WritingCount(
            id: document.documentID,
            dailyCount: data["dailyCount"] as? Int ?? 3,
            additionalCount: data["additionalCount"] as? Int ?? 0,
            lastResetDate: (data["lastResetDate"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}
