import Foundation

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