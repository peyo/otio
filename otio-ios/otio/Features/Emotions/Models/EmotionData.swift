import Foundation

struct EmotionData: Identifiable, Hashable, Codable {
    let id: String
    let type: String
    let date: Date  // Removed intensity
}

extension EmotionData {
    static let emotionOrder = [
        "happy",
        "loved",
        "confident",
        "playful",
        "balanced",
        "embarrassed",
        "angry",
        "scared",
        "sad"
    ]
    
    static let emotions: [String: [String]] = [
        "sad": ["sad", "lonely", "hurt", "disappointed"],
        "scared": ["scared", "anxious", "powerless", "overwhelmed"],
        "angry": ["angry", "bored", "jealous", "annoyed"],
        "embarrassed": ["embarrassed", "ashamed", "excluded", "guilty"],
        "playful": ["playful", "creative", "curious", "affectionate"],
        "confident": ["confident", "brave", "hopeful", "powerful"],
        "loved": ["loved", "respected", "valued", "accepted"],
        "happy": ["happy", "caring", "grateful", "excited"],
        "balanced": ["balanced"]
    ]
}