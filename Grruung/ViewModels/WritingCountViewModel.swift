//
//  WritingCountViewModel.swift
//  Grruung
//
//  Created by NO SEONGGYEONG on 5/27/25.
//

import Foundation
import FirebaseFirestore

class WritingCountViewModel: ObservableObject {
    @Published var userWritingCount: WritingCount
    private var db = Firestore.firestore()
    
    init(userID: String) {
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
                
                DispatchQueue.main.async {
                    self.userWritingCount = writingCount
                    self.userWritingCount.checkAndResetDaily()
                    self.updateWritingCountInFirestore()
                }
            } else {
                DispatchQueue.main.async {
                    self.updateWritingCountInFirestore()
                }
            }
        }
    }
    
    func tryToWrite() -> Bool {
        if userWritingCount.tryWrite() {
            updateWritingCountInFirestore()
            return true
        }
        return false
    }
    
    func addPurchasedCount(count: Int = 1) {
        userWritingCount.addPurchasedCount(count: count)
        updateWritingCountInFirestore()
    }
    
    private func updateWritingCountInFirestore() {
        db.collection("WritingCounts").document(userWritingCount.id).setData(
            userWritingCount.toFirestoreData(),
            merge: true
        ) { error in
            if let error = error {
                print("글쓰기 카운트 업데이트 실패: \(error)")
            }
        }
    }
}
