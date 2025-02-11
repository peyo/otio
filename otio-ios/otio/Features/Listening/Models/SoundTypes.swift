import Foundation

enum SoundType: String, CaseIterable {
    case upliftingSound = "uplifting sound"
    case soothingSound = "soothing sound"
    case calmingSound = "calming sound"
    case groundingSound = "grounding sound"
    case rancheriaFalls = "rancheria falls"
    case recommendedSound = "recommended sound"
}

func determineRecommendedSound(from normalizedScore: Double) -> SoundType {
    switch normalizedScore {
    case 0.6...1.0:  // Happy
        return .upliftingSound
    case 0.2..<0.6:  // Loved or Confident
        return .upliftingSound
    case 0.0..<0.2:  // Playful
        return .soothingSound
    case -0.2..<0.0:  // Embarrassed
        return .soothingSound
    case -0.6..<(-0.2):  // Scared
        return .calmingSound
    case -1.0..<(-0.6):  // Angry
        return .groundingSound
    case -4.0..<(-1.0):  // Sad
        return .soothingSound
    case 0.0:  // Balanced
        return .rancheriaFalls
    default:
        return .rancheriaFalls
    }
}