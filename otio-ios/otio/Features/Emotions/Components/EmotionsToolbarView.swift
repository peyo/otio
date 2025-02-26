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
            Button {
                showBreathingView = true
            } label: {
                Image(systemName: "nose")
                    .foregroundColor(.appAccent)
            }
            .navigationDestination(isPresented: $showBreathingView) {
                BreathingView()
            }
            
            Button {
                showInsightsView = true
            } label: {
                Image(systemName: "eye")
                    .foregroundColor(.appAccent)
            }
            .navigationDestination(isPresented: $showInsightsView) {
                InsightsView(emotions: weekEmotions)
            }

            Button {
                showListeningView = true
            } label: {
                Image(systemName: "ear")
                    .foregroundColor(.appAccent)
            }
            .navigationDestination(isPresented: $showListeningView) {
                ListeningView(normalizedScore: normalizedScore)
            }
            
            Button {
                showAccountView = true
            } label: {
                Image(systemName: "person")
                    .foregroundColor(.appAccent)
            }
            .navigationDestination(isPresented: $showAccountView) {
                AccountView()
            }
        }
    }
}