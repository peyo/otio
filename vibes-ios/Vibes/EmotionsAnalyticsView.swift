import SwiftUI
import FirebaseFunctions
import FirebaseCore
import FirebaseAuth

struct EmotionsAnalyticsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    let emotions: [EmotionData]
    @State private var insights: [Insight] = []
    @State private var errorMessage: String? // For error handling
    @State private var currentTask: Task<Void, Never>?
    @State private var cooldownTime: Int = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Title and Subtitle
                VStack(spacing: 2) {
                    Text("Insights")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Your emotional journey")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                // Insights Section
                if isLoading {
                    ProgressView()
                        .tint(.appAccent)
                        .frame(maxWidth: .infinity)
                } else if let errorMessage = errorMessage {
                    let errorInsight = Insight(
                        emoji: "⚠️",
                        title: "",
                        description: errorMessage
                    )
                    InsightCard(insight: errorInsight)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(insights.prefix(3), id: \.self) { insight in
                            InsightCard(insight: insight)
                        }
                    }
                }
                
                if cooldownTime > 0 {
                    Text("Next insights available in: \(cooldownTime / 3600)h \((cooldownTime % 3600) / 60)m")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.appAccent)
                }
            }
        }
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

    private func fetchInsights() async {
        isLoading = true
        defer { isLoading = false }

        // Check for cancellation
        if Task.isCancelled { return }

        // Check authentication first
        guard let user = Auth.auth().currentUser else {
            print("Debug: ❌ No authenticated user")
            errorMessage = "Please sign in to view insights"
            return
        }

        if emotions.isEmpty {
            print("Debug: ⚠️ No emotions to analyze")
            errorMessage = "No emotions data available to analyze insights. Start logging your emotions."
            return
        }

        do {
            // Get a fresh token first
            let token = try await user.getIDToken(forcingRefresh: true)
            print("Debug: 🎫 Using fresh token:", token.prefix(20))
            
            // Create a new Functions instance for each call
            let functions = Functions.functions(app: FirebaseApp.app()!, region: "us-central1")
            
            // Format emotions
            let formattedEmotions = emotions.map { emotion in
                [
                    "type": emotion.type,
                    "intensity": emotion.intensity,
                    "date": relativeTimeString(from: emotion.date)
                ]
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
                    emoji: dict["emoji"] as? String ?? "❓",
                    title: dict["title"] as? String ?? "",
                    description: dict["description"] as? String ?? ""
                )
            }
            
            print("Debug: ✅ Processed \(insights.count) insights")
            
            await MainActor.run {
                self.insights = insights
                self.cooldownTime = cooldownRemainingMs / 1000  // Convert milliseconds to seconds
                self.errorMessage = nil
                print("Debug: ✅ Insights updated successfully")
            }
        } catch {
            print("Debug: ❌ Error fetching insights:", error)
            print("Debug: 🔍 Detailed error:", (error as NSError).userInfo)
            errorMessage = "Unable to fetch insights at this time. Please try again later."
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
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    struct InsightCard: View {
        let insight: Insight
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(insight.emoji)
                        .font(.title2)
                    Text(insight.title)
                        .font(.headline)
                }
                
                Text(insight.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
            )
        }
    }
}
