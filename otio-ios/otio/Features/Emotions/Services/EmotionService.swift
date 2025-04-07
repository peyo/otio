import FirebaseDatabase
import FirebaseAuth
import Foundation

class EmotionService: ObservableObject {
    // Recent emotion logs
    private var recentLogs: [Date] = []
    
    // Cooldown state
    @Published private(set) var inCooldown: Bool = false
    private var cooldownEndTime: Date?
    
    // Recent emotions data
    @Published var recentEmotions: [EmotionData] = []
    
    // Constants
    private let triggerThreshold = 5 // Number of emotions
    private let triggerTimeWindow: TimeInterval = 10 * 60 // 10 minutes in seconds
    private let cooldownPeriod: TimeInterval = 20 * 60 // 30 minutes in seconds
    
    static let shared = EmotionService()
    
    private init() {
        // Load saved state if needed
        loadState()
    }
    
    // Check if user can log an emotion
    func canLogEmotion() -> Bool {
        // If cooldown has ended, update state
        if let endTime = cooldownEndTime, Date() >= endTime {
            inCooldown = false
            cooldownEndTime = nil
            saveState()
        }
        
        return !inCooldown
    }

    /* Logic for testing without cooldown
    func canLogEmotion() -> Bool {
        return true  // Always allow logging, never in cooldown
    }
    */
    
    // Try to log an emotion - returns true if successful, false if in cooldown
    func tryLogEmotion() -> Bool {
        // First check if we're in cooldown
        if !canLogEmotion() {
            return false
        }
        
        // Record this attempt
        recentLogs.append(Date())
        
        // Check if we need to trigger cooldown
        checkAndTriggerCooldown()
        
        // Save state
        saveState()
        
        // Logging was successful
        return true
    }
    
    // Check if we need to trigger cooldown
    private func checkAndTriggerCooldown() {
        let windowStart = Date().addingTimeInterval(-triggerTimeWindow)
        
        // Count logs in the trigger window
        let recentLogCount = recentLogs.filter { $0 >= windowStart }.count
        
        // If threshold reached, trigger cooldown
        if recentLogCount >= triggerThreshold {
            triggerCooldown()
        }
        
        // Clean up old logs
        recentLogs = recentLogs.filter { $0 >= windowStart }
    }
    
    // Trigger the cooldown period
    private func triggerCooldown() {
        inCooldown = true
        cooldownEndTime = Date().addingTimeInterval(cooldownPeriod)
    }
    
    // Get remaining cooldown time in seconds
    func remainingCooldownTime() -> TimeInterval {
        guard inCooldown, let endTime = cooldownEndTime else {
            return 0
        }
        
        return max(0, endTime.timeIntervalSince(Date()))
    }
    
    // Format remaining time as minutes only (Xm)
    func formattedRemainingTime() -> String {
        let remaining = Int(remainingCooldownTime())
        if remaining <= 0 {
            return "0m"
        }
        
        let minutes = Int(ceil(Double(remaining) / 60.0)) // Round up to the next minute
        return "\(minutes)m"
    }
    
    // Save state to UserDefaults
    private func saveState() {
        let defaults = UserDefaults.standard
        defaults.set(recentLogs, forKey: "EmotionService.recentLogs")
        defaults.set(cooldownEndTime, forKey: "EmotionService.cooldownEndTime")
        defaults.set(inCooldown, forKey: "EmotionService.inCooldown")
    }
    
    // Load state from UserDefaults
    private func loadState() {
        let defaults = UserDefaults.standard
        if let savedLogs = defaults.array(forKey: "EmotionService.recentLogs") as? [Date] {
            recentLogs = savedLogs
        }
        cooldownEndTime = defaults.object(forKey: "EmotionService.cooldownEndTime") as? Date
        inCooldown = defaults.bool(forKey: "EmotionService.inCooldown")
        
        // Validate state on load
        _ = canLogEmotion() // This will update inCooldown if needed
    }
    
    // Log emotion with optional text and energy level
    func logEmotion(type: String, text: String? = nil, energyLevel: Int? = nil) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: No user logged in")
            return
        }
        
        let ref = Database.database().reference()
        let emotionRef = ref.child("users").child(userId).child("emotions").childByAutoId()
        
        var data: [String: Any] = [
            "type": type,
            "date": ServerValue.timestamp()
        ]
        
        if let text = text, !text.isEmpty {
            data["text"] = text
        }
        
        if let energyLevel = energyLevel {
            data["energy_level"] = energyLevel
        }
        
        emotionRef.setValue(data) { error, _ in
            if let error = error {
                print("Error saving emotion: \(error.localizedDescription)")
            } else {
                print("Emotion logged successfully")
                Task {
                    try? await self.refreshRecentEmotions()
                }
            }
        }
    }
    
    // Update an existing emotion
    func updateEmotion(id: String, type: String, text: String? = nil, energyLevel: Int? = nil) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: No user logged in")
            return
        }
        
        let emotionRef = Database.database().reference()
            .child("users")
            .child(userId)
            .child("emotions")
            .child(id)
        
        var updates: [String: Any] = [
            "type": type
        ]
        
        if let text = text, !text.isEmpty {
            updates["text"] = text
        } else {
            // Remove text field if empty
            updates["text"] = NSNull()
        }
        
        if let energyLevel = energyLevel {
            updates["energy_level"] = energyLevel
        } else {
            // Remove energy_level field if nil
            updates["energy_level"] = NSNull()
        }
        
        emotionRef.updateChildValues(updates) { error, _ in
            if let error = error {
                print("Error updating emotion: \(error.localizedDescription)")
            } else {
                print("Emotion updated successfully")
                Task {
                    try? await self.refreshRecentEmotions()
                }
            }
        }
    }
    
    // Delete an emotion
    func deleteEmotion(id: String) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: No user logged in")
            return
        }
        
        let emotionRef = Database.database().reference()
            .child("users")
            .child(userId)
            .child("emotions")
            .child(id)
        
        emotionRef.removeValue { error, _ in
            if let error = error {
                print("Error deleting emotion: \(error.localizedDescription)")
            } else {
                print("Emotion deleted successfully")
                Task {
                    try? await self.refreshRecentEmotions()
                }
            }
        }
    }
    
    // Refresh recent emotions
    @MainActor
    func refreshRecentEmotions() async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: No user logged in")
            throw NSError(domain: "EmotionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        let (_, recent) = try await Self.fetchEmotions(userId: userId)
        self.recentEmotions = recent
    }
    
    // MARK: - Data Validation
    
    private static func validateEmotionData(type: String, energyLevel: Int?, text: String?) throws {
        // Validate emotion type
        guard !type.isEmpty else {
            throw NSError(domain: "EmotionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Emotion type cannot be empty"])
        }
        
        // Validate energy level if provided
        if let energyLevel = energyLevel {
            guard (1...5).contains(energyLevel) else {
                throw NSError(domain: "EmotionService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Energy level must be between 1 and 5"])
            }
        }
        
        // Validate text if provided
        if let text = text {
            guard text.count <= 500 else {
                throw NSError(domain: "EmotionService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Notes cannot exceed 500 characters"])
            }
        }
    }
    
    private static func validateEmotionData(_ data: [String: Any]) throws -> EmotionData {
        guard let type = data["type"] as? String,
              let timestamp = data["timestamp"] as? Double else {
            throw NSError(domain: "EmotionService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid emotion data structure"])
        }
        
        let energyLevel = data["energy_level"] as? Int
        let text = data["text"] as? String
        
        // Validate the data
        try validateEmotionData(type: type, energyLevel: energyLevel, text: text)
        
        return EmotionData(
            id: data["id"] as? String ?? UUID().uuidString,
            type: type,
            date: Date(timeIntervalSince1970: timestamp / 1000),
            text: text,
            energyLevel: energyLevel
        )
    }

    // MARK: - Public Methods
    
    static func submitEmotion(type: String, userId: String, text: String? = nil, energyLevel: Int? = nil) async throws {
        print("Submitting emotion:", type)
        
        // Validate the data before sending
        try validateEmotionData(type: type, energyLevel: energyLevel, text: text)
        
        let ref = Database.database().reference()
        let emotionsRef = ref.child("users").child(userId).child("emotions")
        
        let emotionData = EmotionData(
            type: type,
            text: text,
            energyLevel: energyLevel
        )
        
        let dict = emotionData.toDictionary()
        
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                emotionsRef.childByAutoId().setValue(dict) { error, _ in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            }
            
            // Post notification for emotion saved
            NotificationCenter.default.post(name: NSNotification.Name("EmotionSaved"), object: nil)
            
        } catch {
            print("Error submitting emotion:", error)
            throw error
        }
    }
    
    static func fetchEmotions(userId: String) async throws -> (all: [EmotionData], recent: [EmotionData]) {
        print("Fetching emotions for user:", userId)
        let ref = Database.database().reference()
        
        // Get reference for all emotions from the past week using indexed query
        let weekAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        // Add a small safety margin (1 hour) to ensure we don't miss any emotions
        let weekAgoTimestamp = Int(weekAgo.addingTimeInterval(-3600).timeIntervalSince1970 * 1000)
        
        // Get all emotions from the past week using indexed query
        let allEmotionsRef = ref.child("users").child(userId).child("emotions")
            .queryOrdered(byChild: "timestamp")
            .queryStarting(atValue: weekAgoTimestamp)
        
        // Get reference for most recent emotions - limited by count, not by field
        let recentEmotionsRef = ref.child("users").child(userId).child("emotions")
            .queryOrdered(byChild: "timestamp")
            .queryLimited(toLast: 7)  // Fetch more to account for potential filtering
        
        async let allEmotionsSnapshot = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<DataSnapshot, Error>) in
            allEmotionsRef.observeSingleEvent(of: .value) { snapshot in
                continuation.resume(returning: snapshot)
            } withCancel: { error in
                continuation.resume(throwing: error)
            }
        }
        
        async let recentEmotionsSnapshot = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<DataSnapshot, Error>) in
            recentEmotionsRef.observeSingleEvent(of: .value) { snapshot in
                continuation.resume(returning: snapshot)
            } withCancel: { error in
                continuation.resume(throwing: error)
            }
        }
        
        let (allSnapshot, recentSnapshot) = try await (allEmotionsSnapshot, recentEmotionsSnapshot)
        
        // Process all emotions
        let allEmotions: [EmotionData] = allSnapshot.children.compactMap { child in
            if let snapshot = child as? DataSnapshot,
               let dict = snapshot.value as? [String: Any] {
                do {
                    let emotion = try validateEmotionData(dict)
                    if emotion.date >= weekAgo {
                        return emotion
                    }
                } catch {
                    print("Error validating emotion data:", error)
                    // Continue processing other emotions even if one fails
                }
            }
            return nil
        }
        
        // Process recent emotions
        let recentEmotions: [EmotionData] = recentSnapshot.children.compactMap { child in
            if let snapshot = child as? DataSnapshot,
               let dict = snapshot.value as? [String: Any] {
                do {
                    let emotion = try validateEmotionData(dict)
                    return emotion
                } catch {
                    print("Error validating emotion data:", error)
                    // Continue processing other emotions even if one fails
                }
            }
            return nil
        }
        
        // Sort emotions by date (newest first)
        let sortedAllEmotions = allEmotions.sorted { (emotion1: EmotionData, emotion2: EmotionData) -> Bool in
            emotion1.date > emotion2.date
        }
        let sortedRecentEmotions = recentEmotions.sorted { (emotion1: EmotionData, emotion2: EmotionData) -> Bool in
            emotion1.date > emotion2.date
        }
        
        // Limit recent emotions to 7 after sorting
        if sortedRecentEmotions.count > 7 {
            return (sortedAllEmotions, Array(sortedRecentEmotions.prefix(7)))
        }
        
        return (sortedAllEmotions, sortedRecentEmotions)
    }

    static func deleteEmotion(emotionId: String, userId: String) async throws {
        let ref = Database.database().reference()
            .child("users")
            .child(userId)
            .child("emotions")
            .child(emotionId)
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ref.removeValue { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}