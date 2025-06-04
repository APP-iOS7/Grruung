//
//  WritingCountViewModel.swift
//  Grruung
//
//  Created by NO SEONGGYEONG on 5/27/25.
//

import Foundation
import FirebaseFirestore

@MainActor
class WritingCountViewModel: ObservableObject {
    @Published var userWritingCount: WritingCount?
    private var db = Firestore.firestore()
    
    init() {
    }
    
    // authService를 받아서 초기화하는 메서드
    func initialize(with authService: AuthService) {
        guard let userID = authService.user?.uid else { return }
        self.userWritingCount = WritingCount(id: userID)
        loadWritingCount(userID: userID)
    }
    
    func loadWritingCount(userID: String) {
        db.collection("WritingCounts").document(userID).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let data = snapshot?.data() {
                let writingCount = WritingCount(
                    id: userID,
                    dailyCount: data["dailyCount"] as? Int ?? 3,
                    additionalCount: data["additionalCount"] as? Int ?? 0,
                    lastResetDate: (data["lastResetDate"] as? Timestamp)?.dateValue() ?? Date()
                )
                
                Task { @MainActor in
                    self.userWritingCount = writingCount
                    self.userWritingCount?.checkAndResetDaily()
                    self.updateWritingCountInFirestore()
                }
            } else {
                Task { @MainActor in
                    self.updateWritingCountInFirestore()
                }
            }
        }
    }
    
    func tryToWrite() -> Bool {
        guard var writingCount = userWritingCount else { return false }
        if writingCount.tryWrite() {
            self.userWritingCount = writingCount
            updateWritingCountInFirestore()
            return true
        }
        return false
    }
    
    func addPurchasedCount(count: Int = 1) {
        userWritingCount?.addPurchasedCount(count: count)
        updateWritingCountInFirestore()
    }
    
    private func updateWritingCountInFirestore() {
        guard let writingCount = userWritingCount else { return }
        db.collection("WritingCounts").document(writingCount.id).setData(
            writingCount.toFirestoreData(),
            merge: true
        ) { error in
            if let error = error {
                print("글쓰기 카운트 업데이트 실패: \(error)")
            }
        }
    }
}
