import SwiftUI
import Charts

struct EmotionsAnalyticsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTimeframe: DateRange = .week
    @State private var isLoading = false
    @State private var emotions: [EmotionData] = []
    @State private var insights: [Insight] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Modern title with subtitle
                VStack(spacing: 6) {
                    Text("Your emotional journey")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .padding(.top, 20)
                .frame(maxWidth: .infinity)
                
                // Modern Rectangular Segmented Picker
                HStack(spacing: 8) {
                    ForEach(DateRange.allCases, id: \.self) { timeframe in
                        Button {
                            withAnimation {
                                selectedTimeframe = timeframe
                            }
                        } label: {
                            Text(timeframe.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedTimeframe == timeframe ? 
                                             Color.appAccent : Color.clear)
                                )
                                .foregroundColor(selectedTimeframe == timeframe ? 
                                               .white : .secondary)
                        }
                    }
                }
                .padding(3)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                
                // Insights Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Insights")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else if insights.isEmpty {
                        Text(emptyMessageFor(timeframe: selectedTimeframe))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(insights) { insight in
                                InsightCard(insight: insight)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
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
        .onChange(of: selectedTimeframe) { oldValue, newValue in
            Task {
                await fetchInsights()
            }
        }
        .task {
            await fetchInsights()
        }
    }
    
    private func emptyMessageFor(timeframe: DateRange) -> String {
        switch timeframe {
        case .day: return "Your daily insights will show up here"
        case .week: return "Track more to see this week's insights"
        case .month: return "No monthly insights yet"
        }
    }
    
    private func fetchInsights() async {
        isLoading = true
        defer { isLoading = false }
        
        // 1. Fetch emotions from your API
        guard let emotionsUrl = URL(string: "http://localhost:3000/api/emotions") else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: emotionsUrl)
            let decoder = JSONDecoder()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            decoder.dateDecodingStrategy = .formatted(formatter)
            
            let response = try decoder.decode(EmotionsResponse.self, from: data)
            emotions = filterEmotions(response.data, for: selectedTimeframe)
            
            // 2. Generate prompt for OpenAI
            let prompt = generatePrompt(for: emotions, timeframe: selectedTimeframe)
            
            // 3. Call OpenAI API
            let aiInsights = try await fetchAIInsights(prompt: prompt)
            
            // 4. Update UI
            await MainActor.run {
                self.insights = aiInsights
            }
        } catch {
            print("Error fetching insights:", error)
        }
    }
    
    private func generatePrompt(for emotions: [EmotionData], timeframe: DateRange) -> String {
        let emotionSummary = emotions.map { "- \($0.type) (Intensity: \($0.intensity)) at \($0.date)" }
            .joined(separator: "\n")
        
        return """
        Based on the following emotional data for the past \(timeframe.rawValue.lowercased()):
        
        \(emotionSummary)
        
        Generate 3 meaningful insights about the emotional patterns. Each insight should:
        1. Be encouraging and supportive
        2. Focus on patterns and trends
        3. Provide gentle suggestions when relevant
        4. Be concise (max 2 sentences)
        5. Include an appropriate emoji
        
        Format each insight as: emoji|title|description
        """
    }
    
    private func fetchAIInsights(prompt: String) async throws -> [Insight] {
        // TODO: Replace with actual OpenAI API call
        guard let url = URL(string: "http://localhost:3000/api/analyze") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = ["prompt": prompt]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(AIResponse.self, from: data)
        
        return response.insights.map { Insight(
            emoji: $0.emoji,
            title: $0.title,
            description: $0.description
        )}
    }
    
    private func filterEmotions(_ emotions: [EmotionData], for timeframe: DateRange) -> [EmotionData] {
        let calendar = Calendar.current
        let now = Date()
        
        return emotions.filter { emotion in
            switch timeframe {
            case .day:
                return calendar.isDate(emotion.date, inSameDayAs: now)
            case .week:
                let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
                return emotion.date >= weekAgo
            case .month:
                let monthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
                return emotion.date >= monthAgo
            }
        }
    }
}

struct InsightCard: View {
    let insight: Insight
    
    var body: some View {
        HStack(spacing: 16) {
            // Emoji Circle
            Text(insight.emoji)
                .font(.title)
                .padding(12)
                .background(
                    Circle()
                        .fill(Color.appAccent.opacity(0.1))
                )
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .fontWeight(.medium)
                
                Text(insight.description)
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

// Insight Model
struct Insight: Identifiable, Equatable {
    let id = UUID()
    let emoji: String
    let title: String
    let description: String
    
    // Required for Equatable when using UUID
    static func == (lhs: Insight, rhs: Insight) -> Bool {
        lhs.emoji == rhs.emoji &&
        lhs.title == rhs.title &&
        lhs.description == rhs.description
    }
}

// Add this struct to handle AI API response
struct AIResponse: Codable {
    struct AIInsight: Codable {
        let emoji: String
        let title: String
        let description: String
    }
    
    let insights: [AIInsight]
}

#Preview {
    NavigationStack {
        EmotionsAnalyticsView()
    }
} 