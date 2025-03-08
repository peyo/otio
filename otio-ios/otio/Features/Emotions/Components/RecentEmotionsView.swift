import SwiftUI
import Foundation

struct RecentEmotionsView: View {
    let isLoading: Bool
    let recentEmotions: [EmotionData]
    let timeString: (Date) -> String
    let onDelete: (EmotionData) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("recent")
                .font(.custom("IBMPlexMono-Light", size: 17))
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(.primary)
                    Spacer()
                }
            } else if recentEmotions.isEmpty {
                HStack(spacing: 16) {
                    Image(systemName: "leaf.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40)
                        .foregroundColor(.primary)
                    
                    Text("track your first emotion to see it here.")
                        .font(.custom("IBMPlexMono-Light", size: 15))
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding()
                .background(Color.appCardBackground)
            } else {
                VStack(spacing: 16) {
                    ForEach(recentEmotions) { emotion in
                        EmotionCard(
                            emotion: emotion,
                            timeString: timeString,
                            onDelete: { onDelete(emotion) }
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.leading, UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first?.safeAreaInsets.left ?? 0)
        .padding(.trailing, UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first?.safeAreaInsets.right ?? 0)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}