import SwiftUI

struct EmotionCard: View {
    let emotion: EmotionData
    let timeString: (Date) -> String

    var body: some View {
        HStack(spacing: 16) {
            // Emoji Square with colored background
            Image(emojiFor(emotion.type))
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .padding(12)  // Add padding back
                .background(
                    Rectangle()
                        .fill(Color.forEmotion(emotion.type).opacity(0.1))
                )

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
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
        .padding()
        .background(
            Rectangle()
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
    }
}
