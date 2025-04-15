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
            title: /*"track your emotions",*/"",
            description: "tap an emotion whenever you'd like to track how you're feeling. studies (lieberman, 2007) found that naming emotions reduces amygdala activity, making feelings less overwhelming."
        ),
        TutorialSlide(
            lightModeImage: "insights_screen_light",
            darkModeImage: "insights_screen_dark",
            title: /*"spot emotional insights",*/"",
            description: "view your emotional patterns and receive daily reflections. mindfulness research (kabat-zinn, 1990) shows that reflective awareness improves mental health and emotional understanding."
        )
    ]
    
    var isLastSlide: Bool {
        currentSlide == slides.count - 1
    }
    
    func completeTutorial() {
        UserDefaults.standard.set(TutorialState.currentVersion, forKey: "tutorialVersion")
    }
}