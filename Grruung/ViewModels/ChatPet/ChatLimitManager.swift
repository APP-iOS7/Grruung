//
//  ChatLimitManager.swift
//  Grruung
//
//  Created by KimJunsoo on 6/11/25.
//

import Foundation

// 채팅 제한 관리 클래스
class ChatLimitManager {
    static let shared = ChatLimitManager()
    
    // UserDefaults 키
    private enum UserDefaultsKeys {
        static let chatCountKey = "daily_chat_count"
        static let lastResetDateKey = "last_reset_date"
    }
    
    // 최대 무료 채팅 횟수
    let maxFreeChatCount = 3
    
    private init() {
        // 일일 초기화 확인
        checkAndResetDailyCount()
    }
    
    // 오늘 남은 채팅 횟수를 반환
    func getRemainingChats() -> Int {
        let usedCount = UserDefaults.standard.integer(forKey: UserDefaultsKeys.chatCountKey)
        return max(0, maxFreeChatCount - usedCount)
    }
    
    // 채팅 횟수 사용
    func useChat() -> Bool {
        checkAndResetDailyCount()
        
        let currentCount = UserDefaults.standard.integer(forKey: UserDefaultsKeys.chatCountKey)
        
        // 무료 채팅 횟수를 모두 사용한 경우
        if currentCount >= maxFreeChatCount {
            return false
        }
        
        // 카운트 증가
        UserDefaults.standard.set(currentCount + 1, forKey: UserDefaultsKeys.chatCountKey)
        return true
    }
    
    // 채팅 티켓 사용 (추가 채팅 티켓)
    func useChatTicket() -> Bool {
        // TODO: 실제 구매한 티켓이 있는지 확인하는 로직 필요
        // 임시로 true 반환 (티켓이 있다고 가정)
        return true
    }
    
    // 날짜 변경 시 카운트 초기화
    private func checkAndResetDailyCount() {
        let calendar = Calendar.current
        let now = Date()
        
        // 마지막 초기화 날짜 가져오기
        if let lastResetDateData = UserDefaults.standard.object(forKey: UserDefaultsKeys.lastResetDateKey) as? Date {
            // 날짜가 변경되었는지 확인
            if !calendar.isDate(lastResetDateData, inSameDayAs: now) {
                // 날짜가 변경되었으면 초기화
                UserDefaults.standard.set(0, forKey: UserDefaultsKeys.chatCountKey)
                UserDefaults.standard.set(now, forKey: UserDefaultsKeys.lastResetDateKey)
            }
        } else {
            // 최초 사용 시 설정
            UserDefaults.standard.set(now, forKey: UserDefaultsKeys.lastResetDateKey)
            UserDefaults.standard.set(0, forKey: UserDefaultsKeys.chatCountKey)
        }
    }
}
