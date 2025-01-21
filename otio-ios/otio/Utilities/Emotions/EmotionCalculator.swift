import Foundation

struct EmotionCalculator {
    static func calculateWeeklyScore(emotions: [EmotionData]) -> Double {
        var totalScore = 0.0
        for emotion in emotions {
            let baseScore: Double
            switch emotion.type {
            case "happy":
                baseScore = 2.0
            case "sad":
                baseScore = 1.0
            case "anxious":
                baseScore = -1.0
            case "angry":
                baseScore = -2.0
            default:
                baseScore = 0.0
            }
            let weightedScore = baseScore * Double(emotion.intensity)
            totalScore += weightedScore
            print("Debug: Emotion \(emotion.type) with intensity \(emotion.intensity) contributes \(weightedScore) to total score.")
        }
        print("Debug: Total Weekly Score: \(totalScore)")
        return totalScore
    }

    static func normalizeScore(actualScore: Double, maxScore: Double) -> Double {
        let normalized = actualScore / maxScore
        print("Debug: Normalized Score: \(normalized) (Actual: \(actualScore), Max: \(maxScore))")
        return normalized
    }

    static func calculateMaxPossibleScore(maxEntries: Int, maxIntensity: Int) -> Double {
        let maxScore = Double(maxEntries * 2 * maxIntensity)
        print("Debug: Max Possible Score: \(maxScore)")
        return maxScore
    }

    static func calculateAndNormalizeWeeklyScore(emotions: [EmotionData]) -> Double {
        let actualScore = calculateWeeklyScore(emotions: emotions)
        let maxScore = calculateMaxPossibleScore(maxEntries: 10, maxIntensity: 3)
        return normalizeScore(actualScore: actualScore, maxScore: maxScore)
    }
} 