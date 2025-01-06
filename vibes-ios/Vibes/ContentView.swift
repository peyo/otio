import SwiftUI
import FirebaseDatabase
import FirebaseAuth

struct EmotionOption: Identifiable {
    let id = UUID()
    let type: String
    let icon: String
}

struct ContentView: View {
    @EnvironmentObject var userService: UserService
    private let emotions = ["Happy", "Sad", "Anxious", "Angry", "Neutral"]
    private let buttonSpacing: CGFloat = 12

    @State private var selectedEmotion: String?
    @State private var showingIntensitySheet = false
    @State private var weekEmotions: [EmotionData] = [] // Cache for a week's emotions
    @State private var recentEmotions: [EmotionData] = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        Group {
            if userService.isAuthenticated {
                NavigationStack {
                    ScrollView {
                        VStack(spacing: 32) {
                            emotionInputSection
                            recentEmotionsSection
                        }
                    }
                    .background(Color(.systemGroupedBackground))
                    .navigationTitle("Vibes")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            HStack(spacing: 16) {
                                NavigationLink {
                                    ConnectionView()
                                } label: {
                                    Image(systemName: "person.2.fill")
                                        .foregroundColor(.appAccent)
                                }
                                
                                NavigationLink(destination: {
                                    print("Debug: 📊 Passing \(weekEmotions.count) emotions to analytics")
                                    print("Debug: 📝 Week emotions content:")
                                    weekEmotions.forEach { emotion in
                                        print("- \(emotion.type) (Intensity: \(emotion.intensity)) at \(emotion.date)")
                                    }
                                    
                                    return EmotionsAnalyticsView(emotions: weekEmotions)
                                }, label: {
                                    Image(systemName: "eye")
                                        .foregroundColor(.appAccent)
                                })
                                
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
        .padding(.top, 16)
    }

    private var recentEmotionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent")
                .font(.headline)
                .padding(.horizontal)

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if recentEmotions.isEmpty {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay(
                        HStack(spacing: 16) {
                            Image(systemName: "heart.text.square")
                                .font(.system(size: 24))
                                .foregroundColor(.appAccent)
                                .frame(width: 40)
                            
                            Text("Track your first emotion to see it here.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        .padding()
                    )
                    .frame(height: 80)
                    .padding(.horizontal)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(recentEmotions.prefix(3))) { emotion in
                        EmotionCard(
                            emotion: emotion,
                            timeString: relativeTimeString(from:)
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func handleEmotionTap(_ type: String) {
        if type == "Neutral" {
            submitEmotion(type: "Neutral", intensity: 0)
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
                    let emotion = EmotionData(id: snapshot.key, type: type, intensity: intensity, createdAt: date)
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
                    let emotion = EmotionData(id: snapshot.key, type: type, intensity: intensity, createdAt: date)
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
}

struct EmotionButton: View {
    let type: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack {
                Text(emojiFor(type))
                    .font(.system(size: 40))
                Text(type)
                    .font(.caption)
            }
            .frame(width: 100, height: 100)
            .background(Color.forEmotion(type).opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.forEmotion(type) : .clear, lineWidth: 2)
            )
        }
        .foregroundColor(.primary)
    }
}

struct EmotionCard: View {
    let emotion: EmotionData
    let timeString: (Date) -> String

    var body: some View {
        HStack(spacing: 16) {
            // Emoji Circle
            Text(emojiFor(emotion.type))
                .font(.title)
                .padding(12)
                .background(
                    Circle()
                        .fill(Color.forEmotion(emotion.type).opacity(0.1))
                )

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(emotion.type)
                        .fontWeight(.medium)
                    if emotion.type != "Neutral" {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("Intensity \(emotion.intensity)")
                            .foregroundColor(.secondary)
                    }
                }

                Text(timeString(emotion.date))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
    }
}

struct IntensitySelectionView: View {
    let emotion: String
    let onSelect: (Int) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Text(emojiFor(emotion))
                        .font(.system(size: 60))

                    Text("How \(emotion.lowercased()) are you feeling?")
                        .font(.headline)
                }
                .padding(.top, 40)

                HStack(spacing: 20) {
                    ForEach(1...3, id: \.self) { intensity in
                        Button {
                            onSelect(intensity)
                            dismiss()
                        } label: {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.forEmotion(emotion).opacity(Double(intensity) / 3.0))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    VStack(spacing: 4) {
                                        Text("\(intensity)")
                                            .font(.title2)
                                        Text(intensityLabel(for: intensity))
                                            .font(.caption)
                                    }
                                        .foregroundColor(.primary)
                                )
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Select Intensity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func intensityLabel(for intensity: Int) -> String {
        switch intensity {
        case 1: return "A little"
        case 2: return "Somewhat"
        case 3: return "Very"
        default: return ""
        }
    }
}

#Preview {
    ContentView()
}
