import SwiftUI

struct InsightCard: View {
    let insight: Insight
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                Image(systemName: InsightSymbol.sfSymbol(for: insight.emojiName))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundColor(.primary)
                Text(insight.title)
                    .font(.custom("IBMPlexMono-Light", size: 15))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            Text(insight.description)
                .font(.custom("IBMPlexMono-Light", size: 15))
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Rectangle()
                .fill(Color.appCardBackground)
        )
    }
}