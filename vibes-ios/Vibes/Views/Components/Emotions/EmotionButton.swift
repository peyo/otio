import SwiftUI

struct EmotionButton: View {
    let type: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack {
                Image(emojiFor(type))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                Text(type)
                    .font(.custom("NewHeterodoxMono-Book", size: 14))
                    .fontWeight(.medium)
            }
            .frame(width: 100, height: 100)
            .background(Color.forEmotion(type).opacity(0.1))
            .cornerRadius(0)
            .overlay(
                Rectangle()
                    .stroke(isSelected ? Color.forEmotion(type) : .clear, lineWidth: 2)
            )
        }
        .foregroundColor(.primary)
    }
}