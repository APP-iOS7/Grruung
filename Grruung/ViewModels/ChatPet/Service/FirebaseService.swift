//
//  FirebaseService.swift
//  Grruung
//
//  Created by KimJunsoo on 5/7/25.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseDatabase

// Firebase 관련 작업을 처리하는 서비스 클래스
class FirebaseService {
    static let shared = FirebaseService()
    
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    private init() {}
    
    // 현재 로그인된 사용자의 UID를 반환
    func getCurrentUserID() -> String? {
        return auth.currentUser?.uid
    }
    
    // MARK: - 캐릭터 관련 메서드
    // Firestore에서 사용자의 모든 캐릭터 목록을 가져옴
    func fetchUserCharacters(completion: @escaping ([GRCharacter]?, Error?) -> Void) {
        guard let userID = getCurrentUserID() else {
            completion(nil, NSError(domain: "FirebaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "사용자 인증이 필요합니다."]))
            return
        }
        
        db.collection("users").document(userID).collection("characters")
            .getDocuments { (snapshot, error) in
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion([], nil)
                    return
                }
                
                var characters: [GRCharacter] = []
                
                for document in documents {
                    let data = document.data()
                    
                    let id = document.documentID
                    let speciesRaw = data["species"] as? String ?? ""
                    let species = PetSpecies(rawValue: speciesRaw) ?? .CatLion
                    let name = data["name"] as? String ?? "이름 없음"
                    let imageName = data["image"] as? String ?? ""
                    
                    // 상태 정보 파싱
                    let statusData = data["status"] as? [String: Any] ?? [:]
                    let level = statusData["level"] as? Int ?? 1
                    let exp = statusData["exp"] as? Int ?? 0
                    let expToNextLevel = statusData["expToNextLevel"] as? Int ?? 100
                    let phaseRaw = statusData["phase"] as? String ?? ""
                    let phase = CharacterPhase(rawValue: phaseRaw) ?? .infant
                    let satiety = statusData["satiety"] as? Int ?? 50
                    let stamina = statusData["stamina"] as? Int ?? 50
                    let activity = statusData["activity"] as? Int ?? 50
                    let affection = statusData["affection"] as? Int ?? 50
                    let healthy = statusData["healthy"] as? Int ?? 50
                    let clean = statusData["clean"] as? Int ?? 50
                    let address = statusData["address"] as? String ?? "usersHome"
                    let birthDateTimestamp = statusData["birthDate"] as? Timestamp
                    let birthDate = birthDateTimestamp?.dateValue() ?? Date()
                    let appearance = statusData["appearance"] as? [String: String] ?? [:]
                    
                    let status = GRCharacterStatus(
                        level: level,
                        exp: exp,
                        expToNextLevel: expToNextLevel,
                        phase: phase,
                        satiety: satiety,
                        stamina: stamina,
                        activity: activity,
                        affection: affection,
                        healthy: healthy,
                        clean: clean,
                        address: address,
                        birthDate: birthDate,
                        appearance: appearance
                    )
                    
                    let character = GRCharacter(
                        id: id,
                        species: species,
                        name: name,
                        imageName: imageName,
                        birthDate: birthDate,
                        status: status
                    )
                    
                    characters.append(character)
                }
                
                completion(characters, nil)
            }
    }
    
    func saveCharacter(_ character: GRCharacter, completion: @escaping (Error?) -> Void) {
        guard let userID = getCurrentUserID() else {
            completion(NSError(domain: "FirebaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "사용자 인증이 필요합니다."]))
            return
        }
        
        // 캐릭터 상태 정보를 딕셔너리로 변환
        let statusData: [String: Any] = [
            "level": character.status.level,
            "exp": character.status.exp,
            "expToNextLevel": character.status.expToNextLevel,
            "phase": character.status.phase.rawValue,
            "satiety": character.status.satiety,
            "stamina": character.status.stamina,
            "activity": character.status.activity,
            "affection": character.status.affection,
            "healthy": character.status.healthy,
            "clean": character.status.clean,
            "address": character.status.address,
            "birthDate": Timestamp(date: character.status.birthDate),
            "appearance": character.status.appearance,
        ]
        
        // 캐릭터 정보를 딕셔너리로 변환
        let characterData: [String: Any] = [
            "species": character.species.rawValue,
            "name": character.name,
            "image": character.imageName,
            "status": statusData,
            "updatedAt": Timestamp(date: Date()),
        ]
        
        // Firestore에 저장
        db.collection("users").document(userID).collection("characters").document(character.id)
            .setData(characterData, merge: true) { error in
                completion(error)
            }
    }
    
    // 캐릭터를 Firestore에서 삭제합니다.
    func deleteCharacter(id: String, completion: @escaping (Error?) -> Void) {
        guard let userID = getCurrentUserID() else {
            completion(NSError(domain: "FirebaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "사용자 인증이 필요합니다."]))
            return
        }
        
        db.collection("users").document(userID).collection("characters").document(id).delete { error in
            completion(error)
        }
    }
    
    // MARK: - 채팅 메시지 관련 메서드
    // Firestore에 채팅 메시지를 저장
    func saveChatMessage(_ message: ChatMessage, characterID: String, completion: @escaping (Error?) -> Void) {
        guard let userID = getCurrentUserID() else {
            completion(NSError(domain: "FirebaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "사용자 인증이 필요합니다."]))
            return
        }
        
        let messageData: [String: Any] = [
            "text": message.text,
            "isFromPet": message.isFromPet,
            "timestamp": Timestamp(date: message.timestamp)
        ]
        
        db.collection("users").document(userID)
            .collection("characters").document(characterID)
            .collection("messages").document(message.id)
            .setData(messageData) { error in
                completion(error)
            }
    }
    
    // Firestore에서 특정 캐릭터와의 채팅 메시지를 가져옴.
    func fetchChatMessages(characterID: String, limit: Int = 50, completion: @escaping ([ChatMessage]?, Error?) -> Void) {
        guard let userID = getCurrentUserID() else {
            completion(nil, NSError(domain: "FirebaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "사용자 인증이 필요합니다."]))
            return
        }
        
        db.collection("users").document(userID)
            .collection("characters").document(characterID)
            .collection("messages")
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion([], nil)
                    return
                }
                
                var messages: [ChatMessage] = []
                
                for document in documents {
                    let data = document.data()
                    
                    let text = data["text"] as? String ?? ""
                    let isFromPet = data["isFromPet"] as? Bool ?? false
                    let timestampData = data["timestamp"] as? Timestamp
                    let timestamp = timestampData?.dateValue() ?? Date()
                    
                    let message = ChatMessage(text: text, isFromPet: isFromPet, timestamp: timestamp)
                    messages.append(message)
                }
                
                // 시간순으로 정렬
                messages.sort { $0.timestamp < $1.timestamp }
                
                completion(messages, nil)
            }
    }
    
    // MARK: - 대화 세션 관리
    
    // 새로운 대화 세션을 생성
    func createConversationSession(
        characterID: String,
        sessionName: String? = nil,
        completion: @escaping (String?, Error?) -> Void
    ) {
        guard let userID = getCurrentUserID() else {
            completion(nil, NSError(domain: "FirebaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "사용자 인증이 필요합니다."]))
            return
        }
        
        // 세션 이름 생성 (제공되지 않은 경우 시간 기반으로 생성)
        let name = sessionName ?? "\(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)) 대화"
        
        let sessionData: [String: Any] = [
            "startTime": Timestamp(date: Date()),
            "sessionName": name,
            "messageCount": 0,
            "active": true
        ]
        
        // Firestore에 세션 생성
        let sessionRef = db.collection("users").document(userID)
            .collection("characters").document(characterID)
            .collection("conversations").document("sessions")
            .collection("data").document()
        
        sessionRef.setData(sessionData) { error in
            if let error = error {
                completion(nil, error)
            } else {
                completion(sessionRef.documentID, nil)
            }
        }
    }
    
    // 대화 세션을 종료
    func endConversationSession(
        sessionID: String,
        characterID: String,
        summary: String? = nil,
        completion: @escaping (Error?) -> Void
    ) {
        guard let userID = getCurrentUserID() else {
            completion(NSError(domain: "FirebaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "사용자 인증이 필요합니다."]))
            return
        }
        
        // 세션 업데이트 데이터
        var updateData: [String: Any] = [
            "endTime": Timestamp(date: Date()),
            "active": false
        ]
        
        // 요약이 제공된 경우 추가
        if let summary = summary {
            updateData["summary"] = summary
        }
        
        // Firestore 업데이트
        db.collection("users").document(userID)
            .collection("characters").document(characterID)
            .collection("conversations").document("sessions")
            .collection("data").document(sessionID)
            .updateData(updateData) { error in
                completion(error)
            }
    }
    
    // 활성 대화 세션 불러오기. 없으면 새로 생성
    func getOrCreateActiveSession(
        characterID: String,
        completion: @escaping (String?, Error?) -> Void
    ) {
        guard let userID = getCurrentUserID() else {
            completion(nil, NSError(domain: "FirebaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "사용자 인증이 필요합니다."]))
            return
        }
        
        // 활성 세션 쿼리
        db.collection("users").document(userID)
            .collection("characters").document(characterID)
            .collection("conversations").document("sessions")
            .collection("data")
            .whereField("active", isEqualTo: true)
            .getDocuments { [weak self] (snapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                // 활성 세션이 있는 경우
                if let document = snapshot?.documents.first {
                    completion(document.documentID, nil)
                    return
                }
                
                // 활성 세션이 없는 경우 새로 생성
                self.createConversationSession(characterID: characterID) { sessionID, error in
                    completion(sessionID, error)
                }
            }
    }
    
    // MARK: - 대화 메시지 관리
    
    // 메시지를 현재 활성 세션에 저장
    /// - Parameters:
    ///   - message: 대화 메시지
    ///   - characterID: 캐릭터 ID
    ///   - sessionID: 세션 ID (옵션, 제공되지 않으면 활성 세션 사용)
    ///   - petStatus: 펫 상태 요약 (옵션)
    ///   - completion: 완료 콜백
    func saveChatMessageWithSession(
        _ message: ChatMessage,
        characterID: String,
        sessionID: String? = nil,
        petStatus: [String: Any]? = nil,
        completion: @escaping (Error?) -> Void
    ) {
        // 세션 ID가 없으면 활성 세션 가져오기
        if let sessionID = sessionID {
            saveChatMessageToSession(message, characterID: characterID, sessionID: sessionID, petStatus: petStatus, completion: completion)
        } else {
            getOrCreateActiveSession(characterID: characterID) { [weak self] (sessionID, error) in
                guard let self = self else { return }
                
                if let error = error {
                    completion(error)
                    return
                }
                
                if let sessionID = sessionID {
                    self.saveChatMessageToSession(message, characterID: characterID, sessionID: sessionID, petStatus: petStatus, completion: completion)
                } else {
                    completion(NSError(domain: "FirebaseService", code: 500, userInfo: [NSLocalizedDescriptionKey: "세션을 생성할 수 없습니다."]))
                }
            }
        }
    }
    
    // 특정 세션에 메시지를 저장합니다.
    private func saveChatMessageToSession(
        _ message: ChatMessage,
        characterID: String,
        sessionID: String,
        petStatus: [String: Any]? = nil,
        completion: @escaping (Error?) -> Void
    ) {
        guard let userID = getCurrentUserID() else {
            completion(NSError(domain: "FirebaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "사용자 인증이 필요합니다."]))
            return
        }
        
        // 메시지 데이터 준비
        var messageData: [String: Any] = [
            "text": message.text,
            "isFromPet": message.isFromPet,
            "timestamp": Timestamp(date: message.timestamp),
            "sessionID": sessionID,
            "readByUser": !message.isFromPet
        ]
        
        // 펫 상태가 제공된 경우 추가
        if let petStatus = petStatus {
            messageData["petStatus"] = petStatus
        }
        
        // 트랜잭션으로 메시지 저장 및 세션 메시지 카운트 업데이트
        let batch = db.batch()
        
        // 1. 메시지 저장
        let messageRef = db.collection("users").document(userID)
            .collection("characters").document(characterID)
            .collection("conversations").document("messages")
            .collection("data").document(message.id)
        
        batch.setData(messageData, forDocument: messageRef)
        
        // 2. 세션 메시지 카운트 업데이트
        let sessionRef = db.collection("users").document(userID)
            .collection("characters").document(characterID)
            .collection("conversations").document("sessions")
            .collection("data").document(sessionID)
        
        batch.updateData(["messageCount": FieldValue.increment(Int64(1))], forDocument: sessionRef)
        
        // 3. 첫 메시지인 경우 fireMessageID 업데이트
        // 4. 마지막 메시지 ID 업데이트
        sessionRef.getDocument { [weak self] snapshot, error in
            guard let self = self, let snapshot = snapshot, snapshot.exists else {
                completion(error ?? NSError(domain: "FirebaseService", code: 404, userInfo: [NSLocalizedDescriptionKey: "세션을 찾을 수 없습니다."]))
                return
            }
            
            let data = snapshot.data() ?? [:]
            
            // 첫 메시지 ID 설정 (Empty일 경우)
            if data["firstMessageID"] == nil {
                batch.updateData(["firstMessageID": message.id], forDocument: sessionRef)
            }
            
            // 마지막 메시지 ID 업데이트
            batch.updateData(["lastMessageID": message.id], forDocument: sessionRef)
            
            // 트랜잭션 커밋
            batch.commit { error in
                completion(error)
                
                // 중요 메시지인 경우 기억으로 저장
                // 현재 20자 이상일 경우 중요 메시지로 기억되게 함
                if error == nil && message.isFromPet && message.text.count >= 20 {
                    self.storeMessageAsMemory(message: message, characterID: characterID)
                }
            }
        }
    }
    
    // 메시지를 기억으로 저장
    private func storeMessageAsMemory(
        message: ChatMessage,
        characterID: String,
        importance: Int = 5
    ) {
        guard let userID = getCurrentUserID() else { return }
        
        // 중요 대화 기억으로 저장
        let memoryData: [String: Any] = [
            "content": message.text,          // 기억의 내용 (메시지 텍스트)
            "timestamp": Timestamp(date: message.timestamp),  // 기억이 생성된 시간
            "importance": importance,         // 기억의 중요도 점수
            "emotionalContext": "대화",       // 기억과 연관된 감정적 맥락
            "category": "대화",               // 기억의 카테고리
            "mentionCount": 1,                // 이 기억이 언급된 횟수
            "messageID": message.id           // 원본 메시지 ID
        ]
        
        let memoryRef = db.collection("users").document(userID)
            .collection("characters").document(characterID)
            .collection("memories").document("important")
            .collection("data").document()
        
        memoryRef.setData(memoryData) { _ in
            // 저장 완료 (오류 무시)
        }
    }
    
    // MARK: - 대화 히스토리 조회
    
    // 특정 세션의 대화 메시지를 가져옴
    /// - Parameters:
    ///   - sessionID: 세션 ID
    ///   - characterID: 캐릭터 ID
    ///   - limit: 최대 메시지 수
    ///   - completion: 완료 콜백
    func fetchMessagesFromSession(
        sessionID: String,
        characterID: String,
        limit: Int = 50,
        completion: @escaping ([ChatMessage]?, Error?) -> Void
    ) {
        guard let userID = getCurrentUserID() else {
            completion(nil, NSError(domain: "FirebaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "사용자 인증이 필요합니다."]))
            return
        }
        
        db.collection("users").document(userID)
            .collection("characters").document(characterID)
            .collection("conversations").document("messages")
            .collection("data")
            .whereField("sessionID", isEqualTo: sessionID)
            .order(by: "timestamp", descending: false) // 시간순 정렬
            .limit(to: limit)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion([], nil)
                    return
                }
                
                let messages = documents.compactMap { document -> ChatMessage? in
                    let data = document.data()
                    
                    let text = data["text"] as? String ?? ""
                    let isFromPet = data["isFromPet"] as? Bool ?? false
                    let timestampData = data["timestamp"] as? Timestamp
                    let timestamp = timestampData?.dateValue() ?? Date()
                    
                    return ChatMessage(
                        text: text,
                        isFromPet: isFromPet,
                        timestamp: timestamp
                    )
                }
                
                completion(messages, nil)
            }
    }
    
    // 최근 N개의 대화 세션에서 메시지를 조회
    /// - Parameters:
    ///   - characterID: 캐릭터 ID
    ///   - sessionCount: 조회할 세션 수
    ///   - messagesPerSession: 세션당 메시지 수
    ///   - completion: 완료 콜백
    func fetchRecentConversations(
        characterID: String,
        sessionCount: Int = 3,
        messagesPerSession: Int = 20,
        completion: @escaping ([[ChatMessage]]?, Error?) -> Void
    ) {
        guard let userID = getCurrentUserID() else {
            completion(nil, NSError(domain: "FirebaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "사용자 인증이 필요합니다."]))
            return
        }
        
        // 최근 세션 조회
        db.collection("users").document(userID)
            .collection("characters").document(characterID)
            .collection("conversations").document("sessions")
            .collection("data")
            .order(by: "startTime", descending: true)
            .limit(to: sessionCount)
            .getDocuments { [weak self] (snapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    completion([], nil)
                    return
                }
                
                // 각 세션에서 메시지 조회
                var allSessionMessages: [[ChatMessage]] = []
                let group = DispatchGroup()
                
                for document in documents {
                    group.enter()
                    
                    let sessionID = document.documentID
                    self.fetchMessagesFromSession(
                        sessionID: sessionID,
                        characterID: characterID,
                        limit: messagesPerSession
                    ) { messages, error in
                        defer { group.leave() }
                        
                        if let messages = messages, !messages.isEmpty {
                            allSessionMessages.append(messages)
                        }
                    }
                }
                
                group.notify(queue: .main) {
                    completion(allSessionMessages, nil)
                }
            }
    }
    
    // MARK: - 중요 기억 관리
    
    // 중요 기억을 조회합니다.
    /// - Parameters:
    ///   - characterID: 캐릭터 ID
    ///   - limit: 최대 기억 수
    ///   - completion: 완료 콜백
    func fetchImportantMemories(
        characterID: String,
        limit: Int = 20,
        completion: @escaping ([[String: Any]]?, Error?) -> Void
    ) {
        guard let userID = getCurrentUserID() else {
            completion(nil, NSError(domain: "FirebaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "사용자 인증이 필요합니다."]))
            return
        }
        
        db.collection("users").document(userID)
            .collection("characters").document(characterID)
            .collection("memories").document("important")
            .collection("data")
            .order(by: "importance", descending: true)
            .limit(to: limit)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion([], nil)
                    return
                }
                
                let memories = documents.map { $0.data() }
                completion(memories, nil)
            }
    }
    
    // 새로운 중요 기억을 저장합니다.
    /// - Parameters:
    ///   - memory: 기억 데이터
    ///   - characterID: 캐릭터 ID
    ///   - completion: 완료 콜백
    func storeImportantMemory(
        memory: [String: Any],
        characterID: String,
        completion: @escaping (Error?) -> Void
    ) {
        guard let userID = getCurrentUserID() else {
            completion(NSError(domain: "FirebaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "사용자 인증이 필요합니다."]))
            return
        }
        
        // 메모리에 타임스탬프 추가
        var memoryData = memory
        if memoryData["timestamp"] == nil {
            memoryData["timestamp"] = Timestamp(date: Date())
        }
        
        db.collection("users").document(userID)
            .collection("characters").document(characterID)
            .collection("memories").document("important")
            .collection("data").document()
    }
}
