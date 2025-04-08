import Foundation

class EmotionCooldownService: ObservableObject {
    // MARK: - Properties
    private let defaults = UserDefaults.standard
    private var recentLogs: [Date] = []
    private var cooldownEndTime: Date?
    @Published private(set) var inCooldown: Bool = false
    
    // MARK: - Constants
    private let triggerThreshold = 5
    private let triggerTimeWindow: TimeInterval = 10 * 60 // 10 minutes
    private let cooldownPeriod: TimeInterval = 20 * 60 // 20 minutes
    
    // MARK: - Initialization
    init() {
        loadState()
    }
    
    // MARK: - Public Interface
    func canLogEmotion() -> Bool {
        if let endTime = cooldownEndTime, Date() >= endTime {
            inCooldown = false
            cooldownEndTime = nil
            saveState()
        }
        return !inCooldown
    }
    
    func tryLogEmotion() -> Bool {
        if !canLogEmotion() {
            return false
        }
        
        recentLogs.append(Date())
        checkAndTriggerCooldown()
        saveState()
        
        return true
    }
    
    func remainingCooldownTime() -> TimeInterval {
        guard inCooldown, let endTime = cooldownEndTime else {
            return 0
        }
        return max(0, endTime.timeIntervalSince(Date()))
    }
    
    func formattedRemainingTime() -> String {
        let remaining = Int(remainingCooldownTime())
        if remaining <= 0 {
            return "0m"
        }
        let minutes = Int(ceil(Double(remaining) / 60.0))
        return "\(minutes)m"
    }
    
    // MARK: - Private Methods
    private func checkAndTriggerCooldown() {
        let windowStart = Date().addingTimeInterval(-triggerTimeWindow)
        let recentLogCount = recentLogs.filter { $0 >= windowStart }.count
        
        if recentLogCount >= triggerThreshold {
            triggerCooldown()
        }
        
        recentLogs = recentLogs.filter { $0 >= windowStart }
    }
    
    private func triggerCooldown() {
        inCooldown = true
        cooldownEndTime = Date().addingTimeInterval(cooldownPeriod)
    }
    
    // MARK: - Storage Methods
    private func saveState() {
        defaults.set(recentLogs, forKey: "EmotionService.recentLogs")
        defaults.set(cooldownEndTime, forKey: "EmotionService.cooldownEndTime")
        defaults.set(inCooldown, forKey: "EmotionService.inCooldown")
    }
    
    private func loadState() {
        if let savedLogs = defaults.array(forKey: "EmotionService.recentLogs") as? [Date] {
            recentLogs = savedLogs
        }
        cooldownEndTime = defaults.object(forKey: "EmotionService.cooldownEndTime") as? Date
        inCooldown = defaults.bool(forKey: "EmotionService.inCooldown")
        
        // Validate state on load
        _ = canLogEmotion()
    }
}