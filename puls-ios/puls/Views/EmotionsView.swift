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
    @State private var weekEmotions: [EmotionData] = [] // Cache for a week's emotions
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
                        Color(.systemGroupedBackground)
                            .ignoresSafeArea()  // This extends the background behind the navigation bar
                        
                        VStack(spacing: 0) {
                            emotionInputSection
                                .padding(.top, 16)
                            
                            // Reduce the Spacer height to move Recent up
                            Spacer()
                                .frame(minHeight: 32, maxHeight: 48)  // Reduced from 48-64 to 32-48
                            
                            // Recent section as a separate VStack
                            VStack(alignment: .leading, spacing: 16) {
                                Text("recent")
                                    .font(.custom("NewHeterodoxMono-Book", size: 17))
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .padding(.horizontal)
                                    .padding(.bottom, 21)
                                
                                // Cards container
                                VStack(spacing: 12) {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.appAccent)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                            .padding(.vertical, 50) // Adjust padding to center the ProgressView
                                    } else if recentEmotions.isEmpty {
                                        HStack(spacing: 16) {
                                            Image(systemName: "heart.text.square")
                                                .font(.system(size: 24))
                                                .foregroundColor(.appAccent)
                                                .frame(width: 40)
                                            
                                            Text("track your first emotion to see it here.")
                                                .font(.custom("NewHeterodoxMono-Book", size: 15))
                                                .fontWeight(.medium)
                                                .foregroundColor(.secondary)
                                            
                                            Spacer()
                                        }
                                        .padding()
                                        .background(
                                            Rectangle()
                                                .fill(Color(.systemBackground))
                                        )
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .padding(.vertical, 50) // Adjust padding to center the message
                                    } else {
                                        ForEach(Array(recentEmotions.prefix(3))) { emotion in
                                            EmotionCard(
                                                emotion: emotion,
                                                timeString: relativeTimeString
                                            )
                                        }
                                    }
                                }
                                .frame(height: 240)
                                .padding(.horizontal)
                            }
                            .padding(.top, 8)
                            
                            Spacer(minLength: 16)
                        }
                        .padding(.top, -8)
                    }
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Text("puls")
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
                    .sheet(isPresented: $showingIntensitySheet) {
                        IntensitySelectionView(emotion: selectedEmotion!) { intensity in
                            submitEmotion(type: selectedEmotion!, intensity: intensity)
                        }
                    }
                    .task {
                        await fetchEmotions()
                        normalizedScore = calculateAndNormalizeWeeklyScore()
                        print("Normalized Weekly Score: \(normalizedScore)")
                    }
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
            print("Debug: No userId found in submitEmotion")
            errorMessage = "No user logged in"
            showError = true
            return 
        }
        print("Debug: Submitting emotion for userId:", userId)
        
        Task {
            do {
                let ref = Database.database().reference()
                let emotionRef = ref.child("users").child(userId).child("emotions").childByAutoId()
                
                let data: [String: Any] = [
                    "type": type,
                    "intensity": intensity,
                    "timestamp": ServerValue.timestamp()
                ]
                
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    emotionRef.setValue(data) { error, _ in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: ())
                        }
                    }
                }
                
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
        guard let userId = userService.userId else { 
            print("Debug: ❌ No userId found in fetchEmotions")
            return 
        }
        print("Debug: 🔍 Starting fetch for userId:", userId)
        
        isLoading = true
        defer { isLoading = false }
        
        let ref = Database.database().reference()
        
        // Fetch all emotions for analytics
        let allEmotionsRef = ref.child("users").child(userId).child("emotions")
            .queryOrdered(byChild: "timestamp")
        print("Debug: 📱 Fetching all emotions with query:", allEmotionsRef.description)
        
        // Fetch only recent emotions, ordered by timestamp, limited to 3
        let recentEmotionsRef = ref.child("users").child(userId).child("emotions")
            .queryOrdered(byChild: "timestamp")
            .queryLimited(toLast: 3)
        print("Debug: 📱 Fetching recent emotions with query:", DatabaseQuery.description())
        
        do {
            // Fetch both in parallel
            async let allSnapshotResult = withCheckedThrowingContinuation { (continuation: CheckedContinuation<DataSnapshot, Error>) in
                allEmotionsRef.getData { error, snapshot in
                    if let error = error {
                        print("Debug: ❌ All emotions fetch error:", error.localizedDescription)
                        continuation.resume(throwing: error)
                    } else if let snapshot = snapshot {
                        print("Debug: ✅ All emotions snapshot received")
                        continuation.resume(returning: snapshot)
                    }
                }
            }
            
            async let recentSnapshotResult = withCheckedThrowingContinuation { (continuation: CheckedContinuation<DataSnapshot, Error>) in
                recentEmotionsRef.getData { error, snapshot in
                    if let error = error {
                        print("Debug: ❌ Recent emotions fetch error:", error.localizedDescription)
                        continuation.resume(throwing: error)
                    } else if let snapshot = snapshot {
                        print("Debug: ✅ Recent emotions snapshot received")
                        continuation.resume(returning: snapshot)
                    }
                }
            }
            
            // Process snapshots
            let (allSnapshot, recentSnapshot) = try await (allSnapshotResult, recentSnapshotResult)
            
            var allEmotions: [EmotionData] = []
            var recentEmotions: [EmotionData] = []
            
            // Process all emotions
            for child in allSnapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let dict = snapshot.value as? [String: Any],
                   let type = dict["type"] as? String,
                   let intensity = dict["intensity"] as? Int,
                   let timestamp = dict["timestamp"] as? TimeInterval {
                    let date = Date(timeIntervalSince1970: timestamp/1000)
                    let emotion = EmotionData(id: snapshot.key, type: type, intensity: intensity, date: date)
                    allEmotions.append(emotion)
                }
            }
            
            // Process recent emotions
            for child in recentSnapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let dict = snapshot.value as? [String: Any],
                   let type = dict["type"] as? String,
                   let intensity = dict["intensity"] as? Int,
                   let timestamp = dict["timestamp"] as? TimeInterval {
                    let date = Date(timeIntervalSince1970: timestamp/1000)
                    let emotion = EmotionData(id: snapshot.key, type: type, intensity: intensity, date: date)
                    recentEmotions.append(emotion)
                }
            }
            
            // Sort both arrays by date (newest first)
            allEmotions.sort { $0.date > $1.date }
            recentEmotions.sort { $0.date > $1.date }
            
            print("Debug: 📊 Processed all emotions:", allEmotions.count)
            print("Debug: 🎯 Processed recent emotions:", recentEmotions.count)
            
            await MainActor.run {
                print("Debug: 🔍 All emotions before setting:", allEmotions.map { "\($0.type) (\($0.intensity))" })
                self.weekEmotions = allEmotions
                self.recentEmotions = recentEmotions
                print("Debug: 🔄 Updated UI - Recent:", self.recentEmotions.count, "All:", self.weekEmotions.count)
                
                // Add detailed debug logging for weekEmotions
                print("Debug: 📊 Week emotions content:")
                self.weekEmotions.forEach { emotion in
                    print("- \(emotion.type) (Intensity: \(emotion.intensity)) at \(emotion.date)")
                }
            }
            
        } catch {
            print("Debug: ❌ Fetch error:", error)
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

    private func calculateWeeklyScore(emotions: [EmotionData]) -> Double {
        var totalScore = 0.0
        for emotion in emotions {
            let baseScore: Double
            switch emotion.type {
            case "happy":
                baseScore = 2.0
            case "sad":
                baseScore = 1.0
            case "anxious":
                baseScore = -1.0
            case "angry":
                baseScore = -2.0
            default:
                baseScore = 0.0
            }
            let weightedScore = baseScore * Double(emotion.intensity)
            totalScore += weightedScore
            print("Debug: Emotion \(emotion.type) with intensity \(emotion.intensity) contributes \(weightedScore) to total score.")
        }
        print("Debug: Total Weekly Score: \(totalScore)")
        return totalScore
    }

    private func normalizeScore(actualScore: Double, maxScore: Double) -> Double {
        let normalized = actualScore / maxScore
        print("Debug: Normalized Score: \(normalized) (Actual: \(actualScore), Max: \(maxScore))")
        return normalized
    }

    private func calculateMaxPossibleScore(maxEntries: Int, maxIntensity: Int) -> Double {
        let maxScore = Double(maxEntries * 2 * maxIntensity)
        print("Debug: Max Possible Score: \(maxScore)")
        return maxScore
    }

    private func calculateAndNormalizeWeeklyScore() -> Double {
        let actualScore = calculateWeeklyScore(emotions: weekEmotions)
        let maxScore = calculateMaxPossibleScore(maxEntries: 10, maxIntensity: 3) // Example values
        return normalizeScore(actualScore: actualScore, maxScore: maxScore)
    }
}