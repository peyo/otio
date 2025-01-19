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
    @State private var currentTask: Task<Void, Never>?
    @State private var cooldownTime: Int = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    // Pull to refresh with cooldown check
                    RefreshControl(
                        coordinateSpace: .named("refresh"),
                        onRefresh: fetchInsights,
                        isInCooldown: cooldownTime > 0
                    )
                    
                    VStack(spacing: 24) {
                        // Subtitle only
                        Text("navigate your emotions")
                            .font(.custom("NewHeterodoxMono-Book", size: 15))
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .padding(.top, 0)
                        
                        if isLoading {
                            VStack {
                                Spacer()
                                ProgressView()
                                    .tint(.appAccent)
                                Spacer()
                            }
                            .frame(height: geometry.size.height * 0.7)
                        } else if emotions.isEmpty {
                            EmptyStateView()
                        } else {
                            // Insights content
                            VStack(spacing: 16) {
                                if let errorMessage = errorMessage {
                                    let errorInsight = Insight(
                                        emojiName: "zen",
                                        title: "digital detour",
                                        description: errorMessage
                                    )
                                    InsightCard(insight: errorInsight)
                                } else {
                                    ForEach(insights.prefix(3), id: \.self) { insight in
                                        InsightCard(insight: insight)
                                    }
                                    
                                    if cooldownTime > 0 {
                                        Text("next insights available in: \(cooldownTime / 3600)h \((cooldownTime % 3600) / 60)m")
                                            .font(.custom("NewHeterodoxMono-Book", size: 13))
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                            .padding(.top, 8)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .coordinateSpace(name: "refresh")
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("understand")
                        .font(.custom("NewHeterodoxMono-Book", size: 22))
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
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
    }

    private func fetchInsights() async {
        isLoading = true
        defer { isLoading = false }

        // Check for cancellation
        if Task.isCancelled { return }

        // Check authentication first
        guard let user = Auth.auth().currentUser else {
            print("Debug: ❌ No authenticated user")
            errorMessage = "please sign in to view insights."
            return
        }

        if emotions.isEmpty {
            print("Debug: ⚠️ no emotions to analyze")
            errorMessage = "no emotions data available to analyze insights. start logging your feelings."
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
                }
                print("Debug: ✅ Insights updated successfully")
            }
        } catch {
            print("Debug: ❌ Error fetching insights:", error)
            print("Debug: 🔍 Detailed error:", (error as NSError).userInfo)
            errorMessage = "hmm, looks like this page is taking a breather. try returning and refreshing."
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

    private struct EmptyStateView: View {
        var body: some View {
            VStack(spacing: 16) {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.system(size: 40))
                    .foregroundColor(.appAccent)
                
                Text("no emotions to analyze")
                    .font(.custom("NewHeterodoxMono-Book", size: 17))
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("start tracking your emotions to get insights about your emotional patterns.")
                    .font(.custom("NewHeterodoxMono-Book", size: 15))
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                Rectangle()
                    .fill(Color(.systemBackground))
            )
            .padding(.horizontal)
        }
    }
}
