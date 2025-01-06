import SwiftUI

// API Response Models
struct EmotionsResponse: Codable {
    let success: Bool
    let data: [EmotionData]
}

struct EmotionData: Identifiable, Codable {
    let id: String
    let type: String
    let intensity: Int
    let createdAt: Date
    
    var date: Date { createdAt }
}

struct Insight: Decodable {
    let emoji: String
    let title: String
    let description: String
    
    // Regular initializer for creating Insight instances
    init(emoji: String, title: String, description: String) {
        self.emoji = emoji
        self.title = title
        self.description = description
    }
    
    // Define the coding keys
    private enum CodingKeys: String, CodingKey {
        case emoji
        case title
        case description
    }
    
    // Custom decoder initializer to provide a default emoji
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decode(String.self, forKey: .description)
        
        // Try to decode emoji if present, otherwise use a default
        self.emoji = try container.decodeIfPresent(String.self, forKey: .emoji) ?? "💡"
    }
}

struct InsightsResponse: Decodable {
    let success: Bool
    let insights: [Insight]
}

// Extensions for Emotion Colors and Emojis
extension Color {
    static func forEmotion(_ type: String) -> Color {
        switch type {
        case "Happy": return .green
        case "Sad": return .blue
        case "Anxious": return .yellow
        case "Angry": return .red
        case "Neutral": return .gray
        default: return .gray
        }
    }
}

public func emojiFor(_ emotion: String) -> String {
    switch emotion {
    case "Happy": return "😊"
    case "Sad": return "😢"
    case "Anxious": return "😰"
    case "Angry": return "😠"
    case "Neutral": return "😐"
    default: return "❓"
    }
}
