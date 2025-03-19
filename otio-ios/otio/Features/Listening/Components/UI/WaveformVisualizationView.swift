import SwiftUI

struct WaveformVisualizationView: View {
    let sampleCount: Int
    let phase: Double
    let amplitude: Float
    let geometry: GeometryProxy
    let elapsedSeconds: Int
    
    var body: some View {
        VStack(spacing: 32) {
            ZStack {
                DynamicWaveformCircle(
                    sampleCount: sampleCount,
                    phase: phase,
                    amplitude: amplitude,
                    color: Color.primary
                )
            }
            .frame(width: min(200, geometry.size.width * 0.5),
                   height: min(200, geometry.size.width * 0.5))
            .offset(y: -geometry.size.height * 0.02)
            
            // Timer display
            Text(timeString(from: elapsedSeconds))
                .font(.custom("IBMPlexMono-Light", size: 21))
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}