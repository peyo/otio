import SwiftUI

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

extension EmotionData {
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
