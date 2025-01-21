import SwiftUI
import FirebaseDatabase
import FirebaseAuth

struct EmotionOption: Identifiable {
    let id = UUID()
    let type: String
    let icon: String
}

struct EmotionsView: View {
    @EnvironmentObject var userService: UserService
    private let emotions = ["happy", "sad", "anxious", "angry", "balanced"]
    private let buttonSpacing: CGFloat = 12

    @State private var selectedEmotion: String?
    @State private var showingIntensitySheet = false
    @State private var weekEmotions: [EmotionData] = []
    @State private var recentEmotions: [EmotionData] = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var normalizedScore: Double = 0.0

    var body: some View {
        Group {
            if userService.isAuthenticated {
                NavigationStack {
                    ZStack {
                        Color.appBackground
                            .ignoresSafeArea()
                        
                        VStack(spacing: 0) {
                            emotionInputSection
                                .padding(.top, 16)
                            
                            Spacer()
                                .frame(minHeight: 32, maxHeight: 48)
                            
                            // In the main VStack after emotionInputSection
                            VStack(alignment: .leading, spacing: 24) {
                                VStack(alignment: .leading, spacing: 24) {
                                    Text("recent")
                                        .font(.custom("NewHeterodoxMono-Book", size: 17))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    if isLoading {
                                        HStack {
                                            Spacer()
                                            ProgressView()
                                                .tint(.appAccent)
                                            Spacer()
                                        }
                                    } else if recentEmotions.isEmpty {
                                        HStack(spacing: 16) {
                                            Image(systemName: "heart.text.square")
                                                .font(.system(size: 24))
                                                .foregroundColor(.appAccent)
                                                .frame(width: 40)
                                            
                                            Text("track your first emotion to see it here.")
                                                .font(.custom("NewHeterodoxMono-Book", size: 15))
                                                .fontWeight(.medium)
                                                .foregroundColor(.primary)
                                            
                                            Spacer()
                                        }
                                        .padding()
                                        .background(Color(.systemBackground))
                                    } else {
                                        VStack(spacing: 16) {
                                            ForEach(Array(recentEmotions.prefix(3))) { emotion in
                                                EmotionCard(
                                                    emotion: emotion,
                                                    timeString: relativeTimeString
                                                )
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)  // Standard padding
                                .padding(.leading, UIApplication.shared.connectedScenes
                                    .compactMap { $0 as? UIWindowScene }
                                    .flatMap { $0.windows }
                                    .first?.safeAreaInsets.left ?? 0)  // Safe area padding
                                .padding(.trailing, UIApplication.shared.connectedScenes
                                    .compactMap { $0 as? UIWindowScene }
                                    .flatMap { $0.windows }
                                    .first?.safeAreaInsets.right ?? 0)  // Safe area padding
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            Spacer(minLength: 16)
                        }
                        .padding(.top, -8)
                    }
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Text("otio")
                                .font(.custom("NewHeterodoxMono-Book", size: 22))
                                .fontWeight(.semibold)
                        }
                        
                        ToolbarItem(placement: .primaryAction) {
                            HStack(spacing: 16) {
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
                }
                .sheet(isPresented: $showingIntensitySheet) {
                    IntensitySelectionView(emotion: selectedEmotion!) { intensity in
                        submitEmotion(type: selectedEmotion!, intensity: intensity)
                    }
                }
                .task {
                    await fetchEmotions()
                    normalizedScore = EmotionCalculator.calculateAndNormalizeWeeklyScore(emotions: weekEmotions)
                    print("Normalized Weekly Score: \(normalizedScore)")
                }
            } else {
                SignInView()
            }
        }
    }
    
    private var emotionInputSection: some View {
        VStack(spacing: 16) {
            // First row: 3 buttons
            HStack(spacing: buttonSpacing) {
                Spacer()
                ForEach(0..<3) { index in
                    EmotionButton(
                        type: emotions[index],
                        isSelected: selectedEmotion == emotions[index],
                        onTap: {
                            handleEmotionTap(emotions[index])
                        }
                    )
                }
                Spacer()
            }

            // Second row: 2 buttons
            HStack(spacing: buttonSpacing) {
                Spacer()
                ForEach(3..<5) { index in
                    EmotionButton(
                        type: emotions[index],
                        isSelected: selectedEmotion == emotions[index],
                        onTap: {
                            handleEmotionTap(emotions[index])
                        }
                    )
                }
                Spacer()
            }
        }
        .padding(.horizontal)  // Add horizontal padding here if needed
    }

    private func handleEmotionTap(_ type: String) {
        if type == "balanced" {
            submitEmotion(type: "balanced", intensity: 0)
        } else {
            selectedEmotion = type
            showingIntensitySheet = true
        }
    }

    private func submitEmotion(type: String, intensity: Int) {
        guard let userId = userService.userId else { 
            errorMessage = "No user logged in"
            showError = true
            return 
        }
        
        Task {
            do {
                try await EmotionService.submitEmotion(type: type, intensity: intensity, userId: userId)
                selectedEmotion = nil
                await fetchEmotions()
            } catch {
                print("Error submitting emotion:", error)
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func fetchEmotions() async {
        guard let userId = userService.userId else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let (all, recent) = try await EmotionService.fetchEmotions(userId: userId)
            
            await MainActor.run {
                self.weekEmotions = all
                self.recentEmotions = recent
                self.normalizedScore = EmotionCalculator.calculateAndNormalizeWeeklyScore(emotions: all)
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func relativeTimeString(from date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day], from: date, to: now)

        if let day = components.day, day > 0 {
            return day == 1 ? "yesterday" : "\(day) days ago"
        }

        if let hour = components.hour, hour > 0 {
            return hour == 1 ? "an hour ago" : "\(hour) hours ago"
        }

        if let minute = components.minute, minute > 0 {
            return minute == 1 ? "a minute ago" : "\(minute) minutes ago"
        }

        return "just now"
    }
}
