import Foundation

/// Represents user preferences for self-compassion reminders
struct ReminderPreference: Codable {
    /// Whether reminders are enabled
    var isEnabled: Bool
    
    /// Days of the week when reminders should be sent
    var selectedDays: Set<Weekday>
    
    /// Hour component of reminder time (1-12)
    var hour: Int
    
    /// Minute component of reminder time (0-59)
    var minute: Int
    
    /// Whether the time is AM (true) or PM (false)
    var isAM: Bool
    
    /// Default initializer with common values
    init(
        isEnabled: Bool = false,
        selectedDays: Set<Weekday> = [],
        hour: Int = 2,
        minute: Int = 7,
        isAM: Bool = false
    ) {
        self.isEnabled = isEnabled
        self.selectedDays = selectedDays
        self.hour = hour
        self.minute = minute
        self.isAM = isAM
    }
    
    /// Returns a formatted string representation of the time (e.g., "09:00")
    var timeString: String {
        String(format: "%02d:%02d", hour, minute)
    }
    
    /// Returns unique identifiers for each day's notification
    var notificationIdentifiers: [String] {
        selectedDays.map { "reminder_\($0.rawValue)" }
    }
}

/// Represents days of the week for reminder scheduling
enum Weekday: String, Codable, CaseIterable {
    case sunday = "su"
    case monday = "m"
    case tuesday = "t"
    case wednesday = "w"
    case thursday = "th"
    case friday = "f"
    case saturday = "s"
    
    /// Converts the weekday to a number (1 = Sunday, 2 = Monday, etc.)
    /// Used for scheduling notifications with UNCalendarNotificationTrigger
    var weekdayNumber: Int {
        switch self {
        case .sunday: return 1
        case .monday: return 2
        case .tuesday: return 3
        case .wednesday: return 4
        case .thursday: return 5
        case .friday: return 6
        case .saturday: return 7
        }
    }
    
    /// Returns the full name of the weekday
    var fullName: String {
        switch self {
        case .sunday: return "sunday"
        case .monday: return "monday"
        case .tuesday: return "tuesday"
        case .wednesday: return "wednesday"
        case .thursday: return "thursday"
        case .friday: return "friday"
        case .saturday: return "saturday"
        }
    }
}

// MARK: - Validation
extension ReminderPreference {
    /// Validates and corrects the time components
    mutating func validateTime() {
        // Ensure hour is between 1 and 12
        hour = max(1, min(hour, 12))
        
        // Ensure minute is between 0 and 59
        minute = max(0, min(minute, 59))
    }
    
    /// Returns true if the preferences are valid for scheduling notifications
    var isValid: Bool {
        guard isEnabled else { return true }  // Always valid if disabled
        
        return !selectedDays.isEmpty &&  // At least one day selected
               hour >= 1 && hour <= 12 &&  // Valid hour
               minute >= 0 && minute <= 59  // Valid minute
    }
}

// MARK: - Debug Helpers
extension ReminderPreference: CustomStringConvertible {
    var description: String {
        """
        ReminderPreference(
            enabled: \(isEnabled),
            days: [\(selectedDays.map { $0.fullName }.joined(separator: ", "))],
            time: \(timeString) \(isAM ? "AM" : "PM")
        )
        """
    }
}