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
        static let chatTicketsKey = "chat_tickets_count" // 추가: 챗팅 티켓 수를 저장할 키
    }
    
    // 최대 무료 채팅 횟수
    let maxFreeChatCount = 3
    
    // 최대 티켓 보유 가능 수
    let maxTicketCount = 99
    
    private init() {
        // 일일 초기화 확인
        checkAndResetDailyCount()
    }
    
    // 오늘 남은 채팅 횟수를 반환
    func getRemainingChats() -> Int {
        let usedCount = UserDefaults.standard.integer(forKey: UserDefaultsKeys.chatCountKey)
        return max(0, maxFreeChatCount - usedCount)
    }
    
    // 보유한 채팅 티켓 수를 반환
    func getTicketCount() -> Int {
        return UserDefaults.standard.integer(forKey: UserDefaultsKeys.chatTicketsKey)
    }
    
    // 채팅 티켓 추가
    func addChatTickets(_ count: Int) -> Int {
        let currentTickets = getTicketCount()
        let newTicketCount = min(maxTicketCount, currentTickets + count)
        UserDefaults.standard.set(newTicketCount, forKey: UserDefaultsKeys.chatTicketsKey)
        return newTicketCount
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
    
    // 채팅 티켓 사용
    func useChatTicket() -> Bool {
        let ticketCount = getTicketCount()
        
        // 티켓이 없으면 사용 불가
        if ticketCount <= 0 {
            return false
        }
        
        // 티켓 차감
        UserDefaults.standard.set(ticketCount - 1, forKey: UserDefaultsKeys.chatTicketsKey)
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
