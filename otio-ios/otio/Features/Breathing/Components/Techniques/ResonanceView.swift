import SwiftUI
import Combine

struct ResonanceView: View {
    let breathingPhase: BreathingPhase
    let progress: CGFloat
    let isIntroPlaying: Bool
    let isBreathingActive: Bool
    
    // Wave configuration
    private let amplitude: CGFloat = 32
    private let periodMultiplier: CGFloat = 2.0
    private let waveEndPoint: CGFloat = 0.67
    private let verticalOffset: CGFloat = 50
    
    var body: some View {
        GeometryReader { geometry in
            let waveWidth = geometry.size.width * waveEndPoint
            let horizontalOffset = (geometry.size.width - waveWidth) / 2
            
            WavePath(size: geometry.size, 
                    amplitude: amplitude, 
                    periodMultiplier: periodMultiplier,
                    endPoint: waveEndPoint)
                .stroke(Color.white, lineWidth: 2)
                .offset(x: horizontalOffset, y: calculatePosition())
                .animation(.easeInOut(duration: 2.0), value: progress)
                .animation(.easeInOut(duration: 2.0), value: breathingPhase)
                .animation(.easeInOut(duration: 1.5), value: isBreathingActive)
        }
    }
    
    private func calculatePosition() -> CGFloat {
        // Always return to bottom when not active
        guard isBreathingActive else {
            return verticalOffset
        }
        
        // Stay at bottom during intro
        guard !isIntroPlaying else {
            return verticalOffset
        }
        
        switch breathingPhase {
        case .inhale:
            // Move from bottom to top
            return verticalOffset - (progress * verticalOffset * 2)
        case .exhale:
            // Move from top to bottom
            return -verticalOffset + (progress * verticalOffset * 2)
        case .holdAfterInhale:
            return -verticalOffset // Stay at top
        case .holdAfterExhale:
            return verticalOffset  // Stay at bottom
        }
    }
}

// Keep WavePath struct unchanged
struct WavePath: Shape {
    let size: CGSize
    let amplitude: CGFloat
    let periodMultiplier: CGFloat
    let endPoint: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let endX = size.width * endPoint
        let points = stride(from: 0, through: endX, by: 1).map { x -> CGPoint in
            let progress = x / endX
            let y = size.height/2 - amplitude * sin(.pi * 2 * progress * periodMultiplier)
            return CGPoint(x: x, y: y)
        }
        
        if let firstPoint = points.first {
            path.move(to: firstPoint)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }
        
        return path
    }
}