import SwiftUI

struct BreathingTechnique: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let pattern: [Int] // Array of seconds for each phase [inhale, hold, exhale, hold]
    let introAudioFile: String? // Name of the intro audio file
    
    static let boxBreathing = BreathingTechnique(
        name: "box breathing",
        pattern: [4,4,4,4],
        introAudioFile: "box-breathing-intro.wav"
    )
}

struct BreathingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var breathManager = BreathManager.shared
    @State private var currentTechnique: BreathingTechnique
    @State private var elapsedSeconds: Int = 0
    
    private let timerPublisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private let breathingTechniques = [
        BreathingTechnique(
            name: "box breathing", 
            pattern: [4,4,4,4],
            introAudioFile: "box-breathing-intro.wav"
        )
    ]

    init() {
        _currentTechnique = State(initialValue: BreathingTechnique(
            name: "box breathing", 
            pattern: [4,4,4,4],
            introAudioFile: "box-breathing-intro.wav"
        ))
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
                        .foregroundColor(.primary)
                        .padding(.top, 10)
                    
                    Spacer()
                    
                    // Breathing visualization
                    ZStack {
                        /* Circle()
                            .stroke(Color.appAccent.opacity(0.2), lineWidth: 2)
                            .frame(width: 200, height: 200)
                        */
                        
                        // Inner box breathing animation
                        BoxBreathingView(
                            phase: breathManager.currentPhase,
                            progress: breathManager.currentPhaseTimeRemaining <= 0 ? 1.0 : 
                                1.0 - (CGFloat(breathManager.currentPhaseTimeRemaining) / 
                                CGFloat(currentTechnique.pattern[Int(breathManager.currentPhase.rawValue)])),
                            isIntroPlaying: breathManager.isIntroPlaying,
                            isBreathingActive: breathManager.isActive
                        )
                        .frame(width: 200, height: 200)
                    }
                    .frame(height: 200)
                    .offset(y: -20)
                    .onChange(of: breathManager.isIntroPlaying) { newValue in
                        print("BreathingView: isIntroPlaying changed to \(newValue)")
                    }

                    // Timer display
                    Text(timeString(from: elapsedSeconds))
                        .font(.custom("NewHeterodoxMono-Book", size: 21))
                        .foregroundColor(.secondary)
                        .padding(.top, 8)

                    Spacer()
                    
                    // Breathing technique cards
                    if breathingTechniques.count == 1 {
                        // Single card - centered with content-based width
                        HStack {
                            Spacer()
                            BreathingCard(
                                technique: breathingTechniques[0],
                                isSelected: currentTechnique.name == breathingTechniques[0].name
                            ) {
                                if currentTechnique.name != breathingTechniques[0].name {
                                    currentTechnique = breathingTechniques[0]
                                    if breathManager.isActive {
                                        restartBreathing()
                                    }
                                }
                            }
                            .font(.custom("NewHeterodoxMono-Book", size: 17))
                            .frame(height: 100)
                            Spacer()
                        }
                        .padding(.horizontal)
                    } else {
                        // Multiple cards - scrollable, left-aligned
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
                                                if breathManager.isActive {
                                                    restartBreathing()
                                                }
                                            }
                                        }
                                        .font(.custom("NewHeterodoxMono-Book", size: 17))
                                    }
                                    .frame(height: 100)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Start/Stop Button - centered with content-based width
                    Button(action: toggleBreathing) {
                        Image(systemName: breathManager.isActive ? "stop.fill" : "play.fill")
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
                        .foregroundColor(.primary)
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
                if breathManager.isActive {
                    elapsedSeconds += 1
                }
            }
        }
        .onDisappear {
            breathManager.stopBreathing()
            // Force a cleanup of the sound manager
            SoundManager.shared.stopAllAudio()
        }
    }

    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    private func toggleBreathing() {
        print("BreathingView: toggleBreathing called")
        if breathManager.isActive {
            print("BreathingView: stopping breathing exercise")
            breathManager.stopBreathing()
            elapsedSeconds = 0
        } else {
            print("BreathingView: starting breathing exercise")
            breathManager.startBreathing(technique: currentTechnique)
        }
    }

    private func restartBreathing() {
        breathManager.stopBreathing()
        elapsedSeconds = 0
    }
}
