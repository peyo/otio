import SwiftUI
import FirebaseAuth
import Foundation

struct EmotionsToolbarView: View {
    @EnvironmentObject var userService: UserService
    let weekEmotions: [EmotionData]
    let normalizedScore: Double
    @State private var showBreathingView = false
    @State private var showInsightsView = false
    @State private var showListeningView = false
    @State private var showAccountView = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Breathing button
            Button {
                showBreathingView = true
            } label: {
                Image(systemName: "nose")
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
            }
            .navigationDestination(isPresented: $showBreathingView) {
                BreathingView()
            }
            
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

            // Listening button
            Button {
                showListeningView = true
            } label: {
                Image(systemName: "ear")
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
            }
            .navigationDestination(isPresented: $showListeningView) {
                ListeningView(normalizedScore: normalizedScore)
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