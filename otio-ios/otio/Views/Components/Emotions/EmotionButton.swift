import SwiftUI

struct EmotionButton: View {
    let type: String
    let isSelected: Bool
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: onTap) {
            VStack {
                Image(emojiFor(type))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .brightness(colorScheme == .dark ? 1 : 0)
                Text(type)
                    .font(.custom("NewHeterodoxMono-Book", size: 14))
                    .fontWeight(.medium)
            }
            .frame(width: 100, height: 100)
            .background(Color.forEmotion(type))
            .overlay(
                Rectangle()
                    .stroke(isSelected ? Color.forEmotion(type) : .clear, lineWidth: 2)
            )
        }
        .foregroundColor(.primary)
    }
}