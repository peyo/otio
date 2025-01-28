import SwiftUI

// Extensions for Emotion Colors and Emojis
extension Color {
    static func forEmotion(_ type: String) -> Color {
        switch type {
        case "happy": return .happyColor
        case "sad": return .sadColor
        case "anxious": return .anxiousColor
        case "angry": return .angryColor
        case "balanced": return .balancedColor
        default: return .appText
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
