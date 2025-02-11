import SwiftUI

struct EmotionButton: View {
    let type: String
    let isSelected: Bool
    let onTap: () -> Void
    @State private var isHighlighted = false
    
    private func dynamicFontSize(for text: String) -> CGFloat {
        switch text.count {
        case 0...10:
            return 14    // Default size for most words
        default:
            return 12    // Smaller size for words with 11+ characters
        }
    }
    
    var body: some View {
        Button(action: {
            isHighlighted = true
            onTap()
            
            // Reset highlight after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isHighlighted = false
            }
        }) {
            Rectangle()
                .fill(isHighlighted ? Color(.systemGray5) : Color.clear)  // Fill with systemGray5 when selected
                .frame(width: 100, height: 100)
                .overlay(
                    Rectangle()
                        .strokeBorder(Color.primary, lineWidth: 1)  // Primary color adapts to light/dark mode
                )
                .overlay(
                    VStack(spacing: 4) {
                        Text(type)
                            .font(.custom("IBMPlexMono-Light", size: dynamicFontSize(for: type)))
                            .fontWeight(.medium)
                            .foregroundColor(.primary)  // Text color adapts to light/dark mode
                    }
                )
                .animation(.easeInOut(duration: 0.15), value: isHighlighted)
        }
    }
}