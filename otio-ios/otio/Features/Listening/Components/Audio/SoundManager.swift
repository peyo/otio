import Foundation
import AudioKit
import AVFoundation

class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
    // Add these properties
    @Published var isIntroPlaying = false
    @Published var isLoading = false
    @Published var isRecommendedIntroPlaying = false
    @Published var isEmotionIntroPlaying = false
    
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
        audioIntroManager.onIntroStatusChanged = { [weak self] isPlayingRecommended, isPlayingEmotion in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isRecommendedIntroPlaying = isPlayingRecommended
                self.isEmotionIntroPlaying = isPlayingEmotion
                self.isIntroPlaying = isPlayingRecommended || isPlayingEmotion
            }
        }
        
        audioIntroManager.onIntroFinished = { [weak self] sound, normalizedScore, isRecommendedButton in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                print("SoundManager: Intro finished, setting isIntroPlaying to false")
                self.isIntroPlaying = false
                self.isRecommendedIntroPlaying = false
                self.isEmotionIntroPlaying = false
                
                // Make sure we're using the correct sound type
                let soundToPlay = sound
                print("SoundManager: Starting actual sound for: \(soundToPlay.rawValue)")
                
                self.startActualSound(
                    type: soundToPlay, 
                    normalizedScore: normalizedScore, 
                    isRecommendedButton: isRecommendedButton
                )
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
        print("SoundManager: Starting actual sound for type: \(type.rawValue)")
        
        // Handle nature sounds first
        if type == .rancheriaFalls || type == .balanced {
            print("SoundManager: Playing nature sound: \(type.audioFileName ?? "none")")
            natureSoundManager.playNatureSound(
                fileName: type.audioFileName!,
                directory: "nature",
                initialVolume: 1.0
            )
        }
        // Handle recommended sound
        else if type == .recommendedSound, isRecommendedButton {
            print("SoundManager: Playing binaural beat for recommended sound")
            if !engine.avEngine.isRunning {
                try? engine.start()
            }
            
            // Determine which specific sound to play based on score
            if let score = normalizedScore {
                let specificSound = determineRecommendedSound(from: score)
                print("SoundManager: Determined specific sound: \(specificSound.rawValue)")
                oscillatorManager.startSound(specificSound)
            } else {
                // Use balanced as the default sound if no score is provided
                print("SoundManager: No score provided, using balanced sound")
                oscillatorManager.startSound(.balanced)
            }
            
            // Start crossfade timer
            print("SoundManager: Starting crossfade timer for recommended sound")
            crossfadeManager.startCrossfadeTimer()
        }
        // Handle all other emotion sounds
        else {
            print("SoundManager: Playing binaural beat for specific emotion: \(type.rawValue)")
            if !engine.avEngine.isRunning {
                try? engine.start()
            }
            oscillatorManager.startSound(type)
        }
        
        currentSoundType = type
        isLoading = false
    }
    
    func skipIntro() {
        print("SoundManager: Skip intro requested")
        // Set isIntroPlaying to false immediately for UI feedback
        isIntroPlaying = false
        isRecommendedIntroPlaying = false
        isEmotionIntroPlaying = false
        audioIntroManager.skipIntro()
    }
    
    func stopAllSounds() {
        print("SoundManager: Stopping all sounds")
        isIntroPlaying = false
        isRecommendedIntroPlaying = false
        isEmotionIntroPlaying = false
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