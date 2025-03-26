import SwiftUI

struct FourSevenEightView: View {
    let phase: BreathingPhase
    let progress: CGFloat
    let isIntroPlaying: Bool
    let isBreathingActive: Bool
    
    private let lineWidth: CGFloat = 2
    
    var body: some View {
        GeometryReader { geometry in
            let baseSize = min(geometry.size.width, geometry.size.height) * 0.50
            
            ZStack {
                // Animated circle (no glow effect)
                if isBreathingActive && !isIntroPlaying {
                    Circle()
                        .stroke(Color.primary, lineWidth: lineWidth)
                        .frame(width: calculateSize(baseSize: baseSize), height: calculateSize(baseSize: baseSize))
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        .animation(.linear(duration: 0.3), value: phase)
                        .animation(.linear(duration: 0.3), value: progress)
                } else {
                    // Show small initial circle when not active
                    Circle()
                        .stroke(Color.primary, lineWidth: lineWidth)
                        .frame(width: baseSize * 0.6, height: baseSize * 0.6)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
            }
        }
    }
    
    private func calculateSize(baseSize: CGFloat) -> CGFloat {
        let minSize = baseSize * 0.6 // Circle's smallest size
        let maxSize = baseSize       // Circle's largest size
        let sizeRange = maxSize - minSize
        
        switch phase {
        case .inhale:
            // Expand from min to max size
            return minSize + (sizeRange * progress)
            
        case .holdAfterInhale:
            // Stay at max size
            return maxSize
            
        case .exhale:
            // Contract from max to min size
            return maxSize - (sizeRange * progress)
            
        case .holdAfterExhale:
            // Stay at min size
            return minSize
        }
    }
} 