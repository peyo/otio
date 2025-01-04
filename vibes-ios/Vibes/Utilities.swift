import SwiftUI

// API Response Models
struct EmotionsResponse: Codable {
    let success: Bool
    let data: [EmotionData]
}

struct EmotionData: Identifiable, Codable {
    let id: Int
    let type: String
    let intensity: Int
    let createdAt: Date
    
    var date: Date { createdAt }
}

// New Insight struct
struct Insight: Codable {
    let title: String
    let description: String
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
