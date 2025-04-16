import Foundation

class EmotionValidationService {
    // MARK: - Validation Methods
    
    func validateEmotionData(emotion: String, energyLevel: Int?, log: String?) throws {
        if emotion.isEmpty {
            throw EmotionValidationError.emptyEmotion
        }
        
        // Validate energy level if provided
        if let energyLevel = energyLevel {
            guard (1...5).contains(energyLevel) else {
                throw EmotionValidationError.invalidEnergyLevel
            }
        }
        
        // Validate log if provided
        if let log = log {
            guard log.count <= 500 else {
                throw EmotionValidationError.logTooLong
            }
        }
    }
    
    func validateEmotionData(_ data: [String: Any], id: String) throws -> EmotionData {
        guard let emotion = data["emotion"] as? String,
              let timestamp = data["timestamp"] as? Double else {
            throw EmotionValidationError.invalidDataStructure
        }
        
        let energyLevel = data["energy_level"] as? Int
        let log = data["log"] as? String
        let updatedAtTimestamp = data["updated_at"] as? Double
        
        // Validate the data
        try validateEmotionData(emotion: emotion, energyLevel: energyLevel, log: log)
        
        // Convert timestamps to dates
        let date = Date(timeIntervalSince1970: timestamp / 1000)
        let updatedAt = updatedAtTimestamp.map { Date(timeIntervalSince1970: $0 / 1000) }
        
        // Validate updated_at is not before creation date
        if let updatedAt = updatedAt {
            guard updatedAt >= date else {
                throw EmotionValidationError.invalidUpdateTimestamp
            }
        }
        
        return EmotionData(
            id: id,
            emotion: emotion,
            date: date,
            log: log,
            energyLevel: energyLevel,
            updatedAt: updatedAt
        )
    }
}

// MARK: - Error Types
enum EmotionValidationError: LocalizedError {
    case emptyEmotion
    case invalidEnergyLevel
    case logTooLong
    case invalidDataStructure
    case invalidUpdateTimestamp
    
    var errorDescription: String? {
        switch self {
        case .emptyEmotion:
            return "Emotion cannot be empty"
        case .invalidEnergyLevel:
            return "Energy level must be between 1 and 5"
        case .logTooLong:
            return "Notes cannot exceed 500 characters"
        case .invalidDataStructure:
            return "Invalid emotion data structure"
        case .invalidUpdateTimestamp:
            return "Update timestamp cannot be before creation timestamp"
        }
    }
}