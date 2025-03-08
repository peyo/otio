import Foundation
import AudioKit
import AVFoundation

class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
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
    
    // State tracking
    private var currentSoundType: SoundType?
    
    private init() {
        print("\nSoundManager: Beginning initialization...")
        setupAudioSession()
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
        print("\nSoundManager: Starting sound for type: \(type)")
        
        // Stop previous sound
        stopAllSounds()
        
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
    }
    
    func stopAllSounds() {
        print("SoundManager: Stopping all sounds")
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