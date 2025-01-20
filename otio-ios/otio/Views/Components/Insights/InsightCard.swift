import SwiftUI

struct InsightCard: View {
    let insight: Insight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                Image(insight.emojiName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                Text(insight.title)
                    .font(.custom("NewHeterodoxMono-Book", size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            Text(insight.description)
                .font(.custom("NewHeterodoxMono-Book", size: 15))
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Rectangle()
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
    }
}