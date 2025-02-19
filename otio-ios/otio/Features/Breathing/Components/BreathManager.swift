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
    
    private var timer: Timer?
    private let engine = AudioEngine()
    private var beepOscillator: Oscillator?
    private let mainMixer: Mixer
    private let soundManager = SoundManager.shared
    private let totalDuration = 180
    private var isFirstBeep = true
    
    var isActive = false
    
    private init() {
        print("BreathManager: Initializing...")
        
        // Create and set the main mixer first
        mainMixer = Mixer()
        engine.output = mainMixer
        print("BreathManager: Main mixer set as engine output")
        
        // Then start the engine
        do {
            print("BreathManager: Starting audio engine...")
            try engine.start()
            print("BreathManager: Audio engine started successfully")
        } catch {
            print("BreathManager: Failed to start audio engine: \(error)")
        }

        configureAudioSession() // Configure the audio session during initialization
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

    // Common function used by all breathing techniques
    func startBreathing(technique: BreathingTechnique) {
        print("BreathManager: startBreathing called")
        isActive = true
        isIntroPlaying = true
        isFirstBeep = true
        print("BreathManager: isIntroPlaying set to true")
        timeRemaining = totalDuration
        currentPhaseTimeRemaining = technique.pattern[0]
        
        if let introFile = technique.introAudioFile {
            print("BreathManager: attempting to play intro audio: \(introFile)")
            soundManager.fetchDownloadURL(for: introFile, directory: "breathing") { [weak self] url in
                guard let self = self else { return }
                
                if let url = url {
                    print("BreathManager: got URL for intro audio, playing...")
                    self.soundManager.playAudioFromURL(url) {
                        print("BreathManager: intro audio finished naturally")
                        self.isIntroPlaying = false
                        print("BreathManager: isIntroPlaying set to false")
                        self.startBreathingTimer(technique: technique)
                    }
                } else {
                    print("BreathManager: failed to get URL for intro audio")
                    self.isIntroPlaying = false
                    print("BreathManager: isIntroPlaying set to false (URL failed)")
                    self.startBreathingTimer(technique: technique)
                }
            }
        } else {
            startBreathingTimer(technique: technique)
        }
    }
    
    // Common timer setup used by all breathing techniques
    private func startBreathingTimer(technique: BreathingTechnique) {
        print("BreathManager: startBreathingTimer called")
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
            print("BreathManager: Next phase will be: \(nextPhase), isFirstBeep: \(isFirstBeep)")
            if (nextPhase == .inhale || nextPhase == .exhale) && !isFirstBeep {
                print("BreathManager: Conditions met - playing beep")
                playPhaseTransitionBeep()
            } else {
                print("BreathManager: Skipping beep - First beep: \(isFirstBeep)")
            }
            isFirstBeep = false
        case .fourSevenEight:
            print("BreathManager: 4-7-8 technique - checking phase")
            // Play beep at the start of inhale, hold, and exhale phases
            if currentPhase != .holdAfterExhale {
                print("BreathManager: Playing transition beep for phase: \(currentPhase)")
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
        
        print("BreathManager: stopping all audio")
        soundManager.stopAllAudio()
        beepOscillator?.stop()
        beepOscillator = nil
        engine.output = nil
        print("BreathManager: cleanup completed")
    }
    
    deinit {
        stopBreathing()
    }
} 