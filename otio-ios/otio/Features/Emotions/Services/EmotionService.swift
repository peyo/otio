import FirebaseAuth
import Foundation

class EmotionService: ObservableObject {
    // Recent emotions data
    @Published var recentEmotions: [EmotionData] = []
    
    static let shared = EmotionService()
    private let cooldownService = EmotionCooldownService()
    private let validationService = EmotionValidationService()
    
    private init() {}
    
    // MARK: - Public Methods
    
    func logEmotion(type: String, text: String? = nil, energyLevel: Int? = nil) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "EmotionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        // Check cooldown
        guard cooldownService.tryLogEmotion() else {
            throw NSError(domain: "EmotionService", code: 2, userInfo: [NSLocalizedDescriptionKey: "In cooldown period"])
        }
        
        try validationService.validateEmotionData(type: type, energyLevel: energyLevel, text: text)
        try await EmotionDatabaseService.submitEmotion(type: type, userId: userId, text: text, energyLevel: energyLevel)
        NotificationCenter.default.post(name: NSNotification.Name("EmotionSaved"), object: nil)
        try await refreshRecentEmotions()
    }
    
    // Update an existing emotion
    func updateEmotion(id: String, type: String, text: String? = nil, energyLevel: Int? = nil) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "EmotionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        // First validate the data
        try validationService.validateEmotionData(type: type, energyLevel: energyLevel, text: text)
        
        try await EmotionDatabaseService.updateEmotion(id: id, userId: userId, type: type, text: text, energyLevel: energyLevel)
        
        try await refreshRecentEmotions()
    }
    
    // Delete an emotion
    func deleteEmotion(id: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "EmotionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        try await EmotionDatabaseService.deleteEmotion(emotionId: id, userId: userId)
        try await refreshRecentEmotions()
    }
    
    // Refresh recent emotions
    @MainActor
    func refreshRecentEmotions() async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "EmotionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        let (_, recent) = try await EmotionDatabaseService.fetchEmotions(userId: userId)
        self.recentEmotions = recent
    }
}