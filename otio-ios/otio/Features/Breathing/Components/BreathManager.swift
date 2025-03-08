import SwiftUI
import AudioKit
import SoundpipeAudioKit
import AVFoundation

// Common enum used by all breathing techniques
enum BreathingPhase: Int {
    case inhale = 0
    case holdAfterInhale = 1
    case exhale = 2
    case holdAfterExhale = 3
}

class BreathManager: ObservableObject {
    static let shared = BreathManager()
    
    @Published var currentPhase: BreathingPhase = .inhale
    @Published var timeRemaining: Int = 180
    @Published var currentPhaseTimeRemaining: Int = 4
    @Published var isIntroPlaying = false
    @Published var isLoading = false
    @Published var isActive = false
    
    private var preloadedURL: URL?
    private var preloadedTechnique: BreathingType?
    private var timer: Timer?
    private let engine = AudioEngine()
    private var beepOscillator: Oscillator?
    private let mainMixer: Mixer
    private let audioPlayerManager = AudioPlayerManager()
    private let totalDuration = 180
    private var isFirstBeep = true
    
    private var currentTechnique: BreathingTechnique?
    
    private init() {
        print("BreathManager: Initializing...")
        
        mainMixer = Mixer()
        engine.output = mainMixer
        print("BreathManager: Main mixer set as engine output")
        
        do {
            print("BreathManager: Starting audio engine...")
            try engine.start()
            print("BreathManager: Audio engine started successfully")
        } catch {
            print("BreathManager: Failed to start audio engine: \(error)")
        }

        configureAudioSession()
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.allowAirPlay])
            try audioSession.setActive(true)
            print("Audio session configured successfully.")
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    func preloadIntroFor(technique: BreathingTechnique) {
        guard let introFile = technique.introAudioFile else { return }
        
        if preloadedTechnique != technique.type {
            preloadedURL = nil
            preloadedTechnique = nil
        }
        
        isLoading = true
        print("BreathManager: Preloading intro for \(technique.type) with file: \(introFile)")
        
        audioPlayerManager.fetchDownloadURL(for: introFile, directory: "breathing") { [weak self] url in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let url = url {
                    self.preloadedURL = url
                    self.preloadedTechnique = technique.type
                    print("BreathManager: Successfully preloaded intro for \(technique.type)")
                }
                self.isLoading = false
            }
        }
    }

    // Common function used by all breathing techniques
    func startBreathing(technique: BreathingTechnique) {
        print("BreathManager: startBreathing called for technique: \(technique.type)")
        
        if preloadedTechnique != technique.type {
            preloadedURL = nil
            preloadedTechnique = nil
        }
        
        currentTechnique = technique
        isActive = true
        isIntroPlaying = true
        isFirstBeep = true
        timeRemaining = totalDuration
        currentPhaseTimeRemaining = technique.pattern[0]
        
        if let introFile = technique.introAudioFile {
            print("BreathManager: Using intro file: \(introFile)")
            isLoading = true
            
            audioPlayerManager.fetchAndPlayAudio(
                fileName: introFile,
                directory: "breathing",
                onStart: { [weak self] in
                    DispatchQueue.main.async {
                        self?.isLoading = false  // Stop loading when audio starts playing
                    }
                },
                completion: { [weak self] in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        print("BreathManager: intro audio finished naturally")
                        self.isIntroPlaying = false
                        print("BreathManager: isIntroPlaying set to false")
                        print("BreathManager: Starting exercise in 3 seconds...")
                        
                        // Add 3 second delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            self.startBreathingTimer(technique: technique)
                        }
                    }
                },
                onError: { [weak self] error in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        print("BreathManager: Error playing intro: \(error.description)")
                        self.isLoading = false
                        self.stopBreathing()
                    }
                }
            )
        } else {
            startBreathingTimer(technique: technique)
        }
    }
    
    // Common timer setup used by all breathing techniques
    private func startBreathingTimer(technique: BreathingTechnique) {
        print("BreathManager: startBreathingTimer called")
        
        // Play start beep when timer begins
        playPhaseTransitionBeep()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateBreathing(technique: technique)
        }
    }
    
    // Common breathing update logic used by all techniques
    private func updateBreathing(technique: BreathingTechnique) {
        guard timeRemaining > 0 else {
            print("BreathManager: Exercise complete, stopping")
            stopBreathing()
            return
        }
        
        currentPhaseTimeRemaining -= 1
        timeRemaining -= 1
        
        // Log current state
        print("BreathManager: Time - Phase: \(currentPhase), Remaining: \(currentPhaseTimeRemaining), Total: \(timeRemaining)")
        
        if currentPhaseTimeRemaining < 0 {
            print("BreathManager: Phase complete, transitioning...")
            moveToNextPhase(technique: technique)
        }
    }
    
    private func moveToNextPhase(technique: BreathingTechnique) {
        print("\n=== Phase Transition ===")
        print("BreathManager: Current phase before transition: \(currentPhase)")
        
        // Beep logic for different techniques
        switch technique.type {
        case .resonance:
            print("BreathManager: Resonance technique - checking beep conditions")
            // For resonance, we want beeps when transitioning TO inhale or exhale
            let nextPhase = getNextPhase(currentPhase)
            print("BreathManager: Next phase will be: \(nextPhase)")
            if nextPhase == .inhale || nextPhase == .exhale {
                print("BreathManager: Conditions met - playing beep")
                playPhaseTransitionBeep()
            }
        case .fourSevenEight:
            print("BreathManager: 4-7-8 technique - checking phase")
            // Play beep at the start of each phase except holdAfterExhale
            let nextPhase = getNextPhase(currentPhase)
            if nextPhase != .holdAfterExhale {
                print("BreathManager: Playing transition beep for next phase: \(nextPhase)")
                playPhaseTransitionBeep()
            }
        default: // Box breathing
            print("BreathManager: Box breathing - checking next phase")
            let nextPhaseIndex = (currentPhase.rawValue + 1) % 4
            let nextPhaseDuration = technique.pattern[nextPhaseIndex]
            print("BreathManager: Next phase duration: \(nextPhaseDuration)")
            if nextPhaseDuration > 0 {
                print("BreathManager: Playing transition beep")
                playPhaseTransitionBeep()
            }
        }
        
        // Phase transition logic remains the same
        let previousPhase = currentPhase
        switch currentPhase {
        case .inhale:
            currentPhase = .holdAfterInhale
            currentPhaseTimeRemaining = technique.pattern[1]
        case .holdAfterInhale:
            currentPhase = .exhale
            currentPhaseTimeRemaining = technique.pattern[2]
        case .exhale:
            currentPhase = .holdAfterExhale
            currentPhaseTimeRemaining = technique.pattern[3]
        case .holdAfterExhale:
            currentPhase = .inhale
            currentPhaseTimeRemaining = technique.pattern[0]
        }
        
        print("BreathManager: Transition complete - \(previousPhase) → \(currentPhase)")
        print("BreathManager: New phase duration: \(currentPhaseTimeRemaining)")
        print("=== End Transition ===\n")
    }
    
    private func getNextPhase(_ phase: BreathingPhase) -> BreathingPhase {
        switch phase {
        case .inhale:
            return .holdAfterInhale
        case .holdAfterInhale:
            return .exhale
        case .exhale:
            return .holdAfterExhale
        case .holdAfterExhale:
            return .inhale
        }
    }
    
    // Common beep sound generation used by all techniques
    private func playPhaseTransitionBeep() {
        print("\n--- Beep Event ---")
        print("BreathManager: Initiating beep at phase: \(currentPhase)")
        
        // Make sure engine is active and has output
        if engine.output == nil {
            engine.output = mainMixer
            try? engine.start()
        }
        
        beepOscillator = Oscillator(
            waveform: Table(.sine),
            frequency: 440.0,
            amplitude: 0.3
        )
        
        if let beepOscillator = beepOscillator {
            print("BreathManager: Playing beep")
            mainMixer.addInput(beepOscillator)
            mainMixer.volume = 1.0
            beepOscillator.start()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                guard let self = self else { return }
                print("BreathManager: Beep complete")
                beepOscillator.stop()
                self.mainMixer.removeInput(beepOscillator)
                self.beepOscillator = nil
                print("--- End Beep Event ---\n")
            }
        }
    }
    
    // Common cleanup used by all techniques
    func stopBreathing() {
        print("BreathManager: stopBreathing called")
        isActive = false
        isIntroPlaying = false
        isFirstBeep = true
        timer?.invalidate()
        timer = nil
        timeRemaining = totalDuration
        currentPhaseTimeRemaining = 4
        currentPhase = .inhale
        
        preloadedURL = nil
        preloadedTechnique = nil
        
        print("BreathManager: stopping all audio")
        audioPlayerManager.stopAudio()
        beepOscillator?.stop()
        beepOscillator = nil
        print("BreathManager: cleanup completed")
    }
    
    // Add delay to skip intro as well
    func skipIntro(technique: BreathingTechnique) {
        print("BreathManager: Skipping intro")
        
        audioPlayerManager.stopAudio()
        
        isIntroPlaying = false
        print("BreathManager: isIntroPlaying set to false (intro skipped)")
        print("BreathManager: Starting exercise in 3 seconds...")
        
        // Add 3 second delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.startBreathingTimer(technique: technique)
        }
    }
    
    deinit {
        stopBreathing()
    }
} 