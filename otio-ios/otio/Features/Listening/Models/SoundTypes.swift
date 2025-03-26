import Foundation

enum SoundType: String, CaseIterable {
    case happy = "happy"
    case loved = "loved"
    case confident = "confident"
    case playful = "playful"
    case embarrassed = "embarrassed"
    case scared = "scared"
    case angry = "angry"
    case sad = "sad"
    case rancheriaFalls = "rancheria falls"
    case recommendedSound = "recommended sound"
    
    // Audio file name for nature sounds
    var audioFileName: String? {
        switch self {
        case .rancheriaFalls:
            return "2024-09-15-rancheria-falls.mp3"
        default:
            return nil
        }
    }
    
    // Add this property for intro audio files
    var introAudioFile: String? {
        switch self {
        case .happy: return "happy-meditation.mp3"
        case .loved: return "loved-meditation.mp3"
        case .confident: return "confident-meditation.mp3"
        case .playful: return "playful-meditation.mp3"
        case .embarrassed: return "embarrassed-meditation.mp3"
        case .scared: return "scared-meditation.mp3"
        case .angry: return "angry-meditation.mp3"
        case .sad: return "sad-meditation.mp3"
        case .rancheriaFalls: return "rancheria-falls-meditation.mp3"
        case .recommendedSound: return "recommended-meditation.mp3"
        }
    }
}

func determineRecommendedSound(from normalizedScore: Double) -> SoundType {
    switch normalizedScore {
    case 0.75...1.0:  // Happy
        return .happy
    case 0.5..<0.75:  // Loved
        return .loved
    case 0.25..<0.5:  // Confident
        return .confident
    case 0.0..<0.25:  // Playful
        return .playful
    case -0.25..<0.0:  // Embarrassed
        return .embarrassed
    case -0.5..<(-0.25):  // Scared
        return .scared
    case -0.75..<(-0.5):  // Angry
        return .angry
    case -1.0..<(-0.75):  // Sad
        return .sad
    case 0.0:  // Balanced (exact 0.0)
        return .rancheriaFalls
    default:
        return .rancheriaFalls
    }
}