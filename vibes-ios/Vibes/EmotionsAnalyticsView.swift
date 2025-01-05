import SwiftUI

struct EmotionsAnalyticsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    var emotions: [EmotionData]
    @State private var insights: [Insight] = []
    @State private var errorMessage: String? // For error handling

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
                } else if insights.isEmpty {
                    let defaultInsight = Insight(emoji: "❓", title: "", description: "Track more to see this week's insights.")
                    InsightCard(insight: defaultInsight)
                } else if let errorMessage = errorMessage {
                    let errorInsight = Insight(emoji: "⚠️", title: "", description: errorMessage)
                    InsightCard(insight: errorInsight)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(insights.indices, id: \.self) { index in
                            InsightCard(insight: insights[index])
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)  // Only padding at the bottom
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
            await fetchInsights()
        }
    }

    private func fetchInsights() async {
        isLoading = true
        defer { isLoading = false }

        guard let url = URL(string: "http://localhost:3000/api/insights") else {
            print("Invalid URL")
            return
        }

        if emotions.isEmpty {
            print("Emotions array is empty. Cannot send request.")
            errorMessage = "No emotions data available to analyze insights. Start logging your emotions!"
            return
        }

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            // Ensure date formatting for the payload
            let isoFormatter = ISO8601DateFormatter()
            let payload: [String: Any] = [
                "emotions": emotions.map { emotion in
                    [
                        "type": emotion.type,
                        "intensity": emotion.intensity,
                        "date": isoFormatter.string(from: emotion.date)
                    ]
                }
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)

            print("Payload sent:", String(data: request.httpBody!, encoding: .utf8) ?? "nil")

            let (data, response) = try await URLSession.shared.data(for: request)

            // Debugging: Print raw response
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code:", httpResponse.statusCode)
            }
            print("Response Data:", String(data: data, encoding: .utf8) ?? "nil")

            let insightsResponse = try JSONDecoder().decode(InsightsResponse.self, from: data)

            guard insightsResponse.success else {
                throw URLError(.badServerResponse)
            }

            let insights = insightsResponse.insights.map { insight in
                Insight(emoji: insight.emoji, title: insight.title, description: insight.description)
            }

            await MainActor.run {
                self.insights = insights
            }
        } catch {
            print("Error fetching insights:", error)
            errorMessage = "Unable to fetch insights at this time. Please try again later."
        }
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
