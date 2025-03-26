import SwiftUI

struct TutorialSlide: Identifiable {
    let id = UUID()
    let image: String
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
            image: "emotions-screen",
            title: /*"track your emotions",*/"",
            description: "tap an emotion whenever you'd like to track how you're feeling. studies (lieberman, 2007) found that naming emotions reduces amygdala activity, making feelings less overwhelming."
        ),
        TutorialSlide(
            image: "insights-screen",
            title: /*"spot emotional insights",*/"",
            description: "view your emotional patterns and receive daily reflections. mindfulness research (kabat-zinn, 1990) shows that reflective awareness improves mental health and emotional understanding."
        ),
        TutorialSlide(
            image: "listening-screen",
            title: /*"listen and center",*/"",
            description: "choose from binaural beats and nature sounds from u.s. parks. studies (zeidan, 2010 and goyal, 2014) show meditation improves focus and reduces anxiety."
        ),
        TutorialSlide(
            image: "breathing-screen",
            title: /*"take a breath",*/"",
            description: "follow guided breathing exercises. research (balban, 2023) found that this cyclic sighing pattern reduces anxiety and negative mood more effectively than meditation alone."
        )
    ]
    
    var isLastSlide: Bool {
        currentSlide == slides.count - 1
    }
    
    func completeTutorial() {
        UserDefaults.standard.set(TutorialState.currentVersion, forKey: "tutorialVersion")
    }
}