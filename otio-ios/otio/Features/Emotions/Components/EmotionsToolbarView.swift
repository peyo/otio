import SwiftUI
import FirebaseAuth
import Foundation

struct EmotionsToolbarView: View {
    @EnvironmentObject var userService: UserService
    let weekEmotions: [EmotionData]
    let normalizedScore: Double
    
    var body: some View {
        HStack(spacing: 8) {
            NavigationLink {
                BreathingView()
            } label: {
                Image(systemName: "nose")
                    .foregroundColor(.appAccent)
            }
            
            NavigationLink {
                InsightsView(emotions: weekEmotions)
            } label: {
                Image(systemName: "eye")
                    .foregroundColor(.appAccent)
            }

            NavigationLink {
                ListeningView(normalizedScore: normalizedScore)
            } label: {
                Image(systemName: "ear")
                    .foregroundColor(.appAccent)
            }
            
            Button {
                do {
                    print("Debug: 🚪 Starting sign out process")
                    try Auth.auth().signOut()
                    userService.signOut()
                    print("Debug: ✅ Sign out completed")
                } catch {
                    print("Debug: ❌ Error signing out:", error)
                }
            } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .foregroundColor(.appAccent)
            }
        }
    }
}