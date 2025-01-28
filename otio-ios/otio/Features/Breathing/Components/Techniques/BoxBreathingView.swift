import SwiftUI

struct BoxBreathingView: View {
    let phase: BreathingPhase
    let progress: CGFloat
    let isIntroPlaying: Bool
    let isBreathingActive: Bool
    
    private let lineWidth: CGFloat = 2
    private let cornerRadius: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            // Make the box smaller (32% of the smallest screen dimension)
            let size = min(geometry.size.width, geometry.size.height) * 0.32
            
            // Center the box in the view
            let rect = CGRect(
                x: (geometry.size.width - size) / 2,
                y: (geometry.size.height - size) / 2,
                width: size,
                height: size
            )
            
            ZStack {
                // Base box (dimmed) - now with no corner radius
                Rectangle()
                    .stroke(Color.appAccent, lineWidth: lineWidth)
                    .frame(width: size, height: size)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                // Only show animated segment if breathing is active and intro is not playing
                if isBreathingActive && !isIntroPlaying {
                    activeSegment(in: rect)
                        .stroke(Color.appAccent, lineWidth: lineWidth * 2)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        .animation(.linear(duration: 0.3), value: phase)
                        .animation(.linear(duration: 0.3), value: progress)
                }
            }
            .onChange(of: isBreathingActive) { newValue in
                print("Debug: isBreathingActive changed to \(newValue)")
                if newValue {
                    print("Debug: Drawing animated segment - Phase: \(phase), Progress: \(progress)")
                } else {
                    print("Debug: Animation conditions not met - isBreathingActive: \(isBreathingActive), isIntroPlaying: \(isIntroPlaying)")
                }
            }
        }
    }
    
    @ViewBuilder
    private func activeSegment(in rect: CGRect) -> Path {
        Path { path in
            switch phase {
            case .inhale:
                path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.minX, y: progress >= 1.0 ? rect.minY : rect.maxY - (rect.height * progress)))
                
            case .holdAfterInhale:
                path.move(to: CGPoint(x: rect.minX, y: rect.minY))
                path.addLine(to: CGPoint(x: progress >= 1.0 ? rect.maxX : rect.minX + (rect.width * progress), y: rect.minY))
                
            case .exhale:
                path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.maxX, y: progress >= 1.0 ? rect.maxY : rect.minY + (rect.height * progress)))
                
            case .holdAfterExhale:
                path.move(to: CGPoint(x: rect.maxX, y: rect.maxY))
                path.addLine(to: CGPoint(x: progress >= 1.0 ? rect.minX : rect.maxX - (rect.width * progress), y: rect.maxY))
            }
        }
    }
}
