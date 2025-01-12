import SwiftUI

enum SoundType: String, CaseIterable {
    case binauralBeats = "binaural beats"
    case pinkNoise = "pink noise"
    case isochronicTone = "isochronic tone"
    case natureSound = "rancheria falls"
}

struct ListeningView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var soundManager = SoundManager.shared
    @State private var isPlaying = false
    @State private var currentSound: SoundType = .binauralBeats
    @State private var amplitude: Float = 0.1
    @State private var phase: Double = 0
    private let sampleCount = 100

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("catch the wave")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 10)
                    
                    Spacer()
                    
                    // Waveform visualization
                    ZStack {
                        Circle()
                            .stroke(Color.appAccent.opacity(0.2), lineWidth: 2)
                            .frame(width: 200, height: 200)
                        
                        DynamicWaveformCircle(
                            sampleCount: sampleCount,
                            phase: phase,
                            amplitude: amplitude,
                            color: Color.appAccent
                        )
                        .frame(width: 200, height: 200)
                    }
                    .frame(height: 200)
                    .offset(y: -20) // Shifted up by y points

                    Spacer() // Add a spacer to push content down
                    
                    // Sound selection cards
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(SoundType.allCases, id: \.self) { sound in
                                SoundCard(sound: sound, isSelected: currentSound == sound) {
                                    currentSound = sound
                                    if isPlaying {
                                        if sound == .natureSound {
                                            soundManager.fetchDownloadURL(for: "2024-09-15-rancheria-falls.wav") { url in
                                                if let url = url {
                                                    soundManager.playAudioFromURL(url)
                                                } else {
                                                    print("Failed to get download URL")
                                                }
                                            }
                                        } else {
                                            soundManager.startSound(type: currentSound)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Play/Stop Button
                    Button(action: toggleSound) {
                        Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.appAccent) // Symbol color
                            .frame(width: 50, height: 50)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(0)
                    }
                    .padding(.top, 30)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("meditate")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.appAccent)
                    }
                }
            }
            .onAppear {
                startVisualUpdates()
            }
            .onDisappear {
                soundManager.stopAllSounds()
            }
        }
    }

    func toggleSound() {
        if isPlaying {
            soundManager.stopAllSounds()
        } else {
            soundManager.startSound(type: currentSound)
        }
        isPlaying.toggle()
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

struct SoundCard: View {
    let sound: SoundType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(sound.rawValue)
                .foregroundColor(.appAccent) // Text color
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    Rectangle()
                        .fill(isSelected ? Color.gray.opacity(0.1) : Color.clear) // Background color\
                        .cornerRadius(0) // Rounded corners
                )
                .overlay(
                    Rectangle()
                        .strokeBorder(isSelected ? Color.appAccent : Color.clear, lineWidth: 2) // Border color
                        .cornerRadius(0) // Rounded corners
                )
        }
        .padding(.horizontal, 4)
    }
}