import FirebaseAuth
import Foundation

class EmotionService: ObservableObject {
    // Recent emotions data
    @Published var recentEmotions: [EmotionData] = []
    @Published var allEmotions: [EmotionData] = []
    @Published var calendarEmotions: [EmotionData] = []
    
    // Calendar data window tracking
    private var calendarDataStartDate: Date?
    private var calendarDataEndDate: Date?
    
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
        
        // Refresh both recent and calendar emotions
        try await refreshRecentEmotions()
        
        // Force a refresh of the calendar data by clearing the window tracking
        calendarDataStartDate = nil
        calendarDataEndDate = nil
        
        // Fetch the current month's data
        if let startOfMonth = Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: Date())
        ) {
            try await fetchEmotionsForMonth(startOfMonth)
        }
    }
    
    // Delete an emotion
    func deleteEmotion(id: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "EmotionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        try await EmotionDatabaseService.deleteEmotion(emotionId: id, userId: userId)
        
        // Refresh both recent and calendar emotions
        try await refreshRecentEmotions()
        
        // Force a refresh of the calendar data by clearing the window tracking
        calendarDataStartDate = nil
        calendarDataEndDate = nil
        
        // Fetch the current month's data
        if let startOfMonth = Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: Date())
        ) {
            try await fetchEmotionsForMonth(startOfMonth)
        }
    }
    
    // Refresh all emotions
    @MainActor
    func refreshAllEmotions() async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "EmotionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        let (all, _) = try await EmotionDatabaseService.fetchEmotions(userId: userId)
        self.allEmotions = all
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
    
    // Fetch emotions for a specific month
    @MainActor
    func fetchEmotionsForMonth(_ date: Date) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "EmotionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        let calendar = Calendar.current
        
        // Get start of the selected month
        guard let startOfMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: date)
        ) else { return }
        
        // Get start of the next month
        guard let startOfNextMonth = calendar.date(
            byAdding: DateComponents(month: 1),
            to: startOfMonth
        ) else { return }
        
        // Get start of the previous month
        guard let startOfPreviousMonth = calendar.date(
            byAdding: DateComponents(month: -1),
            to: startOfMonth
        ) else { return }
        
        // Check if the requested date range is already within our data window
        if let dataStart = calendarDataStartDate,
           let dataEnd = calendarDataEndDate,
           startOfPreviousMonth >= dataStart && startOfNextMonth <= dataEnd {
            // We already have this data, no need to fetch
            return
        }
        
        // Fetch emotions for a 3-month window (previous, current, and next month)
        let emotions = try await EmotionDatabaseService.fetchEmotionsForDateRange(
            userId: userId,
            startDate: startOfPreviousMonth,
            endDate: startOfNextMonth
        )
        
        self.calendarEmotions = emotions
        self.calendarDataStartDate = startOfPreviousMonth
        self.calendarDataEndDate = startOfNextMonth
    }
}