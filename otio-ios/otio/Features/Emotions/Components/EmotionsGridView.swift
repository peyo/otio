import SwiftUI

struct EmotionsGridView: View {
    let emotionOrder: [String]
    let selectedEmotion: String?
    let onEmotionTap: (String) -> Void
    let geometry: GeometryProxy
    
    var body: some View {
        // Get safe area insets
        let safeAreaInsets = getSafeAreaInsets()
        let leftInset = safeAreaInsets.left
        let rightInset = safeAreaInsets.right
        
        // Calculate available width with safeguards
        let horizontalPadding: CGFloat = 40 // 20 on each side
        let availableWidth = max(geometry.size.width - horizontalPadding - leftInset - rightInset, 10)
        
        // Calculate button size and spacing with safeguards
        let columns: CGFloat = 3
        let totalSpacing = min(availableWidth * 0.15, availableWidth * 0.5) // Cap at 50% of width
        let spacing = max(totalSpacing / max(columns - 1, 1), 5) // Minimum spacing of 5
        let buttonSize = max((availableWidth - totalSpacing) / columns, 30) // Minimum button size of 30
        
        return VStack(alignment: .leading, spacing: spacing) {
            // Create rows dynamically based on the emotion list
            ForEach(0..<(emotionOrder.count + 3 - 1) / 3, id: \.self) { rowIndex in
                HStack(spacing: spacing) {
                    // Create buttons for this row
                    ForEach(0..<min(3, emotionOrder.count - rowIndex * 3), id: \.self) { columnIndex in
                        let index = rowIndex * 3 + columnIndex
                        emotionButton(emotion: emotionOrder[index], size: buttonSize)
                    }
                }
                // Ensure frame width is positive and finite
                .frame(width: availableWidth > 0 ? availableWidth : nil, alignment: .leading)
            }
        }
        .padding(.horizontal, 20)
        .padding(.leading, leftInset)
        .padding(.trailing, rightInset)
    }
    
    // Helper function to get safe area insets
    private func getSafeAreaInsets() -> UIEdgeInsets {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first?.safeAreaInsets ?? .zero
    }
    
    // Helper function to create emotion buttons
    private func emotionButton(emotion: String, size: CGFloat) -> some View {
        Button {
            onEmotionTap(emotion)
        } label: {
            Rectangle()
                .fill(Color.clear)
                // Ensure button dimensions are positive and finite
                .frame(width: size > 0 ? size : 30, height: size > 0 ? size : 30)
                .overlay(
                    Rectangle()
                        .strokeBorder(Color.primary, lineWidth: 1)
                )
                .overlay(
                    VStack(spacing: 4) {
                        Text(emotion)
                            .font(.custom("IBMPlexMono-Light", size: dynamicFontSize(for: emotion)))
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                )
        }
    }
    
    private func dynamicFontSize(for text: String) -> CGFloat {
        switch text.count {
        case 0...10:
            return 14
        default:
            return 12
        }
    }
}