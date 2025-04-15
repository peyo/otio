import SwiftUI
import FirebaseAuth
import Foundation

struct EmotionsToolbarView: View {
    @EnvironmentObject var userService: UserService
    let weekEmotions: [EmotionData]
    let normalizedScore: Double
    @State private var showInsightsView = false
    @State private var showAccountView = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Insights button
            Button {
                showInsightsView = true
            } label: {
                Image(systemName: "eye")
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
            }
            .navigationDestination(isPresented: $showInsightsView) {
                InsightsView(emotions: weekEmotions)
            }
            
            // Account button
            Button {
                showAccountView = true
            } label: {
                Image(systemName: "person")
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
            }
            .navigationDestination(isPresented: $showAccountView) {
                AccountView()
                    .environmentObject(userService)
            }
        }
    }
}