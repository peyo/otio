import SwiftUI
import Charts

struct EmotionsAnalyticsView: View {
    @State private var timeframe = "Week"
    private let timeframes = ["Day", "Week", "Month"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Modern title with subtitle
                VStack(spacing: 6) {
                    Text("Insights")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Your emotional journey")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                .frame(maxWidth: .infinity)
                
                VStack(spacing: 24) {
                    // Timeframe picker
                    Picker("Timeframe", selection: $timeframe) {
                        ForEach(timeframes, id: \.self) { timeframe in
                            Text(timeframe)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    // Show insights based on selected timeframe
                    Group {
                        switch timeframe {
                        case "Day":
                            InsightCard(insights: dayInsights)
                        case "Week":
                            InsightCard(insights: weekInsights)
                        case "Month":
                            InsightCard(insights: monthInsights)
                        default:
                            EmptyView()
                        }
                    }
                }
                .padding(.horizontal)  // Single padding for both picker and card
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // Separated insights into computed properties for better organization
    private var dayInsights: [Insight] {
        [
            Insight(
                emoji: "😊",
                title: "Positive Start",
                description: "You began your day with happiness"
            ),
            Insight(
                emoji: "⚖️",
                title: "Balanced Emotions",
                description: "You're maintaining good emotional balance today"
            )
        ]
    }
    
    private var weekInsights: [Insight] {
        [
            Insight(
                emoji: "📈",
                title: "Improving Trend",
                description: "Your anxiety levels have decreased this week"
            ),
            Insight(
                emoji: "🌅",
                title: "Morning Person",
                description: "You tend to feel most positive in the mornings"
            ),
            Insight(
                emoji: "💪",
                title: "Great Progress",
                description: "You've been consistent in tracking your emotions"
            )
        ]
    }
    
    private var monthInsights: [Insight] {
        [
            Insight(
                emoji: "🎯",
                title: "Pattern Detected",
                description: "You handle stress better on weekdays"
            ),
            Insight(
                emoji: "🌟",
                title: "Achievement",
                description: "This is your most balanced month so far"
            )
        ]
    }
}

struct InsightCard: View {
    let insights: [Insight]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(insights) { insight in
                HStack(alignment: .top, spacing: 16) {
                    Text(insight.emoji)
                        .font(.title2)
                        .frame(width: 40, alignment: .center)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(insight.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(insight.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                }
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(
                    color: Color.black.opacity(0.03),
                    radius: 10,
                    x: 0,
                    y: 2
                )
        )
        .animation(.easeInOut, value: insights)
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

#Preview {
    EmotionsAnalyticsView()
} 