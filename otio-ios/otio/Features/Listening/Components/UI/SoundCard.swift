import SwiftUI

struct SoundCard: View {
    let sound: SoundType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(sound.rawValue)
                .foregroundColor(.primary) // Text color
                .font(.custom("IBMPlexMono-Light", size: 15))
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    Rectangle()
                        .fill(isSelected ? Color(.systemGray5) : Color.clear) // Background color
                )
                .overlay(
                    Rectangle()
                        .strokeBorder(isSelected ? Color.primary : Color.clear, lineWidth: 1) // Border color
                )
        }
        .padding(.horizontal, 4)
    }
}