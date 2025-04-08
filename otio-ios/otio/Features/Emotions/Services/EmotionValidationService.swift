import Foundation

class EmotionValidationService {
    // MARK: - Validation Methods
    
    func validateEmotionData(type: String, energyLevel: Int?, text: String?) throws {
        // Validate emotion type
        guard !type.isEmpty else {
            throw EmotionValidationError.emptyType
        }
        
        // Validate energy level if provided
        if let energyLevel = energyLevel {
            guard (1...5).contains(energyLevel) else {
                throw EmotionValidationError.invalidEnergyLevel
            }
        }
        
        // Validate text if provided
        if let text = text {
            guard text.count <= 500 else {
                throw EmotionValidationError.textTooLong
            }
        }
    }
    
    func validateEmotionData(_ data: [String: Any], id: String) throws -> EmotionData {
        guard let type = data["type"] as? String,
              let timestamp = data["timestamp"] as? Double else {
            throw EmotionValidationError.invalidDataStructure
        }
        
        let energyLevel = data["energy_level"] as? Int
        let text = data["text"] as? String
        let updatedAtTimestamp = data["updated_at"] as? Double
        
        // Validate the data
        try validateEmotionData(type: type, energyLevel: energyLevel, text: text)
        
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
            type: type,
            date: date,
            text: text,
            energyLevel: energyLevel,
            updatedAt: updatedAt
        )
    }
}

// MARK: - Error Types
enum EmotionValidationError: LocalizedError {
    case emptyType
    case invalidEnergyLevel
    case textTooLong
    case invalidDataStructure
    case invalidUpdateTimestamp
    
    var errorDescription: String? {
        switch self {
        case .emptyType:
            return "Emotion type cannot be empty"
        case .invalidEnergyLevel:
            return "Energy level must be between 1 and 5"
        case .textTooLong:
            return "Notes cannot exceed 500 characters"
        case .invalidDataStructure:
            return "Invalid emotion data structure"
        case .invalidUpdateTimestamp:
            return "Update timestamp cannot be before creation timestamp"
        }
    }
}