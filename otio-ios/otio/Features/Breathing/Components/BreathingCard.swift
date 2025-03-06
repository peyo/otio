import SwiftUI

struct BreathingCard: View {
    let technique: BreathingTechnique
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(technique.name)
                .foregroundColor(.appAccent) // Text color
                .font(.custom("IBMPlexMono-Light", size: 15))
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    Rectangle()
                        .fill(isSelected ? Color(.systemGray5) : Color.clear)
                )
                .overlay(
                    Rectangle()
                        .strokeBorder(isSelected ? Color.appAccent : Color.clear, lineWidth: 1)
                )
        }
        .padding(.horizontal, 4)
    }
}