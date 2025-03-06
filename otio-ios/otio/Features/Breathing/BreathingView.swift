import SwiftUI

struct BreathingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var breathManager = BreathManager.shared
    @StateObject private var userService = UserService.shared
    @State private var currentTechnique: BreathingTechnique
    @State private var elapsedSeconds: Int = 0
    @State private var isInitializing = true  // Add loading state
    
    private let timerPublisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let breathingTechniques = BreathingTechnique.allTechniques

    init() {
        print("🟡 BreathingView init started: \(Date())")
        _currentTechnique = State(initialValue: BreathingTechnique.boxBreathing)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                if isInitializing {
                    // Show immediate feedback while view loads
                    VStack {
                        ProgressView()
                            .tint(.appAccent)
                        Text("preparing breath...")
                            .font(.custom("IBMPlexMono-Light", size: 15))
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                } else {
                    mainContent
                }
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
                print("🟢 BreathingView appeared: \(Date())")
                // Preload the intro audio when view appears
                breathManager.preloadIntroFor(technique: currentTechnique)
            }
            .task {
                print("🔵 BreathingView task started: \(Date())")
                // Brief delay to allow transition animation
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                await MainActor.run {
                    isInitializing = false
                }
            }
            .onReceive(timerPublisher) { _ in
                if breathManager.isActive {
                    elapsedSeconds += 1
                }
            }
        }
        .onDisappear {
            print("🔴 BreathingView disappeared: \(Date())")
            cleanup()
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                Text("find your rhythm")
                    .font(.custom("IBMPlexMono-Light", size: 17))
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .padding(.top, -32)
                
                Spacer()
                
                // Breathing visualization
                ZStack {
                    switch BreathingVisualization.forTechnique(currentTechnique.type) {
                    case .box:
                        let progress = calculateProgress(
                            timeRemaining: breathManager.currentPhaseTimeRemaining,
                            pattern: currentTechnique.pattern,
                            phase: breathManager.currentPhase
                        )
                        BoxBreathingView(
                            phase: breathManager.currentPhase,
                            progress: progress,
                            isIntroPlaying: breathManager.isIntroPlaying,
                            isBreathingActive: breathManager.isActive
                        )
                    case .circle:
                        let progress = calculateProgress(
                            timeRemaining: breathManager.currentPhaseTimeRemaining,
                            pattern: currentTechnique.pattern,
                            phase: breathManager.currentPhase
                        )
                        FourSevenEightView(
                            phase: breathManager.currentPhase,
                            progress: progress,
                            isIntroPlaying: breathManager.isIntroPlaying,
                            isBreathingActive: breathManager.isActive
                        )
                    case .wave:
                        let progress = calculateProgress(
                            timeRemaining: breathManager.currentPhaseTimeRemaining,
                            pattern: currentTechnique.pattern,
                            phase: breathManager.currentPhase
                        )
                        ResonanceView(
                            breathingPhase: breathManager.currentPhase,
                            progress: progress,
                            isIntroPlaying: breathManager.isIntroPlaying,
                            isBreathingActive: breathManager.isActive
                        )
                    }
                }
                .frame(width: 200, height: 200)
                .offset(y: -20)
                
                // Timer display
                Text(timeString(from: elapsedSeconds))
                    .font(.custom("IBMPlexMono-Light", size: 21))
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                
                Spacer()
                
                // Breathing technique cards
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(breathingTechniques, id: \.id) { technique in
                            VStack {
                                BreathingCard(technique: technique, isSelected: currentTechnique.type == technique.type) {
                                    if currentTechnique.type != technique.type {
                                        // Stop current breathing if active
                                        if breathManager.isActive {
                                            // Update total breathing minutes when switching
                                            let minutes = Int(ceil(Double(elapsedSeconds) / 60.0))
                                            userService.updateBreathingMinutes(minutes: minutes)
                                            elapsedSeconds = 0
                                            breathManager.stopBreathing()
                                        }
                                        
                                        // Switch to new technique and preload
                                        currentTechnique = technique
                                        breathManager.preloadIntroFor(technique: technique)
                                    }
                                }
                                .font(.custom("IBMPlexMono-Light", size: 17))
                            }
                            .frame(height: 100)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Start/Stop Button with loading state
                VStack(spacing: 0) {
                    // Button or loading indicator
                    Group {
                        if breathManager.isLoading {
                            ProgressView()
                                .tint(.appAccent)
                                .frame(width: 50, height: 50)
                        } else {
                            Button(action: toggleBreathing) {
                                Image(systemName: breathManager.isActive ? "stop.fill" : "play.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.appAccent)
                                    .frame(width: 50, height: 50)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(0)
                            }
                        }
                    }
                    .padding(.top, 30)
                    
                    // Fixed height container for skip intro text
                    ZStack {
                        // Invisible text to reserve space
                        Text("skip intro")
                            .font(.custom("IBMPlexMono-Light", size: 17))
                            .foregroundColor(.clear)
                            .padding(.top, 20)
                        
                        // Actual skip intro text
                        if breathManager.isIntroPlaying && breathManager.isActive {
                            Text("skip intro")
                                .font(.custom("IBMPlexMono-Light", size: 17))
                                .foregroundColor(.appAccent)
                                .onTapGesture {
                                    breathManager.skipIntro(technique: currentTechnique)
                                }
                                .padding(.top, 20)
                                .transition(.opacity)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 40)
            .frame(maxWidth: .infinity, alignment: .leading)
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
            // Update total breathing minutes when stopping
            let minutes = Int(ceil(Double(elapsedSeconds) / 60.0))
            userService.updateBreathingMinutes(minutes: minutes)
            elapsedSeconds = 0
            breathManager.stopBreathing()
        } else {
            startBreathing()
        }
    }

    private func startBreathing() {
        print("BreathingView: starting breathing exercise")
        breathManager.startBreathing(technique: currentTechnique)
    }

    private func restartBreathing() {
        breathManager.stopBreathing()
        elapsedSeconds = 0
    }

    private func calculateProgress(timeRemaining: Int, pattern: [Int], phase: BreathingPhase) -> CGFloat {
        if timeRemaining <= 0 {
            return 1.0
        }
        return 1.0 - (CGFloat(timeRemaining) / CGFloat(pattern[Int(phase.rawValue)]))
    }

    private func cleanup() {
        breathManager.stopBreathing()
        // Replace SoundManager.shared.stopAllAudio() with breathManager.stopBreathing()
        // since breathManager now handles its own audio cleanup
    }
}
