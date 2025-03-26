import Foundation
import AudioKit
import AVFoundation

class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
    // Add these properties
    @Published var isIntroPlaying = false
    @Published var isLoading = false
    
    // Core components
    private let engine = AudioEngine()
    private let audioSessionManager = AudioSessionManager.shared
    private lazy var oscillatorManager: OscillatorManager = {
        print("SoundManager: Creating OscillatorManager...")
        return OscillatorManager(engine: engine)
    }()
    private let natureSoundManager = NatureSoundManager()
    private lazy var crossfadeManager: CrossfadeManager = {
        return CrossfadeManager(
            oscillatorManager: oscillatorManager,
            natureSoundManager: natureSoundManager
        )
    }()
    
    // Add the intro manager
    private let audioIntroManager = AudioIntroManager()
    
    // State tracking
    private var currentSoundType: SoundType?
    
    private init() {
        print("\nSoundManager: Beginning initialization...")
        setupAudioSession()
        setupIntroManager()
    }
    
    private func setupIntroManager() {
        audioIntroManager.onIntroFinished = { [weak self] sound, normalizedScore, isRecommendedButton in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                print("SoundManager: Intro finished, setting isIntroPlaying to false")
                self.isIntroPlaying = false
                self.startActualSound(type: sound, normalizedScore: normalizedScore, isRecommendedButton: isRecommendedButton)
            }
        }
    }
    
    private func setupAudioSession() {
        print("SoundManager: Setting up audio session...")
        do {
            try audioSessionManager.configureAudioSession()
            print("SoundManager: Audio session configured successfully")
        } catch {
            print("SoundManager: Failed to setup audio session: \(error)")
        }
    }
    
    private func startEngine() {
        print("SoundManager: Starting audio engine...")
        do {
            try engine.start()
            print("SoundManager: Audio engine started successfully")
        } catch {
            print("SoundManager: Failed to start engine: \(error)")
        }
    }
    
    func startSound(type: SoundType, normalizedScore: Double? = nil, isRecommendedButton: Bool = false) {
        print("SoundManager: Starting sound for type: \(type.rawValue), isRecommended: \(isRecommendedButton)")
        
        // Stop any currently playing sounds
        stopAllSounds()
        
        // Set loading state
        isLoading = true
        
        // Play intro if available
        isIntroPlaying = true
        audioIntroManager.playIntroFor(
            sound: type,
            normalizedScore: normalizedScore,
            isRecommendedButton: isRecommendedButton
        )
    }
    
    private func startActualSound(type: SoundType, normalizedScore: Double? = nil, isRecommendedButton: Bool = false) {
        if let audioFile = type.audioFileName {
            // Play nature sound
            print("SoundManager: Playing nature sound: \(audioFile)")
            natureSoundManager.playNatureSound(
                fileName: audioFile,
                directory: "nature",
                initialVolume: 1.0
            )
        } else {
            // Play binaural beat
            if !engine.avEngine.isRunning {
                try? engine.start()
            }
            oscillatorManager.startSound(type)
            
            // Start crossfade timer if this is a recommended sound
            if isRecommendedButton {
                print("SoundManager: Starting crossfade timer for recommended sound")
                crossfadeManager.startCrossfadeTimer()
            }
        }
        
        currentSoundType = type
        isLoading = false
    }
    
    func skipIntro() {
        print("SoundManager: Skip intro requested")
        // Set isIntroPlaying to false immediately for UI feedback
        isIntroPlaying = false
        audioIntroManager.skipIntro()
    }
    
    func stopAllSounds() {
        print("SoundManager: Stopping all sounds")
        isIntroPlaying = false
        isLoading = false
        audioIntroManager.stopEverything()
        oscillatorManager.stopAllSounds()
        natureSoundManager.stopCurrentSound()
        crossfadeManager.cancelCrossfade()
        currentSoundType = nil
    }
    
    func cleanup() {
        stopAllSounds()
        engine.stop()
    }
    
    deinit {
        cleanup()
    }
}