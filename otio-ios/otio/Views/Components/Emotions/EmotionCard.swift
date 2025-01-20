import SwiftUI

struct EmotionCard: View {
    let emotion: EmotionData
    let timeString: (Date) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 16) {
                Image(emojiFor(emotion.type))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .background(
                        Rectangle()
                            .fill(Color.forEmotion(emotion.type).opacity(0.1))
                            .frame(width: 52, height: 52)  // Fixed size background
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(emotion.type)
                            .font(.custom("NewHeterodoxMono-Book", size: 15))
                            .fontWeight(.semibold)
                        if emotion.type != "balanced" {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text("intensity \(emotion.intensity)")
                                .font(.custom("NewHeterodoxMono-Book", size: 15))
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }

                    Text(timeString(emotion.date))
                        .font(.custom("NewHeterodoxMono-Book", size: 15))
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Rectangle()
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
    }
}
