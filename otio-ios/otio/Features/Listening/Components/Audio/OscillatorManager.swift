import Foundation
import AudioKit
import SoundpipeAudioKit

class OscillatorManager {
    private let engine: AudioEngine
    private var binauralGenerator: EnhancedBinauralGenerator?
    
    // Frequency constants
    private struct BrainwaveFreqs {
        static let happy = 10.0      // Alpha (8-12 Hz)
        static let loved = 8.0       // Alpha-Theta (6-10 Hz)
        static let confident = 12.0   // Alpha-Beta (10-14 Hz)
        static let playful = 10.5     // Alpha (9-12 Hz)
        static let embarrassed = 6.0  // Theta (4-8 Hz)
        static let angry = 4.0       // Theta-Delta (2-6 Hz)
        static let scared = 4.5      // Theta-Delta (3-6 Hz)
        static let sad = 2.5         // Delta (1-4 Hz)
    }
    
    init(engine: AudioEngine) {
        print("\n=== OscillatorManager: Initialization Started ===")
        self.engine = engine
        setupGenerator()
        print("=== OscillatorManager: Initialization Complete ===\n")
    }
    
    private func setupGenerator() {
        print("OscillatorManager: Creating binaural generator...")
        binauralGenerator = EnhancedBinauralGenerator(engine: engine)
        
        if binauralGenerator != nil {
            print("OscillatorManager: Binaural generator created successfully")
        } else {
            print("OscillatorManager: Failed to create binaural generator!")
        }
    }
    
    func startSound(_ type: SoundType) {
        print("\n=== OscillatorManager: Starting Sound ===")
        print("OscillatorManager: Starting sound for \(type)")
        print("OscillatorManager: Engine running: \(engine.avEngine.isRunning)")
        
        guard let generator = binauralGenerator else {
            print("OscillatorManager: No binaural generator available!")
            return
        }
        
        let frequency: Float = {
            switch type {
            case .happy: return Float(BrainwaveFreqs.happy)
            case .loved: return Float(BrainwaveFreqs.loved)
            case .confident: return Float(BrainwaveFreqs.confident)
            case .playful: return Float(BrainwaveFreqs.playful)
            case .embarrassed: return Float(BrainwaveFreqs.embarrassed)
            case .angry: return Float(BrainwaveFreqs.angry)
            case .scared: return Float(BrainwaveFreqs.scared)
            case .sad: return Float(BrainwaveFreqs.sad)
            default: return 10.0
            }
        }()
        
        generator.start(frequency: frequency)
    }
    
    func stopSound(_ type: SoundType) {
        print("OscillatorManager: Stopping sound")
        binauralGenerator?.stop()
    }
    
    func stopAllSounds() {
        print("OscillatorManager: Stopping all sounds")
        binauralGenerator?.stop()
    }
    
    func fadeOut(_ type: SoundType, duration: TimeInterval) {
        print("OscillatorManager: Fading out")
        binauralGenerator?.fadeOut(duration: duration)
    }
    
    func setVolume(_ volume: Float) {
        print("OscillatorManager: Setting volume to \(volume)")
        binauralGenerator?.setVolume(volume)
    }
}