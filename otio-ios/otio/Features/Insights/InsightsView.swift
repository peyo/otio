import SwiftUI
import FirebaseFunctions
import FirebaseCore
import FirebaseAuth

struct InsightsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    let emotions: [EmotionData]
    @State private var insights: [Insight] = []
    @State private var errorMessage: String?
    @State private var errorTitle: String?
    @State private var currentTask: Task<Void, Never>?
    @State private var cooldownTime: Int = 0

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    Color.appBackground
                        .ignoresSafeArea()
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: ViewSpacing.subtitleToContent) {
                            Text("navigate your emotions")
                                .font(.custom("IBMPlexMono-Light", size: 17))
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            if isLoading {
                                VStack {
                                    Spacer()
                                    ProgressView()
                                        .tint(.primary)
                                    Spacer()
                                }
                                .frame(height: geometry.size.height * 0.7)
                            } else {
                                // Insights content
                                VStack(spacing: 16) {
                                    if let errorMessage = errorMessage {
                                        let errorInsight = Insight(
                                            emojiName: "zen",
                                            title: errorTitle ?? "oops",
                                            description: errorMessage
                                        )
                                        InsightCard(insight: errorInsight)
                                    } else {
                                        ForEach(insights.prefix(3), id: \.self) { insight in
                                            InsightCard(insight: insight)
                                        }
                                        
                                        if cooldownTime > 0 {
                                            Text("next insights available in: \(cooldownTime / 3600)h \((cooldownTime % 3600) / 60)m")
                                                .font(.custom("IBMPlexMono-Light", size: 13))
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                                .padding(.top, 8)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, ViewSpacing.screenVerticalPadding)
                    }
                    .refreshable {
                        if cooldownTime <= 0 {
                            await fetchInsights()
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("understand")
                            .font(.custom("IBMPlexMono-Light", size: 22))
                            .fontWeight(.semibold)
                    }
                    
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.primary)
                        }
                    }
                }
                .gesture(
                    DragGesture()
                        .onEnded { gesture in
                            if gesture.translation.width > 100 {
                                dismiss()
                            }
                        }
                )
                .task {
                    // Cancel previous task if it exists
                    currentTask?.cancel()
                    
                    // Create and store new task
                    let task = Task {
                        await fetchInsights()
                    }
                    currentTask = task
                    
                    // Wait for completion
                    await task.value
                }
            }
        }
    }

    private func fetchInsights() async {
        isLoading = true
        defer { isLoading = false }

        // Check for cancellation
        if Task.isCancelled { return }

        // Check authentication first
        guard let user = Auth.auth().currentUser else {
            print("Debug: ❌ No authenticated user")
            await MainActor.run {
                errorMessage = "please sign in to view insights."
                errorTitle = "account needed"  // Specific title for auth error
            }
            return
        }

        if emotions.isEmpty {
            print("Debug: ⚠️ no emotions to analyze")
            await MainActor.run {
                errorMessage = "start logging your emotions to view insights."
                errorTitle = "getting started"  // Specific title for empty emotions
            }
            return
        } else if emotions.count < 7 {
            print("Debug: ⚠️ not enough emotions for insights: \(emotions.count)/7")
            await MainActor.run {
                errorMessage = "log \(7 - emotions.count) more emotions to receive personalized insights."
                errorTitle = "almost there"  // Encouraging title for progress
            }
            return
        }

        do {
            // Get a fresh token first
            let token = try await user.getIDToken(forcingRefresh: true)
            print("Debug: 🎫 Using fresh token:", token.prefix(20))
            
            // Create a new Functions instance for each call
            let functions = Functions.functions(app: FirebaseApp.app()!, region: "us-central1")
            
            // Format emotions with all required fields
            let formattedEmotions = emotions.map { emotion in
                var dict: [String: Any] = [
                    "emotion": emotion.emotion,
                    "timestamp": Int(emotion.date.timeIntervalSince1970 * 1000)  // Convert to milliseconds
                ]
                
                if let log = emotion.log {
                    dict["log"] = log
                }
                
                if let energyLevel = emotion.energyLevel {
                    dict["energy_level"] = energyLevel
                }
                
                return dict
            }
            
            print("Debug: 📤 Cloud Function payload:")
            print(formattedEmotions)
            
            // Call function with timeout
            let callable = functions.httpsCallable("generateInsights")
            let result = try await withTimeout(seconds: 30) {
                try await callable.call(["emotions": formattedEmotions])
            }
            
            print("Debug: 📥 Cloud Function response:")
            print(String(describing: result.data))
            
            // Parse response
            guard let data = result.data as? [String: Any],
                  let success = data["success"] as? Bool,
                  success,
                  let insightsData = data["insights"] as? [[String: Any]],
                  let cooldownRemainingMs = data["cooldownRemaining"] as? Int else {
                print("Debug: ❌ Invalid server response")
                throw URLError(.badServerResponse)
            }
            
            let insights = insightsData.map { dict in
                Insight(
                    emojiName: dict["emojiName"] as? String ?? "",
                    title: dict["title"] as? String ?? "",
                    description: dict["description"] as? String ?? ""
                )
            }
            
            print("Debug: ✅ Processed \(insights.count) insights")
            
            await MainActor.run {
                withAnimation {
                    self.insights = insights
                    self.cooldownTime = cooldownRemainingMs / 1000
                    self.errorMessage = nil
                    self.errorTitle = nil  // Clear error title
                }
                print("Debug: ✅ Insights updated successfully")
            }
        } catch {
            print("Debug: ❌ Error fetching insights:", error)
            print("Debug: 🔍 Detailed error:", (error as NSError).userInfo)
            await MainActor.run {
                errorMessage = "hmm, looks like this page is taking a breather. try returning and refreshing."
                errorTitle = "digital detour"  // Specific title for API errors
            }
        }
    }

    // Helper function to add timeout
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw URLError(.timedOut)
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    // Helper function to format date in a human-readable way
    private func relativeTimeString(from date: Date) -> String {
        let formatter = Foundation.DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}