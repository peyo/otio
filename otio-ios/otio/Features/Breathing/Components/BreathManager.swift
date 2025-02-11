import SwiftUI
import AudioKit
import SoundpipeAudioKit
import AVFoundation

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

    func startBreathing(technique: BreathingTechnique) {
        print("BreathManager: startBreathing called")
        isActive = true
        isIntroPlaying = true
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
    
    private func startBreathingTimer(technique: BreathingTechnique) {
        print("BreathManager: startBreathingTimer called")
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateBreathing(technique: technique)
        }
    }
    
    private func updateBreathing(technique: BreathingTechnique) {
        guard timeRemaining > 0 else {
            stopBreathing()
            return
        }
        
        currentPhaseTimeRemaining -= 1
        timeRemaining -= 1
        
        if currentPhaseTimeRemaining < 0 {
            moveToNextPhase(technique: technique)
        }
    }
    
    private func moveToNextPhase(technique: BreathingTechnique) {
        print("BreathManager: Moving to next phase")
        
        // Only play beep for phase transitions that have a duration
        let nextPhaseIndex = (currentPhase.rawValue + 1) % 4
        let nextPhaseDuration = technique.pattern[nextPhaseIndex]
        
        // Play beep only if the next phase has a duration (not 0)
        if nextPhaseDuration > 0 {
            playPhaseTransitionBeep()
        }
        
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
        print("BreathManager: Phase changed to \(currentPhase)")
    }
    
    private func playPhaseTransitionBeep() {
        print("BreathManager: Playing phase transition beep")
        
        beepOscillator = Oscillator(
            waveform: Table(.sine),
            frequency: 440.0,  // Changed from 880.0 to 440.0 (A4 note, one octave lower)
            amplitude: 0.3     // Also slightly reduced amplitude
        )
        
        if let beepOscillator = beepOscillator {
            print("BreathManager: Beep oscillator created")
            
            // Add oscillator to the main mixer
            mainMixer.addInput(beepOscillator)
            mainMixer.volume = 1.0
            
            print("BreathManager: Starting beep oscillator...")
            beepOscillator.start()
            print("BreathManager: Beep oscillator started")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                guard let self = self else { return }
                print("BreathManager: Stopping beep oscillator...")
                beepOscillator.stop()
                self.mainMixer.removeInput(beepOscillator)
                self.beepOscillator = nil
                print("BreathManager: Beep cleanup completed")
            }
        }
    }
    
    func stopBreathing() {
        print("BreathManager: stopBreathing called")
        isActive = false
        isIntroPlaying = false
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