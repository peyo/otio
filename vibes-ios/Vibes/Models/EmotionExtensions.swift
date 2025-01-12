import SwiftUI

// Extensions for Emotion Colors and Emojis
extension Color {
    static func forEmotion(_ type: String) -> Color {
        switch type {
        case "happy": return .green
        case "sad": return .blue
        case "anxious": return .yellow
        case "angry": return .red
        case "balanced": return .gray
        default: return .gray
        }
    }
}

public func emojiFor(_ emotion: String) -> String {
    switch emotion.lowercased() {
    case "happy":
        return "happy-face"
    case "sad":
        return "sad-face"
    case "anxious":
        return "anxious-face"
    case "angry":
        return "angry-face"
    case "balanced":
        return "balanced-face"
    default:
        return "unknown-face"
    }
}

extension EmotionData {
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
