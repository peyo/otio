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
        
        // Verify engine is running
        if !engine.avEngine.isRunning {
            print("SoundManager: Engine not running, attempting to start...")
            try? engine.start()
        }
        
        // Start new sound
        oscillatorManager.startSound(type)
        currentSoundType = type
    }
    
    func stopAllSounds() {
        print("SoundManager: Stopping all sounds")
        oscillatorManager.stopAllSounds()
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