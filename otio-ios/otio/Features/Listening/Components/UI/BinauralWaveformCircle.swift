import SwiftUI

struct BinauralWaveformCircle: View {
    let sampleCount: Int
    let spectrumData: [Float]  // [low, mid, high] frequency bands
    let color: Color
    
    // Animation state
    @State private var phase: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let radius = size / 2
            
            // Single waveform circle that responds to frequency bands
            Path { path in
                // Log spectrum data periodically
                if let firstPoint = path.currentPoint, firstPoint == .zero {
                    print("Visualization update:")
                    print("- Low mod: \(String(format: "%.3f", Double(spectrumData[0]) * 0.3))")
                    print("- Mid mod: \(String(format: "%.3f", Double(spectrumData[1]) * 0.2))")
                    print("- High mod: \(String(format: "%.3f", Double(spectrumData[2]) * 0.1))")
                }
                
                for i in 0..<sampleCount {
                    let angle = (Double(i) / Double(sampleCount)) * 2 * .pi
                    
                    // Use different frequency bands to modulate the wave
                    let lowMod = Double(spectrumData[0]) * sin(angle * 2 + phase) * 0.3
                    let midMod = Double(spectrumData[1]) * sin(angle * 4 + phase) * 0.2
                    let highMod = Double(spectrumData[2]) * sin(angle * 8 + phase) * 0.1
                    
                    // Combine modulations
                    let totalMod = lowMod + midMod + highMod
                    
                    // Calculate point with frequency-based modulation
                    let x = cos(angle) * Double(radius * 0.3) * (1.0 + totalMod)
                    let y = sin(angle) * Double(radius * 0.3) * (1.0 + totalMod)
                    
                    let point = CGPoint(
                        x: radius + CGFloat(x),
                        y: radius + CGFloat(y)
                    )
                    
                    if i == 0 {
                        path.move(to: point)
                    } else {
                        path.addLine(to: point)
                    }
                }
                path.closeSubpath()
            }
            .stroke(color.opacity(0.8), lineWidth: 2)
            .frame(width: size, height: size)
            .position(x: geometry.size.width/2, y: geometry.size.height/2)
            .onAppear {
                print("Visualization view appeared")
                // Animate continuously
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    phase = 2 * .pi
                }
            }
        }
    }
}