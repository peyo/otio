import Foundation
import FirebaseDatabase

struct EmotionData: Identifiable, Hashable, Codable {
    let id: String
    let type: String
    let date: Date  // We'll keep the property name as "date" for code clarity
    let text: String?  // Optional text field for user notes
    let energyLevel: Int?  // Optional energy level (1-5 scale)
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case date = "timestamp"  // Map to "timestamp" in JSON
        case text
        case energyLevel = "energy_level"
    }
    
    init(id: String = UUID().uuidString, 
         type: String, 
         date: Date = Date(),
         text: String? = nil,
         energyLevel: Int? = nil) {
        self.id = id
        self.type = type
        self.date = date
        self.text = text
        self.energyLevel = energyLevel
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
    
    // Helper to convert to dictionary for Firebase
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "type": type,
            "timestamp": date.timeIntervalSince1970 * 1000  // Use "timestamp" and convert to milliseconds
        ]
        
        if let text = text {
            dict["text"] = text
        }
        
        if let energyLevel = energyLevel {
            dict["energy_level"] = energyLevel
        }
        
        return dict
    }
    
    // Helper to create from Firebase snapshot
    static func fromSnapshot(_ snapshot: DataSnapshot) -> EmotionData? {
        guard let dict = snapshot.value as? [String: Any],
              let type = dict["type"] as? String,
              let timestamp = dict["timestamp"] as? Double else {  // Look for "timestamp" instead of "date"
            return nil
        }
        
        let text = dict["text"] as? String
        let energyLevel = dict["energy_level"] as? Int
        
        return EmotionData(
            id: snapshot.key,
            type: type,
            date: Date(timeIntervalSince1970: timestamp / 1000),
            text: text,
            energyLevel: energyLevel
        )
    }
}