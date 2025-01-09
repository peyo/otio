import SwiftUI

enum SoundType: String, CaseIterable {
    case harmonicSeries = "Harmonic Series"
    case binauralBeats = "Binaural Beats"
    case pinkNoise = "Pink Noise"
    case isochronicTone = "Isochronic Tone"
}

struct ListeningView: View {
    @Environment(\.dismiss) private var dismiss
    let soundManager = SoundManager()
    @State private var isPlaying = false
    @State private var currentSound: SoundType = .harmonicSeries
    @State private var amplitude: Float = 0.1
    @State private var phase: Double = 0
    private let sampleCount = 100

    var body: some View {
        GeometryReader { geometry in
            VStack {
                // Title and Subtitle at the top
                VStack(spacing: 2) {
                    Text("Meditate")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Catch the wave")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top)
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(Color.appAccent.opacity(0.2), lineWidth: 2)
                        .frame(width: 200, height: 200)
                    
                    WaveformCircle(
                        sampleCount: sampleCount,
                        phase: phase,
                        amplitude: amplitude,
                        color: Color.appAccent
                    )
                    .frame(width: 200, height: 200)
                }
                .frame(height: 200)
                
                Spacer()
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(SoundType.allCases, id: \.self) { sound in
                            SoundCard(sound: sound, isSelected: currentSound == sound) {
                                print("Selected sound: \(sound.rawValue)")
                                currentSound = sound
                                if isPlaying {
                                    soundManager.startSound(type: currentSound)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 20)
                
                Button {
                    toggleSound()
                } label: {
                    Text(isPlaying ? "Stop" : "Start")
                        .foregroundColor(Color.appAccent)
                        .frame(width: geometry.size.width * 0.7, height: 55)
                        .background(Color.appAccent.opacity(0.15))
                        .cornerRadius(16)
                }
                
                Spacer(minLength: 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                startVisualUpdates()
            }
            .onDisappear {
                soundManager.stopAllSounds()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.appAccent)
                    }
                }
            }
        }
    }

    func toggleSound() {
        if isPlaying {
            print("Stopping sound.")
            soundManager.stopAllSounds()
            isPlaying = false
        } else {
            print("Starting sound.")
            soundManager.startSound(type: currentSound)
            isPlaying = true
        }
    }

    func startVisualUpdates() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if isPlaying {
                withAnimation(.linear(duration: 0.1)) {
                    phase += 0.1
                    amplitude = Float.random(in: 0.3...0.6)
                }
            } else {
                amplitude = 0.1
            }
        }
    }
}

struct WaveformCircle: View {
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
        }
    }
}

struct SoundCard: View {
    let sound: SoundType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(sound.rawValue)
                .foregroundColor(.appAccent)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.appAccent.opacity(0.2) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.appAccent, lineWidth: isSelected ? 2 : 0)
                )
        }
        .padding(.horizontal, 4)
    }
}

