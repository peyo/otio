import SwiftUI
import UserNotifications

/// Manages self-compassion reminder preferences and notification scheduling
class ReminderManager: ObservableObject {
    /// Current reminder preferences, automatically saves and updates notifications when changed
    @Published var preferences: ReminderPreference {
        didSet {
            savePreferences()
            updateNotifications()
        }
    }
    
    /// Key used to store preferences in UserDefaults
    private let userDefaultsKey = "reminderPreferences"
    
    /// Array of reminder messages
    public let reminderMessages = [
        "hey, just a reminder, your feelings make sense. you're doing your best.",
        "whatever you're feeling, it's okay to feel it. i'm here with you.",
        "you don't have to fix anything right now. just noticing is enough.",
        "i see you're feeling something today. let's gently explore it together.",
        "even tough emotions are part of the journey. you're not alone.",
        "no pressure to be okay all the time. let's just take a breath together.",
        "you've made space for your feelings today, and that matters.",
        "it's okay to pause. you're allowed to just be.",
        "small steps are still progress. i'm proud of you for showing up.",
        "it's okay to feel uncertain. you don't need all the answers right now.",
        "you're allowed to feel exactly how you feel. no need to edit or explain.",
        "this moment doesn't define you. you're allowed to begin again, gently.",
        "let yourself be human today. soft, strong, messy, and real.",
        "you're not behind. you're moving at your own right pace.",
        "there's strength in stillness. doing nothing is sometimes exactly what you need.",
        "let's release the pressure to be productive. rest is worthwhile too.",
        "you don't have to carry it all alone. even this, you can set down for a while.",
        "the way you're feeling makes sense. you're not too much. you're not too little.",
        "you've survived every hard day before this one. that matters.",
        "let today be simple. just breathing and being is enough."
    ]
    
    init() {
        // Load saved preferences or use defaults
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let preferences = try? JSONDecoder().decode(ReminderPreference.self, from: data) {
            self.preferences = preferences
        } else {
            self.preferences = ReminderPreference()
        }
        
        // Request notification permissions on init
        Task {
            await requestNotificationPermissions()
        }
    }
    
    /// Requests authorization for sending notifications
    private func requestNotificationPermissions() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
            
            if !granted {
                print("Notification permissions were denied")
                // Disable notifications if permissions denied
                await MainActor.run {
                    preferences.isEnabled = false
                }
            }
        } catch {
            print("Error requesting notifications permission:", error)
            // Disable notifications if there was an error
            await MainActor.run {
                preferences.isEnabled = false
            }
        }
    }
    
    /// Creates the notification content
    private func createNotification() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "take a moment"
        content.body = reminderMessages.randomElement() ?? "take a moment to check in with yourself."
        content.sound = .default
        return content
    }
    
    /// Updates all scheduled notifications based on current preferences
    private func updateNotifications() {
        // Remove existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Exit if notifications are disabled or preferences are invalid
        guard preferences.isEnabled, preferences.isValid else {
            print("Notifications disabled or preferences invalid")
            return
        }
        
        // Schedule new notifications for each selected day
        for day in preferences.selectedDays {
            scheduleNotification(for: day)
        }
        
        print("Updated notifications for days: \(preferences.selectedDays.map { $0.fullName }.joined(separator: ", "))")
    }
    
    /// Schedules a notification for a specific day
    private func scheduleNotification(for day: Weekday) {
        let content = createNotification()
        
        // Create date components for the notification
        var dateComponents = DateComponents()
        dateComponents.weekday = day.weekdayNumber
        dateComponents.hour = preferences.isAM ? preferences.hour : preferences.hour + 12
        dateComponents.minute = preferences.minute
        
        print("Scheduling notification for \(day.fullName) at \(preferences.timeString) \(preferences.isAM ? "AM" : "PM")")
        
        // Create the trigger
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        
        // Create the request using the preference's notification identifier
        let request = UNNotificationRequest(
            identifier: "reminder_\(day.rawValue)",
            content: content,
            trigger: trigger
        )
        
        // Schedule the notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification for \(day.fullName):", error)
            } else {
                print("Successfully scheduled notification for \(day.fullName)")
            }
        }
    }
    
    /// Saves the current preferences to UserDefaults
    private func savePreferences() {
        if let encoded = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            print("Saved preferences:", preferences.description)
        }
    }
}