import FirebaseDatabase
import FirebaseAuth
import Foundation

class EmotionService: ObservableObject {
    // Recent emotion logs
    private var recentLogs: [Date] = []
    
    // Cooldown state
    @Published private(set) var inCooldown: Bool = false
    private var cooldownEndTime: Date?
    
    // Constants
    private let triggerThreshold = 5 // Number of emotions
    private let triggerTimeWindow: TimeInterval = 10 * 60 // 10 minutes in seconds
    private let cooldownPeriod: TimeInterval = 20 * 60 // 20 minutes in seconds
    
    init() {
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

    static func submitEmotion(type: String, userId: String) async throws {
        print("Submitting emotion for user:", userId)  // Add debug log
        let ref = Database.database().reference()
        let emotionRef = ref.child("users").child(userId).child("emotions").childByAutoId()
        
        let data: [String: Any] = [
            "type": type,
            "timestamp": ServerValue.timestamp()
        ]
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            emotionRef.setValue(data) { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    static func fetchEmotions(userId: String) async throws -> (all: [EmotionData], recent: [EmotionData]) {
        print("Fetching emotions for user:", userId)  // Add debug log
        let ref = Database.database().reference()
        
        // Get reference for all emotions from the past week
        let weekAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        let timestamp = Int(weekAgo.timeIntervalSince1970 * 1000)
        
        let allEmotionsRef = ref.child("users").child(userId).child("emotions")
            .queryOrdered(byChild: "timestamp")
            .queryStarting(atValue: timestamp)
        
        // Get reference for most recent emotions
        let recentEmotionsRef = ref.child("users").child(userId).child("emotions")
            .queryOrdered(byChild: "timestamp")
            .queryLimited(toLast: 7)
        
        async let allEmotionsSnapshot = try await withCheckedThrowingContinuation { continuation in
            allEmotionsRef.observeSingleEvent(of: .value) { snapshot in
                continuation.resume(returning: snapshot)
            } withCancel: { error in
                continuation.resume(throwing: error)
            }
        }
        
        async let recentEmotionsSnapshot = try await withCheckedThrowingContinuation { continuation in
            recentEmotionsRef.observeSingleEvent(of: .value) { snapshot in
                continuation.resume(returning: snapshot)
            } withCancel: { error in
                continuation.resume(throwing: error)
            }
        }
        
        let (allSnapshot, recentSnapshot) = try await (allEmotionsSnapshot, recentEmotionsSnapshot)
        
        var allEmotions: [EmotionData] = []
        var recentEmotions: [EmotionData] = []
        
        // Process all emotions
        for child in allSnapshot.children {
            if let snapshot = child as? DataSnapshot,
               let dict = snapshot.value as? [String: Any],
               let type = dict["type"] as? String,
               let timestamp = dict["timestamp"] as? Double {
                
                let date = Date(timeIntervalSince1970: timestamp / 1000)
                let emotion = EmotionData(
                    id: snapshot.key,
                    type: type,
                    date: date  // Removed intensity
                )
                allEmotions.append(emotion)
            }
        }
        
        // Process recent emotions
        for child in recentSnapshot.children {
            if let snapshot = child as? DataSnapshot,
               let dict = snapshot.value as? [String: Any],
               let type = dict["type"] as? String,
               let timestamp = dict["timestamp"] as? Double {
                
                let date = Date(timeIntervalSince1970: timestamp / 1000)
                let emotion = EmotionData(
                    id: snapshot.key,
                    type: type,
                    date: date  // Removed intensity
                )
                recentEmotions.append(emotion)
            }
        }
        
        // Sort emotions by date (newest first)
        allEmotions.sort { (emotion1: EmotionData, emotion2: EmotionData) -> Bool in
            emotion1.date > emotion2.date
        }
        recentEmotions.sort { (emotion1: EmotionData, emotion2: EmotionData) -> Bool in
            emotion1.date > emotion2.date
        }
        
        return (allEmotions, recentEmotions)
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