import SwiftUI

struct BreathingCard: View {
    let technique: BreathingTechnique
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(technique.name)
                .foregroundColor(.appAccent)
                .padding()
                .background(
                    Rectangle()
                        .fill(isSelected ? Color.gray.opacity(0.1) : Color.clear)
                        .cornerRadius(0)
                )
                .overlay(
                    Rectangle()
                        .strokeBorder(isSelected ? Color.appAccent : Color.clear, lineWidth: 2)
                        .cornerRadius(0)
                )
        }
        .padding(.horizontal, 4)
    }
}