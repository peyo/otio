import SwiftUI

struct ListeningView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var soundManager = SoundManager.shared
    @State private var isPlaying = false
    @State private var currentSound: SoundType
    @State private var amplitude: Float = 0.1
    @State private var phase: Double = 0
    @State private var elapsedSeconds: Int = 0
    @State private var isInitializing = true  // Add loading state
    private var timerPublisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let sampleCount = 100
    private let normalizedScore: Double
    @StateObject private var userService = UserService.shared

    init(normalizedScore: Double) {
        self.normalizedScore = normalizedScore
        _currentSound = State(initialValue: SoundType.recommendedSound)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    Color.appBackground
                        .ignoresSafeArea()
                    
                    if isInitializing {
                        VStack {
                            ProgressView()
                                .tint(.primary)
                            Text("preparing to listen.")
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
            // Brief delay to allow transition animation
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
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
                
                // Waveform visualization
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

                Spacer()
                
                // Sound selection cards
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // Show recommended sound first
                        VStack {
                            SoundCard(sound: .recommendedSound, isSelected: currentSound == .recommendedSound) {
                                if currentSound != .recommendedSound {
                                    // Stop current sound if playing
                                    if isPlaying {
                                        soundManager.stopAllSounds()
                                        // Update total meditation minutes when switching
                                        let minutes = Int(ceil(Double(elapsedSeconds) / 60.0))
                                        userService.updateMeditationMinutes(minutes: minutes)
                                        elapsedSeconds = 0
                                        isPlaying = false
                                    }
                                    currentSound = .recommendedSound
                                }
                            }
                            .font(.custom("IBMPlexMono-Light", size: 17))
                        }
                        .frame(height: 100)
                        
                        // Show remaining sounds
                        ForEach(SoundType.allCases.filter { $0 != .recommendedSound }, id: \.self) { sound in
                            VStack {
                                SoundCard(sound: sound, isSelected: currentSound == sound) {
                                    if currentSound != sound {
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
                                }
                                .font(.custom("IBMPlexMono-Light", size: 17))
                            }
                            .frame(height: 100)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Play/Stop button
                VStack(spacing: 0) {
                    Button(action: toggleSound) {
                        Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.primary)
                            .frame(width: 50, height: 50)
                            .background(Color(.systemGray5))
                            .cornerRadius(0)
                    }
                    .padding(.top, geometry.size.height * 0.02)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, geometry.size.height * 0.05)
        }
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

    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    func toggleSound() {
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

    func startCurrentSound() {
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
