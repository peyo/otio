import SwiftUI

struct BreathingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var breathManager = BreathManager.shared
    @State private var currentTechnique: BreathingTechnique
    @State private var elapsedSeconds: Int = 0
    
    private let timerPublisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Use the predefined techniques
    private let breathingTechniques = BreathingTechnique.allTechniques

    init() {
        _currentTechnique = State(initialValue: BreathingTechnique.boxBreathing)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("find your breath")
                        .font(.custom("IBMPlexMono-Light", size: 15))
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .padding(.top, 10)
                    
                    Spacer()
                    
                    // Breathing visualization
                    ZStack {
                        switch BreathingVisualization.forTechnique(currentTechnique.type) {
                        case .box:
                            BoxBreathingView(
                                phase: breathManager.currentPhase,
                                progress: breathManager.currentPhaseTimeRemaining <= 0 ? 1.0 : 
                                    1.0 - (CGFloat(breathManager.currentPhaseTimeRemaining) / 
                                    CGFloat(currentTechnique.pattern[Int(breathManager.currentPhase.rawValue)])),
                                isIntroPlaying: breathManager.isIntroPlaying,
                                isBreathingActive: breathManager.isActive
                            )
                        case .circle:
                            FourSevenEightView(
                                phase: breathManager.currentPhase,
                                progress: breathManager.currentPhaseTimeRemaining <= 0 ? 1.0 : 
                                    1.0 - (CGFloat(breathManager.currentPhaseTimeRemaining) / 
                                    CGFloat(currentTechnique.pattern[Int(breathManager.currentPhase.rawValue)])),
                                isIntroPlaying: breathManager.isIntroPlaying,
                                isBreathingActive: breathManager.isActive
                            )
                        }
                    }
                    .frame(width: 200, height: 200)
                    .offset(y: -20)
                    .onChange(of: breathManager.isIntroPlaying) { newValue in
                        print("BreathingView: isIntroPlaying changed to \(newValue)")
                    }

                    // Timer display
                    Text(timeString(from: elapsedSeconds))
                        .font(.custom("IBMPlexMono-Light", size: 21))
                        .foregroundColor(.secondary)
                        .padding(.top, 8)

                    Spacer()
                    
                    // Breathing technique cards
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(breathingTechniques) { technique in
                                BreathingCard(
                                    technique: technique,
                                    isSelected: currentTechnique.type == technique.type
                                ) {
                                    if currentTechnique.type != technique.type {
                                        currentTechnique = technique
                                        if breathManager.isActive {
                                            restartBreathing()
                                        }
                                    }
                                }
                                .font(.custom("IBMPlexMono-Light", size: 17))
                                .frame(height: 100)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Start/Stop Button
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
                        .font(.custom("IBMPlexMono-Light", size: 22))
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
