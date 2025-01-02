import SwiftUI

// API Response Models
struct EmotionsResponse: Codable {
    let success: Bool
    let data: [EmotionData]
}

struct EmotionData: Codable, Identifiable {
    let id: Int
    let type: String
    let intensity: Int
    let createdAt: Date
    
    var date: Date { createdAt }
}

// Enums for Analytics
enum ChartType: String, CaseIterable {
    case timeline
    case pieChart
}

enum DateRange: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
}

enum EmotionType: String, CaseIterable, Identifiable {
    case happy = "Happy"
    case sad = "Sad"
    case anxious = "Anxious"
    case angry = "Angry"
    case neutral = "Neutral"
    
    var id: String { rawValue }
    
    static var all: [EmotionType] {
        Self.allCases
    }
}

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