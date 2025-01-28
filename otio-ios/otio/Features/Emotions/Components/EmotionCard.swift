import SwiftUI

struct EmotionCard: View {
    let emotion: EmotionData
    let timeString: (Date) -> String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 24) {
                Image(emojiFor(emotion.type))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .brightness(colorScheme == .dark ? 1 : 0)  // Make white in dark mode
                    .background(
                        Rectangle()
                            .fill(Color.forEmotion(emotion.type))
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
                .fill(Color.appCardBackground)
        )
    }
}
