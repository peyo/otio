import SwiftUI

struct BreathingCard: View {
    let technique: BreathingTechnique
    let isSelected: Bool
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        // Keep the current dimensions but add the emotion button styling
        VStack(alignment: .center, spacing: 8) {
            Text(technique.name)
                .font(.custom("IBMPlexMono-Light", size: 15))
                .fontWeight(.medium)
                .foregroundColor(isSelected || isPressed ? Color.secondary : Color.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .frame(height: 50)  // Keep the height consistent
        .background(Color.clear)  // Always clear background, removing the highlight
        .overlay(
            Rectangle()
                .strokeBorder(isSelected || isPressed ? Color.secondary : Color.primary, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    // User is pressing down
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    // User released
                    isPressed = false
                    onTap()  // Trigger the action when released
                }
        )
        .padding(.horizontal, 4)
    }
}