import Foundation

enum SoundType: String, CaseIterable {
    case recommendedSound = "recommended sound"
    case happySound = "uplifting sound"
    case sadSound = "soothing sound"
    case anxiousSound = "calming sound"
    case angrySound = "grounding sound"
    case natureSound = "rancheria falls"
}

func determineRecommendedSound(from normalizedScore: Double) -> SoundType {
    switch normalizedScore {
    case 0.6...1.0:
        return .happySound
    case 0.2..<0.6:
        return .sadSound
    case -0.2..<0.2:
        return .natureSound
    case -0.6..<(-0.2):
        return .anxiousSound
    case -1.0..<(-0.6):
        return .angrySound
    default:
        return .natureSound
    }
}