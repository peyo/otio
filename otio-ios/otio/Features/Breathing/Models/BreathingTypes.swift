import Foundation

enum BreathingType: String, CaseIterable {
    case boxBreathing = "box breathing"
    case fourSevenEight = "4-7-8 breathing"
}

struct BreathingTechnique: Identifiable, Hashable {
    let id = UUID()
    let type: BreathingType
    let name: String
    let pattern: [Int] // Array of seconds for each phase [inhale, hold, exhale, hold]
    let introAudioFile: String? // Name of the intro audio file
    
    static let allTechniques: [BreathingTechnique] = [
        .boxBreathing,
        .fourSevenEight
    ]
    
    // Predefined techniques
    static let boxBreathing = BreathingTechnique(
        type: .boxBreathing,
        name: "box breathing",
        pattern: [4,4,4,4],
        introAudioFile: "box-breathing-intro.wav"
    )
    
    static let fourSevenEight = BreathingTechnique(
        type: .fourSevenEight,
        name: "4-7-8 breathing",
        pattern: [4,7,8,0], // Note: last 0 means no hold after exhale
        introAudioFile: "four-seven-eight-intro.wav"
    )
}

enum BreathingVisualization {
    case box
    case circle
    
    static func forTechnique(_ type: BreathingType) -> BreathingVisualization {
        switch type {
        case .boxBreathing:
            return .box
        case .fourSevenEight:
            return .circle
        }
    }
}