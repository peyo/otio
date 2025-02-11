import SwiftUI

// Extensions for Emotion Colors
extension Color {
    static func forEmotion(_ type: String) -> Color {
        switch type {
        case "happy": return .happyColor
        case "loved": return .lovedColor
        case "confident": return .confidentColor
        case "playful": return .playfulColor
        case "balanced": return .balancedColor
        case "embarrassed": return .embarrassedColor
        case "angry": return .angryColor
        case "scared": return .scaredColor
        case "sad": return .sadColor
        default: return .appText
        }
    }
}

extension EmotionData {
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}