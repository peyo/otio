import Foundation
import AVFoundation

class AudioSessionManager {
    static let shared = AudioSessionManager()
    
    private init() {
        print("AudioSessionManager: Instance created")
        // Try to configure immediately
        try? configureAudioSession()
    }
    
    func configureAudioSession() throws {
        print("\nAudioSessionManager: Beginning configuration...")
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // More aggressive configuration
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            // Try setting preferred values
            try audioSession.setPreferredIOBufferDuration(0.005)
            try audioSession.setPreferredSampleRate(44100)
            
            // Detailed session info
            print("AudioSessionManager: Configuration successful:")
            print("- Category: \(audioSession.category.rawValue)")
            print("- Mode: \(audioSession.mode.rawValue)")
            print("- Active: \(audioSession.isOtherAudioPlaying)")
            print("- Volume: \(audioSession.outputVolume)")
            print("- Sample Rate: \(audioSession.sampleRate)")
            print("- IO Buffer Duration: \(audioSession.ioBufferDuration)")
            print("- Output Latency: \(audioSession.outputLatency)")
            print("AudioSessionManager: Configuration complete\n")
            
        } catch {
            print("AudioSessionManager: ❌ Configuration failed: \(error)")
            print("AudioSessionManager: ❌ Error details: \(error.localizedDescription)")
            throw error
        }
    }
    
    func deactivateAudioSession() throws {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(false)
            print("Audio session deactivated successfully.")
        } catch {
            print("Failed to deactivate audio session: \(error)")
            throw error
        }
    }
}