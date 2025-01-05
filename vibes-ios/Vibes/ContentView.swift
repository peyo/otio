import SwiftUI

struct EmotionOption: Identifiable {
    let id = UUID()
    let type: String
    let icon: String
}

struct ContentView: View {
    @EnvironmentObject var userService: UserService
    private let emotions = ["Happy", "Sad", "Anxious", "Angry", "Neutral"]
    private let buttonSpacing: CGFloat = 12

    @State private var selectedEmotion: EmotionOption?
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
                                
                                NavigationLink {
                                    EmotionsAnalyticsView(emotions: weekEmotions)
                                } label: {
                                    Image(systemName: "eye")
                                        .foregroundColor(.appAccent)
                                }
                                
                                Button(action: {
                                    userService.signOut()
                                }) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .foregroundColor(.appAccent)
                                }
                            }
                        }
                    }
                    .sheet(isPresented: $showingIntensitySheet) {
                        IntensitySelectionView(emotion: selectedEmotion!) { intensity in
                            submitEmotion(type: selectedEmotion!.type, intensity: intensity)
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
                        isSelected: selectedEmotion?.type == emotions[index],
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
                        isSelected: selectedEmotion?.type == emotions[index],
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
                Text("No recent emotions")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(recentEmotions) { emotion in
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
            selectedEmotion = EmotionOption(
                type: type,
                icon: type
            )
            showingIntensitySheet = true
        }
    }

    private func submitEmotion(type: String, intensity: Int) {
        Task {
            guard let url = URL(string: "http://localhost:3000/api/emotions") else { return }

            let emotion = ["type": type, "intensity": intensity]

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            do {
                let jsonData = try JSONSerialization.data(withJSONObject: emotion)
                request.httpBody = jsonData

                let (_, response) = try await URLSession.shared.data(for: request)

                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 201 {
                    selectedEmotion = nil
                    await fetchEmotions()
                }
            } catch {
                print("Error submitting emotion:", error)
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    func fetchEmotions() async {
        isLoading = true
        defer { isLoading = false }

        guard let url = URL(string: "http://localhost:3000/api/emotions") else {
            print("Error: Invalid URL")
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            let decoder = JSONDecoder()

            // Create a custom date formatter to match the API format
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            decoder.dateDecodingStrategy = .formatted(formatter)

            let emotionsResponse = try decoder.decode(EmotionsResponse.self, from: data)

            // Cache a week's worth of emotions
            let calendar = Calendar.current
            let now = Date()
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
            weekEmotions = emotionsResponse.data.filter { $0.date >= weekAgo }

            // Update recent emotions
            recentEmotions = emotionsResponse.data
                .sorted { $0.date > $1.date }
                .prefix(3)
                .map { $0 }

        } catch {
            print("Error fetching emotions:", error)
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
    let emotion: EmotionOption
    let onSelect: (Int) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Text(emojiFor(emotion.type))
                        .font(.system(size: 60))

                    Text("How \(emotion.type.lowercased()) are you feeling?")
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
                                .fill(Color.forEmotion(emotion.type).opacity(Double(intensity) / 3.0))
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
