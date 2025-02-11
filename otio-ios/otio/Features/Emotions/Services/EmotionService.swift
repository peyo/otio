import FirebaseDatabase
import FirebaseAuth
import Foundation

class EmotionService {
    static func submitEmotion(type: String, userId: String) async throws {
        let ref = Database.database().reference()
        let emotionRef = ref.child("users").child(userId).child("emotions").childByAutoId()
        
        let data: [String: Any] = [
            "type": type,
            "timestamp": ServerValue.timestamp()
        ]
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            emotionRef.setValue(data) { error, _ in
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
        
        // Get reference for all emotions from the past week
        let weekAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        let timestamp = Int(weekAgo.timeIntervalSince1970 * 1000)
        
        let allEmotionsRef = ref.child("users").child(userId).child("emotions")
            .queryOrdered(byChild: "timestamp")
            .queryStarting(atValue: timestamp)
        
        // Get reference for most recent emotions
        let recentEmotionsRef = ref.child("users").child(userId).child("emotions")
            .queryOrdered(byChild: "timestamp")
            .queryLimited(toLast: 7)
        
        async let allEmotionsSnapshot = try await withCheckedThrowingContinuation { continuation in
            allEmotionsRef.observeSingleEvent(of: .value) { snapshot in
                continuation.resume(returning: snapshot)
            } withCancel: { error in
                continuation.resume(throwing: error)
            }
        }
        
        async let recentEmotionsSnapshot = try await withCheckedThrowingContinuation { continuation in
            recentEmotionsRef.observeSingleEvent(of: .value) { snapshot in
                continuation.resume(returning: snapshot)
            } withCancel: { error in
                continuation.resume(throwing: error)
            }
        }
        
        let (allSnapshot, recentSnapshot) = try await (allEmotionsSnapshot, recentEmotionsSnapshot)
        
        var allEmotions: [EmotionData] = []
        var recentEmotions: [EmotionData] = []
        
        // Process all emotions
        for child in allSnapshot.children {
            if let snapshot = child as? DataSnapshot,
               let dict = snapshot.value as? [String: Any],
               let type = dict["type"] as? String,
               let timestamp = dict["timestamp"] as? Double {
                
                let date = Date(timeIntervalSince1970: timestamp / 1000)
                let emotion = EmotionData(
                    id: snapshot.key,
                    type: type,
                    date: date  // Removed intensity
                )
                allEmotions.append(emotion)
            }
        }
        
        // Process recent emotions
        for child in recentSnapshot.children {
            if let snapshot = child as? DataSnapshot,
               let dict = snapshot.value as? [String: Any],
               let type = dict["type"] as? String,
               let timestamp = dict["timestamp"] as? Double {
                
                let date = Date(timeIntervalSince1970: timestamp / 1000)
                let emotion = EmotionData(
                    id: snapshot.key,
                    type: type,
                    date: date  // Removed intensity
                )
                recentEmotions.append(emotion)
            }
        }
        
        // Sort emotions by date (newest first)
        allEmotions.sort { (emotion1: EmotionData, emotion2: EmotionData) -> Bool in
            emotion1.date > emotion2.date
        }
        recentEmotions.sort { (emotion1: EmotionData, emotion2: EmotionData) -> Bool in
            emotion1.date > emotion2.date
        }
        
        return (allEmotions, recentEmotions)
    }
}