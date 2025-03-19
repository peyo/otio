import SwiftUI

struct ListeningView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var soundManager = SoundManager.shared
    @StateObject private var userService = UserService.shared
    @State private var isPlaying = false
    @State private var currentSound: SoundType
    @State private var amplitude: Float = 0.1
    @State private var phase: Double = 0
    @State private var elapsedSeconds: Int = 0
    @State private var isInitializing = true
    
    private var timerPublisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let sampleCount = 100
    private let normalizedScore: Double

    init(normalizedScore: Double) {
        self.normalizedScore = normalizedScore
        _currentSound = State(initialValue: SoundType.recommendedSound)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    Color.appBackground.ignoresSafeArea()
                    
                    if isInitializing {
                        loadingView
                    } else {
                        mainContent(geometry: geometry)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("listen")
                            .font(.custom("IBMPlexMono-Light", size: 22))
                            .fontWeight(.semibold)
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
        }
        .onAppear {
            print("🟢 ListeningView appeared: \(Date())")
            startVisualUpdates()
            setupNotifications()
        }
        .task {
            print("🔵 ListeningView task started: \(Date())")
            try? await Task.sleep(nanoseconds: 100_000_000)
            await MainActor.run {
                isInitializing = false
            }
        }
        .onDisappear {
            print("🔴 ListeningView disappeared: \(Date())")
            soundManager.stopAllSounds()
            NotificationCenter.default.removeObserver(
                self,
                name: .soundPlaybackFinished,
                object: nil
            )
        }
        .onReceive(timerPublisher) { _ in
            if isPlaying {
                elapsedSeconds += 1
            }
        }
    }

    // MARK: - View Components
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .tint(.primary)
            Text("preparing to listen.")
                .font(.custom("IBMPlexMono-Light", size: 15))
                .foregroundColor(.primary)
                .padding(.top, 8)
        }
    }
    
    @ViewBuilder
    private func mainContent(geometry: GeometryProxy) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                Text("catch the wave")
                    .font(.custom("IBMPlexMono-Light", size: 17))
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .padding(.top, -32)
                
                Spacer()
                
                // Visualization and timer
                WaveformVisualizationView(
                    sampleCount: sampleCount,
                    phase: phase,
                    amplitude: amplitude,
                    geometry: geometry,
                    elapsedSeconds: elapsedSeconds
                )

                Spacer()
                
                // Sound selection
                SoundSelectorView(
                    currentSound: $currentSound,
                    isPlaying: isPlaying,
                    geometry: geometry,
                    onSoundSelected: handleSoundSelection
                )
                
                // Play/Stop button
                playButton(geometry: geometry)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, geometry.size.height * 0.05)
        }
    }
    
    private func playButton(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            Button(action: toggleSound) {
                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.primary)
                    .frame(width: 50, height: 50)
                    .background(Color.appCardBackground)
                    .cornerRadius(0)
            }
            .padding(.top, geometry.size.height * 0.02)
        }
    }
    
    // MARK: - Logic Functions
    
    private func handleSoundSelection(sound: SoundType, minutes: Int) {
        // Stop current sound if playing
        if isPlaying {
            soundManager.stopAllSounds()
            // Update total meditation minutes when switching
            let minutes = Int(ceil(Double(elapsedSeconds) / 60.0))
            userService.updateMeditationMinutes(minutes: minutes)
            elapsedSeconds = 0
            isPlaying = false
        }
        currentSound = sound
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .soundPlaybackFinished,
            object: nil,
            queue: .main
        ) { notification in
            isPlaying = false
            elapsedSeconds = 0
            // Update total meditation minutes when nature sound finishes
            let minutes = Int(ceil(Double(elapsedSeconds) / 60.0))
            userService.updateMeditationMinutes(minutes: minutes)
        }
    }

    private func toggleSound() {
        if isPlaying {
            soundManager.stopAllSounds()
            // Update total meditation minutes when stopping
            let minutes = Int(ceil(Double(elapsedSeconds) / 60.0))
            userService.updateMeditationMinutes(minutes: minutes)
        } else {
            startCurrentSound()
        }
        isPlaying.toggle()
        
        // Reset timer when stopping
        if !isPlaying {
            elapsedSeconds = 0
        }
    }

    private func startCurrentSound() {
        if currentSound == .recommendedSound {
            soundManager.startSound(
                type: determineRecommendedSound(from: normalizedScore),
                normalizedScore: normalizedScore,
                isRecommendedButton: true
            )
        } else {
            soundManager.startSound(
                type: currentSound,
                normalizedScore: normalizedScore
            )
        }
    }

    private func startVisualUpdates() {
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