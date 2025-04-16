import SwiftUI

struct EmotionButton: View {
    let emotion: String
    let isSelected: Bool
    let onTap: () -> Void
    @State private var isPressed = false
    
    private func dynamicFontSize(for text: String) -> CGFloat {
        switch text.count {
        case 0...10:
            return 14    // Default size for most words
        default:
            return 12    // Smaller size for words with 11+ characters
        }
    }
    
    var body: some View {
        Rectangle()
            .fill(isPressed ? Color.appCardBackground : Color.clear)
            .frame(width: 100, height: 100)
            .overlay(
                Rectangle()
                    .strokeBorder(isPressed ? Color.secondary : Color.primary, lineWidth: 1)
            )
            .overlay(
                VStack(spacing: 4) {
                    Text(emotion)
                        .font(.custom("IBMPlexMono-Light", size: dynamicFontSize(for: emotion)))
                        .fontWeight(.medium)
                        .foregroundColor(isPressed ? Color.secondary : Color.primary)
                }
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
    }
}
