import Foundation

struct EmotionCalculator {
    static func calculateWeeklyScore(emotions: [EmotionData]) -> Double {
        var totalScore = 0.0
        for emotion in emotions {
            let baseScore: Double
            switch emotion.type {
            case "happy":
                baseScore = 4.0
            case "loved":
                baseScore = 3.0
            case "confident":
                baseScore = 2.0
            case "playful":
                baseScore = 1.0
            case "balanced":
                baseScore = 0.0
            case "embarrassed":
                baseScore = -1.0
            case "angry":
                baseScore = -2.0
            case "scared":
                baseScore = -3.0
            case "sad":
                baseScore = -4.0
            default:
                baseScore = 0.0
            }
            totalScore += baseScore
            print("Debug: Emotion \(emotion.type) contributes \(baseScore) to total score.")
        }
        print("Debug: Total Weekly Score: \(totalScore)")
        return totalScore
    }

    static func normalizeScore(actualScore: Double, maxScore: Double) -> Double {
        let normalized = actualScore / maxScore
        print("Debug: Normalized Score: \(normalized) (Actual: \(actualScore), Max: \(maxScore))")
        return normalized
    }

    static func calculateMaxPossibleScore(maxEntries: Int) -> Double {
        // Each entry can contribute a maximum score of 4 (for "happy")
        let maxScore = Double(maxEntries * 4)
        print("Debug: Max Possible Score: \(maxScore)")
        return maxScore
    }

    static func calculateAndNormalizeWeeklyScore(emotions: [EmotionData]) -> Double {
        let actualScore = calculateWeeklyScore(emotions: emotions)
        let maxScore = calculateMaxPossibleScore(maxEntries: emotions.count)
        return normalizeScore(actualScore: actualScore, maxScore: maxScore)
    }
}