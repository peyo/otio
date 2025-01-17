import SwiftUI

struct BreathingTechnique: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let pattern: [Int] // Array of seconds for each phase [inhale, hold, exhale, hold]
}

struct BreathingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isActive = false
    @State private var currentTechnique: BreathingTechnique
    @State private var amplitude: Float = 0.1
    @State private var phase: Double = 0
    @State private var elapsedSeconds: Int = 0
    
    private var timerPublisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let sampleCount = 100
    
    private let breathingTechniques = [
        BreathingTechnique(name: "box breathing", pattern: [4,4,4,4]),
        // BreathingTechnique(name: "calm breathing", pattern: [4,7,8,0]),
        // BreathingTechnique(name: "deep breathing", pattern: [4,2,4,0]),
        // Add more techniques as needed
    ]

    init() {
        // Default to box breathing
        _currentTechnique = State(initialValue: BreathingTechnique(name: "box breathing", pattern: [4,4,4,4]))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("find your breath")
                        .font(.custom("NewHeterodoxMono-Book", size: 15))
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.top, 10)
                    
                    Spacer()
                    
                    // Breathing visualization
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
                    .offset(y: -20)

                    // Timer display
                    Text(timeString(from: elapsedSeconds))
                        .font(.custom("NewHeterodoxMono-Book", size: 21))
                        .foregroundColor(.secondary)
                        .padding(.top, 8)

                    Spacer()
                    
                    // Breathing technique cards
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(breathingTechniques) { technique in
                                VStack {
                                    BreathingCard(
                                        technique: technique,
                                        isSelected: currentTechnique.name == technique.name
                                    ) {
                                        if currentTechnique.name != technique.name {
                                            currentTechnique = technique
                                            if isActive {
                                                restartBreathing()
                                            }
                                        }
                                    }
                                    .font(.custom("NewHeterodoxMono-Book", size: 17))
                                }
                                .frame(height: 100)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Start/Stop Button
                    Button(action: toggleBreathing) {
                        Image(systemName: isActive ? "stop.fill" : "play.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.appAccent)
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
                    Text("breathe")
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
                // startVisualUpdates()
            }
            .onReceive(timerPublisher) { _ in
                /* if isPlaying {
                    elapsedSeconds += 1
                } */
            }
        }
    }

    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    private func toggleBreathing() {
        isActive.toggle()
        if !isActive {
            elapsedSeconds = 0
            amplitude = 0.1
        } else {
            startBreathingAnimation()
        }
    }

    private func startBreathingAnimation() {
        // Implement breathing pattern animation
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if isActive {
                withAnimation(.linear(duration: 0.1)) {
                    phase += 0.1
                    // Modify amplitude based on breathing phase
                    // This will need to be coordinated with the breathing pattern
                    amplitude = Float.random(in: 0.3...0.6)
                }
            } else {
                amplitude = 0.1
            }
        }
    }

    private func restartBreathing() {
        isActive = false
        elapsedSeconds = 0
        amplitude = 0.1
        // Additional reset logic as needed
    }
}