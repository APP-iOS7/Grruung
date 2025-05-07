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
                    let species = PetSpecies(rawValue: speciesRaw) ?? .ligerCat
                    let name = data["name"] as? String ?? "이름 없음"
                    let image = data["image"] as? String ?? ""
                    
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
                        image: image,
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
            "image": character.image,
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
        
        db.collection("usres").document(userID)
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
}
