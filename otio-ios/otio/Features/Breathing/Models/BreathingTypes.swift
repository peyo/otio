import Foundation

enum BreathingType: String, CaseIterable {
    case boxBreathing = "box"
    case fourSevenEight = "4-7-8"
    case resonance = "resonance"
}

struct BreathingTechnique: Identifiable, Hashable {
    let id = UUID()
    let type: BreathingType
    let name: String
    let pattern: [Int] // Array of seconds for each phase [inhale, hold, exhale, hold]
    let introAudioFile: String? // Name of the intro audio file
    
    static let allTechniques: [BreathingTechnique] = [
        .boxBreathing,
        .fourSevenEight,
        .resonance
    ]
    
    // Predefined techniques
    static let boxBreathing = BreathingTechnique(
        type: .boxBreathing,
        name: "box",
        pattern: [4,4,4,4],
        introAudioFile: "box-breathing-intro.mp3"
    )
    
    static let fourSevenEight = BreathingTechnique(
        type: .fourSevenEight,
        name: "4-7-8",
        pattern: [4,7,8,0], // Note: last 0 means no hold after exhale
        introAudioFile: "four-seven-eight-intro.mp3"
    )
    
    static let resonance = BreathingTechnique(
        type: .resonance,
        name: "resonance",
        pattern: [5,0,5,0], // 5 seconds inhale, 5 seconds exhale, no holds
        introAudioFile: "resonance-intro.mp3"
    )
}

enum BreathingVisualization {
    case box
    case circle
    case wave
    
    static func forTechnique(_ type: BreathingType) -> BreathingVisualization {
        switch type {
        case .boxBreathing:
            return .box
        case .fourSevenEight:
            return .circle
        case .resonance:
            return .wave
        }
    }
}