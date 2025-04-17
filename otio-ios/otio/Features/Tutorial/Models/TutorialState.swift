import SwiftUI

struct TutorialSlide: Identifiable {
    let id = UUID()
    let lightModeImage: String  // Image for light mode
    let darkModeImage: String   // Image for dark mode
    let title: String
    let description: String
}

class TutorialState: ObservableObject {
    @Published var currentSlide = 0
    static let currentVersion = 1
    
    // Set this to true during development to always show the tutorial
    #if DEBUG
    static let forceShowTutorialForTesting = false // Change this to true to force the tutorial to show
    #else
    static let forceShowTutorialForTesting = false
    #endif
    
    static func shouldShowTutorial() -> Bool {
        // Always show tutorial if force flag is true
        if forceShowTutorialForTesting {
            return true
        }
        
        let lastSeenVersion = UserDefaults.standard.integer(forKey: "tutorialVersion")
        return lastSeenVersion < currentVersion
    }
    
    static func markTutorialAsSeen() {
        UserDefaults.standard.set(currentVersion, forKey: "tutorialVersion")
    }
    
    #if DEBUG
    // Add this method for testing
    static func resetTutorialState() {
        UserDefaults.standard.removeObject(forKey: "tutorialVersion")
        print("DEBUG: Tutorial state reset")
    }
    #endif
    
    let slides = [
        TutorialSlide(
            lightModeImage: "emotions_screen_light",
            darkModeImage: "emotions_screen_dark",
            title: /*"",*/"",
            description: "tap an emotion whenever you'd like to track how you're feeling. studies (lieberman, 2007) found that naming emotions reduces amygdala activity, making feelings less overwhelming."
        ),
        TutorialSlide(
            lightModeImage: "insights_screen_light",
            darkModeImage: "insights_screen_dark",
            title: /*"",*/"",
            description: "view your emotional patterns and receive daily reflections. mindfulness research (kabat-zinn, 1990) shows that reflective awareness improves mental health and emotional understanding."
        ),
        TutorialSlide(
            lightModeImage: "download_screen_light",
            darkModeImage: "download_screen_dark",
            title: /*"",*/"",
            description: "download your emotion log as a csv for personal use or to share with a therapist. research (bailey et al., 2019) shows that emotional data can support collaboration and more personalized care."
        ),
        TutorialSlide(
            lightModeImage: "calendar_screen_light",
            darkModeImage: "calendar_screen_dark",
            title: /*"",*/"",
            description: "view emotions on a calendar. tap any day to reflect on how you felt. research (pennebaker, 1997) shows that tracking emotions over time reveals patterns and builds self-awareness."
        ),
        TutorialSlide(
            lightModeImage: "reminder_screen_light",
            darkModeImage: "reminder_screen_dark",
            title: /*"",*/"",
            description: "schedule gentle reminders to check in with yourself. compassionate prompts support emotional regulation and ease self-criticism, key to emotional well-being and resilience (neff, 2003)."
        )
    ]
    
    var isLastSlide: Bool {
        currentSlide == slides.count - 1
    }
    
    func completeTutorial() {
        UserDefaults.standard.set(TutorialState.currentVersion, forKey: "tutorialVersion")
    }
}