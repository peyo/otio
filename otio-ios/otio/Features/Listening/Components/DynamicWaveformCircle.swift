import SwiftUI

struct DynamicWaveformCircle: View {
    let sampleCount: Int
    let phase: Double
    let amplitude: Float
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let radius = size / 2
            Path { path in
                for i in 0..<sampleCount {
                    let angle = (Double(i) / Double(sampleCount)) * 2 * .pi
                    let x = cos(angle)
                    let y = sin(angle)
                    let waveAmplitude = Double(amplitude) * sin(angle * 8 + phase)
                    let point = CGPoint(
                        x: radius + CGFloat(x * (1 + waveAmplitude)) * radius * 0.3,
                        y: radius + CGFloat(y * (1 + waveAmplitude)) * radius * 0.3
                    )
                    
                    if i == 0 {
                        path.move(to: point)
                    } else {
                        path.addLine(to: point)
                    }
                }
                path.closeSubpath()
            }
            .stroke(color, lineWidth: 2)
            .frame(width: size, height: size)
            .position(x: geometry.size.width/2, y: geometry.size.height/2)
            .animation(.easeInOut(duration: 0.5), value: amplitude) // Add animation
        }
    }
}