import SwiftUI

struct ListeningView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var soundManager = SoundManager.shared
    @State private var isPlaying = false
    @State private var currentSound: SoundType
    @State private var amplitude: Float = 0.1
    @State private var phase: Double = 0
    private let sampleCount = 100
    private let normalizedScore: Double

    init(normalizedScore: Double) {
        self.normalizedScore = normalizedScore
        _currentSound = State(initialValue: SoundType.recommendedSound)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("catch the wave")
                        .font(.custom("NewHeterodoxMono-Book", size: 15))
                        .fontWeight(.medium)
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
                                VStack {
                                    SoundCard(sound: sound, isSelected: currentSound == sound) {
                                        if currentSound != sound {
                                            currentSound = sound
                                            if isPlaying {
                                                soundManager.stopAllSounds()
                                                startCurrentSound()
                                            }
                                        }
                                    }
                                    .font(.custom("NewHeterodoxMono-Book", size: 17))
                                }
                                .frame(height: 100) // Ensure consistent height
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
                        .font(.custom("NewHeterodoxMono-Book", size: 22))
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
            startCurrentSound()
        }
        isPlaying.toggle()
    }

    func startCurrentSound() {
        if currentSound == .recommendedSound {
            soundManager.startSound(type: determineRecommendedSound(from: normalizedScore), normalizedScore: normalizedScore)
        } else {
            soundManager.startSound(type: currentSound)
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
