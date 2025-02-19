import SwiftUI
import Combine

struct ResonanceView: View {
    let breathingPhase: BreathingPhase
    let progress: CGFloat
    let isIntroPlaying: Bool
    let isBreathingActive: Bool
    
    // Animation properties
    @State private var phase: CGFloat = 0
    @State private var isAnimating: Bool = false
    
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
                .offset(x: horizontalOffset, y: phase)
                .onChange(of: isBreathingActive) { active in
                    if !active {
                        stopAnimation()
                    }
                }
                .onChange(of: isIntroPlaying) { playing in
                    if !playing && isBreathingActive {
                        startAnimation()
                    }
                }
                .onChange(of: breathingPhase) { newPhase in
                    updateAnimation(for: newPhase)
                }
        }
    }
    
    private func startAnimation() {
        print("ResonanceView: Starting animation")
        // Start with inhale (moving up)
        phase = 0
        
        // Immediately start moving up for inhale
        withAnimation(.easeInOut(duration: 5)) {
            phase = -verticalOffset
        }
        
        isAnimating = true
        print("ResonanceView: Animation started - moving up")
    }
    
    private func updateAnimation(for phase: BreathingPhase) {
        guard isBreathingActive && !isIntroPlaying else { return }
        
        print("ResonanceView: Updating animation for phase: \(phase)")
        
        switch phase {
        case .inhale:
            withAnimation(.easeInOut(duration: 5)) {
                self.phase = -verticalOffset  // Move up
            }
            print("ResonanceView: Moving up for inhale")
        case .exhale:
            withAnimation(.easeInOut(duration: 5)) {
                self.phase = 0  // Move down
            }
            print("ResonanceView: Moving down for exhale")
        case .holdAfterInhale, .holdAfterExhale:
            // No animation during hold phases
            print("ResonanceView: Hold phase - maintaining position")
            break
        }
    }
    
    private func stopAnimation() {
        print("ResonanceView: Stopping animation")
        isAnimating = false
        withAnimation(.linear(duration: 0.3)) {
            phase = 0
        }
        print("ResonanceView: Animation stopped")
    }
}

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