import FirebaseDatabase
import Foundation

class EmotionDatabaseService {
    static func submitEmotion(emotion: String, userId: String, log: String? = nil, energyLevel: Int? = nil) async throws {
        let ref = Database.database().reference()
        let emotionsRef = ref.child("users").child(userId).child("emotions")
        let newEmotionRef = emotionsRef.childByAutoId()
        
        guard let id = newEmotionRef.key else {
            throw NSError(domain: "EmotionService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to generate emotion ID"])
        }
        
        let emotionData = EmotionData(
            id: id,
            emotion: emotion,
            log: log,
            energyLevel: energyLevel
        )
        
        let dict = emotionData.toDictionary()
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            newEmotionRef.setValue(dict) { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    static func updateEmotion(id: String, userId: String, emotion: String, log: String? = nil, energyLevel: Int? = nil) async throws {
        let emotionRef = Database.database().reference()
            .child("users")
            .child(userId)
            .child("emotions")
            .child(id)
        
        var updates: [String: Any] = [
            "emotion": emotion,
            "updated_at": ServerValue.timestamp()
        ]
        
        if let log = log, !log.isEmpty {
            updates["log"] = log
        } else {
            updates["log"] = NSNull()
        }
        
        if let energyLevel = energyLevel {
            updates["energy_level"] = energyLevel
        } else {
            updates["energy_level"] = NSNull()
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            emotionRef.updateChildValues(updates) { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    static func deleteEmotion(emotionId: String, userId: String) async throws {
        let ref = Database.database().reference()
            .child("users")
            .child(userId)
            .child("emotions")
            .child(emotionId)
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ref.removeValue { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    static func fetchEmotions(userId: String) async throws -> (all: [EmotionData], recent: [EmotionData]) {
        let ref = Database.database().reference()
        
        // Get reference for all emotions from the past week using indexed query
        let weekAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        let weekAgoTimestamp = Int(weekAgo.addingTimeInterval(-3600).timeIntervalSince1970 * 1000)
        
        let allEmotionsRef = ref.child("users").child(userId).child("emotions")
            .queryOrdered(byChild: "timestamp")
            .queryStarting(atValue: weekAgoTimestamp)
        
        let recentEmotionsRef = ref.child("users").child(userId).child("emotions")
            .queryOrdered(byChild: "timestamp")
            .queryLimited(toLast: 7)
        
        async let allEmotionsSnapshot = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<DataSnapshot, Error>) in
            allEmotionsRef.observeSingleEvent(of: .value) { snapshot in
                continuation.resume(returning: snapshot)
            } withCancel: { error in
                continuation.resume(throwing: error)
            }
        }
        
        async let recentEmotionsSnapshot = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<DataSnapshot, Error>) in
            recentEmotionsRef.observeSingleEvent(of: .value) { snapshot in
                continuation.resume(returning: snapshot)
            } withCancel: { error in
                continuation.resume(throwing: error)
            }
        }
        
        let (allSnapshot, recentSnapshot) = try await (allEmotionsSnapshot, recentEmotionsSnapshot)
        
        return try processSnapshots(allSnapshot: allSnapshot, recentSnapshot: recentSnapshot, weekAgo: weekAgo)
    }
    
    private static func processSnapshots(allSnapshot: DataSnapshot, recentSnapshot: DataSnapshot, weekAgo: Date) throws -> (all: [EmotionData], recent: [EmotionData]) {
        let allEmotions: [EmotionData] = allSnapshot.children.compactMap { child in
            if let snapshot = child as? DataSnapshot,
               let dict = snapshot.value as? [String: Any] {
                do {
                    let emotion = try EmotionValidationService().validateEmotionData(dict, id: snapshot.key)
                    if emotion.date >= weekAgo {
                        return emotion
                    }
                } catch {
                    print("Error validating emotion data:", error)
                }
            }
            return nil
        }
        
        let recentEmotions: [EmotionData] = recentSnapshot.children.compactMap { child in
            if let snapshot = child as? DataSnapshot,
               let dict = snapshot.value as? [String: Any] {
                do {
                    let emotion = try EmotionValidationService().validateEmotionData(dict, id: snapshot.key)
                    return emotion
                } catch {
                    print("Error validating emotion data:", error)
                }
            }
            return nil
        }
        
        let sortedAllEmotions = allEmotions.sorted { $0.date > $1.date }
        let sortedRecentEmotions = recentEmotions.sorted { $0.date > $1.date }
        
        return (
            sortedAllEmotions,
            sortedRecentEmotions.count > 7 ? Array(sortedRecentEmotions.prefix(7)) : sortedRecentEmotions
        )
    }
    
    // Fetch emotions for a specific date range
    static func fetchEmotionsForDateRange(userId: String, startDate: Date, endDate: Date) async throws -> [EmotionData] {
        let database = Database.database().reference()
        let emotionsRef = database.child("users").child(userId).child("emotions")
        
        // Convert dates to timestamps for query
        let startTimestamp = Int(startDate.timeIntervalSince1970 * 1000)  // Convert to milliseconds
        let endTimestamp = Int(endDate.timeIntervalSince1970 * 1000)      // Convert to milliseconds
        
        // Query emotions within the date range
        let snapshot = try await emotionsRef
            .queryOrdered(byChild: "timestamp")
            .queryStarting(atValue: startTimestamp)
            .queryEnding(beforeValue: endTimestamp)
            .getData()
        
        guard let emotionsDict = snapshot.value as? [String: [String: Any]] else {
            return []
        }
        
        return emotionsDict.compactMap { id, data in
            guard let emotion = data["emotion"] as? String,
                  let timestamp = data["timestamp"] as? TimeInterval
            else { return nil }
            
            let date = Date(timeIntervalSince1970: timestamp / 1000)  // Convert from milliseconds
            let log = data["log"] as? String
            let energyLevel = data["energy_level"] as? Int
            
            return EmotionData(id: id, emotion: emotion, date: date, log: log, energyLevel: energyLevel)
        }.sorted { $0.date > $1.date }
    }
} 