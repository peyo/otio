import Foundation

struct EmotionData: Identifiable, Hashable, Codable {
    let id: String
    let type: String
    let intensity: Int
    let date: Date
} 