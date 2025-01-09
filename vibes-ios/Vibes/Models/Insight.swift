import Foundation

struct Insight: Decodable, Hashable {
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
    let cooldownRemaining: Int
}