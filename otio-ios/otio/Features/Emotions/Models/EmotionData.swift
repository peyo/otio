import Foundation
import FirebaseDatabase

struct EmotionData: Identifiable, Hashable, Codable {
    let id: String
    let emotion: String  // Changed from type
    let date: Date  // We'll keep the property name as "date" for code clarity
    let log: String?  // Optional text field for user notes (renamed from text)
    let energyLevel: Int?  // Optional energy level (1-5 scale)
    let updatedAt: Date?  // New field
    
    enum CodingKeys: String, CodingKey {
        case id
        case emotion = "emotion"  // Keep Firebase key as "type" or change to "emotion"?
        case date = "timestamp"  // Map to "timestamp" in JSON
        case log  // Now maps to "log" in Firebase
        case energyLevel = "energy_level"
        case updatedAt
    }
    
    init(id: String, 
         emotion: String,
         date: Date = Date(),
         log: String? = nil,
         energyLevel: Int? = nil,
         updatedAt: Date? = nil) {
        self.id = id
        self.emotion = emotion  // Changed from type
        self.date = date
        self.log = log
        self.energyLevel = energyLevel
        self.updatedAt = updatedAt
    }
    
    // Helper to convert to dictionary for Firebase
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "emotion": emotion,
            "timestamp": date.timeIntervalSince1970 * 1000
        ]
        
        if let log = log, !log.isEmpty {
            dict["log"] = log
        }
        
        if let energyLevel = energyLevel {
            dict["energy_level"] = energyLevel
        }
        
        if let updatedAt = updatedAt {
            dict["updated_at"] = updatedAt.timeIntervalSince1970 * 1000
        }
        
        return dict
    }
    
    // Helper to create from Firebase snapshot
    static func fromSnapshot(_ snapshot: DataSnapshot) -> EmotionData? {
        guard let dict = snapshot.value as? [String: Any],
              let emotion = dict["emotion"] as? String,  // Changed from "type"
              let timestamp = dict["timestamp"] as? Double else {
            return nil
        }
        
        let log = dict["log"] as? String
        let energyLevel = dict["energy_level"] as? Int
        let updatedAt = dict["updated_at"] as? Double
        
        return EmotionData(
            id: snapshot.key,
            emotion: emotion,  // This was already correct since we're passing to the constructor
            date: Date(timeIntervalSince1970: timestamp / 1000),
            log: log,
            energyLevel: energyLevel,
            updatedAt: updatedAt.map { Date(timeIntervalSince1970: $0 / 1000) }
        )
    }
}

extension EmotionData {
    static let emotionOrder = [
        "happy",
        "loved",
        "confident",
        "playful",
        "balanced",
        "embarrassed",
        "angry",
        "scared",
        "sad"
    ]
    
    static let emotions: [String: [String]] = [
        "sad": ["sad", "lonely", "hurt", "disappointed"],
        "scared": ["scared", "anxious", "powerless", "overwhelmed"],
        "angry": ["angry", "bored", "jealous", "annoyed"],
        "embarrassed": ["embarrassed", "ashamed", "excluded", "guilty"],
        "playful": ["playful", "creative", "curious", "affectionate"],
        "confident": ["confident", "brave", "hopeful", "powerful"],
        "loved": ["loved", "respected", "valued", "accepted"],
        "happy": ["happy", "caring", "grateful", "excited"],
        "balanced": ["balanced"]
    ]
}