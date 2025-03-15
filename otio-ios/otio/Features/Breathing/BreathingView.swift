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
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    Color.appBackground
                        .ignoresSafeArea()
                    
                    if isInitializing {
                        // Show immediate feedback while view loads
                        VStack {
                            ProgressView()
                                .tint(.primary)
                            Text("preparing to breathe.")
                                .font(.custom("IBMPlexMono-Light", size: 15))
                                .foregroundColor(.primary)
                                .padding(.top, 8)
                        }
                    } else {
                        mainContent(geometry: geometry)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
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
                                .foregroundColor(.primary)
                        }
                    }
                }
                .gesture(
                    DragGesture()
                        .onEnded { gesture in
                            if gesture.translation.width > 100 {
                                dismiss()
                            }
                        }
                )
            }
            .onAppear {
                print("🟢 BreathingView appeared: \(Date())")
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
    private func mainContent(geometry: GeometryProxy) -> some View {
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
                .frame(width: min(200, geometry.size.width * 0.5),  // Responsive width
                       height: min(200, geometry.size.width * 0.5))  // Keep it square
                .offset(y: -geometry.size.height * 0.02)  // Small upward offset
                
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
                                .tint(.primary)
                                .frame(width: 50, height: 50)
                        } else {
                            Button(action: toggleBreathing) {
                                Image(systemName: breathManager.isActive ? "stop.fill" : "play.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.primary)
                                    .frame(width: 50, height: 50)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(0)
                            }
                        }
                    }
                    .padding(.top, geometry.size.height * 0.02)  // Responsive padding
                    
                    // Skip intro with dynamic positioning
                    ZStack {
                        if breathManager.isIntroPlaying && breathManager.isActive && !breathManager.isLoading {
                            Text("skip intro")
                                .font(.custom("IBMPlexMono-Light", size: 15))
                                .foregroundColor(.primary)
                                .onTapGesture {
                                    breathManager.skipIntro(technique: currentTechnique)
                                }
                                .padding(.top, geometry.size.height * 0.02)  // Responsive padding
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, geometry.size.height * 0.05)  // Responsive vertical padding
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
