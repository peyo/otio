import Foundation

struct EmotionCalculator {
    static func calculateWeeklyScore(emotions: [EmotionData]) -> Double {
        var totalScore = 0.0
        for emotion in emotions {
            let baseScore: Double
            switch emotion.type.lowercased() {
                // Happy family (4.0)
                case "happy", "caring", "grateful", "excited":
                    baseScore = 4.0
                
                // Loved family (3.0)
                case "loved", "respected", "valued", "accepted":
                    baseScore = 3.0
                
                // Confident family (2.0)
                case "confident", "brave", "hopeful", "powerful":
                    baseScore = 2.0
                
                // Playful family (1.0)
                case "playful", "creative", "curious", "affectionate":
                    baseScore = 1.0
                
                // Embarrassed family (-1.0)
                case "embarrassed", "ashamed", "excluded", "guilty":
                    baseScore = -1.0
                
                // Angry family (-2.0)
                case "angry", "bored", "jealous", "annoyed":
                    baseScore = -2.0
                
                // Scared family (-3.0)
                case "scared", "anxious", "powerless", "overwhelmed":
                    baseScore = -3.0
                
                // Sad family (-4.0)
                case "sad", "lonely", "hurt", "disappointed":
                    baseScore = -4.0
                
                default:
                    print("Debug: Unknown emotion type: \(emotion.type)")
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