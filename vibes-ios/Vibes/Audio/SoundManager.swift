import Foundation
import AudioKit
import SoundpipeAudioKit
import AVFoundation
import FirebaseStorage

class SoundManager: ObservableObject {
    static let shared = SoundManager()
    private let engine = AudioEngine()
    private var happyChordOscillators: [Oscillator] = []
    private var sadChordOscillators: [Oscillator] = []
    private var anxiousChordOscillators: [Oscillator] = []
    private var angryOscillators: [Oscillator] = []
    private var audioPlayerManager = AudioPlayerManager()
    
    init(normalizedScore: Double = 0.0) {
        // Initialize oscillators for a happy melody
        let happyFrequencies: [Float] = [261.63, 329.63, 392.00] // C4, E4, G4 (C Major chord)
        happyChordOscillators = happyFrequencies.map { frequency in
            Oscillator(waveform: Table(.sine), frequency: frequency, amplitude: 0.5)
        }
        
        // Initialize oscillators for a sad melody using A minor chord
        let sadFrequencies: [Float] = [220.00, 261.63, 329.63] // A3, C4, E4 (A Minor chord)
        sadChordOscillators = sadFrequencies.map { frequency in
            Oscillator(waveform: Table(.sine), frequency: frequency, amplitude: 0.4)
        }
        
        // Initialize oscillators for a calming melody using D minor chord
        let anxiousFrequencies: [Float] = [293.66, 349.23, 440.00] // D4, F4, A4 (D Minor chord)
        anxiousChordOscillators = anxiousFrequencies.map { frequency in
            Oscillator(waveform: Table(.sine), frequency: frequency, amplitude: 0.3)
        }
        
        // Initialize oscillators for a rhythmic pattern for anger
        let angryFrequencies: [Float] = [110.00, 220.00, 330.00] // A2, A3, E4 (Rhythmic pattern)
        angryOscillators = angryFrequencies.map { frequency in
            Oscillator(waveform: Table(.sine), frequency: frequency, amplitude: 0.3)
        }
        
        // Determine the recommended sound based on the normalized score
        let recommendedSound = determineRecommendedSound(from: normalizedScore)
        
        // Set the initial output based on the recommended sound
        switch recommendedSound {
        case .happySound:
            engine.output = Mixer(happyChordOscillators)
        case .sadSound:
            engine.output = Mixer(sadChordOscillators)
        case .anxiousSound:
            engine.output = Mixer(anxiousChordOscillators)
        case .angrySound:
            engine.output = Mixer(angryOscillators)
        case .natureSound:
            // Handle nature sound initialization if needed
            engine.output = Mixer() // Set a default empty mixer
        default:
            engine.output = Mixer(happyChordOscillators) // Fallback to happy sound
        }
        
        // Start the audio engine
        do {
            try engine.start()
            print("Audio engine started successfully.")
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    func startSound(type: SoundType, normalizedScore: Double? = nil) {
        stopAllSounds()
        
        let soundToPlay: SoundType
        if type == .recommendedSound, let score = normalizedScore {
            soundToPlay = determineRecommendedSound(from: score)
        } else {
            soundToPlay = type
        }
        
        switch soundToPlay {
        case .happySound:
            engine.output = Mixer(happyChordOscillators)
            happyChordOscillators.forEach { $0.start() }
        case .sadSound:
            engine.output = Mixer(sadChordOscillators)
            startSadChordProgression()
        case .anxiousSound:
            engine.output = Mixer(anxiousChordOscillators)
            startAnxiousChordProgression()
        case .angrySound:
            engine.output = Mixer(angryOscillators)
            startAngryOscillators()
        case .natureSound:
            fetchDownloadURL(for: "2024-09-15-rancheria-falls.wav") { url in
                if let url = url {
                    self.playAudioFromURL(url)
                } else {
                    print("Failed to get download URL")
                }
            }
        case .recommendedSound:
            // This case should not be reached because soundToPlay should be resolved
            print("Error: Recommended sound should have been resolved to a specific sound type.")
        }
    }
    
    func stopAllSounds() {
        print("Stopping all sounds")
        happyChordOscillators.forEach { $0.stop() }
        sadChordOscillators.forEach { $0.stop() }
        anxiousChordOscillators.forEach { $0.stop() }
        angryOscillators.forEach { $0.stop() }
        audioPlayerManager.stopAudio()
        print("All sounds stopped")
    }
    
    private func startSadChordProgression() {
        sadChordOscillators.forEach { $0.start() }
    }
    
    private func startAnxiousChordProgression() {
        anxiousChordOscillators.forEach { $0.start() }
    }
    
    private func startAngryOscillators() {
        angryOscillators.forEach { $0.start() }
    }

    func playAudioFromURL(_ url: URL) {
        audioPlayerManager.playAudio(from: url)
    }
    
    func fetchDownloadURL(for fileName: String, completion: @escaping (URL?) -> Void) {
        stopAllSounds()
        print("Fetching download URL for \(fileName)")
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let fileRef = storageRef.child("nature/\(fileName)")

        fileRef.downloadURL { url, error in
            if let error = error {
                print("Error fetching download URL: \(error.localizedDescription)")
                completion(nil)
            } else {
                print("Download URL fetched successfully")
                completion(url)
            }
        }
    }
}

class AudioPlayerManager {
    private var player: AVPlayer?

    func playAudio(from url: URL) {
        player = AVPlayer(url: url)
        player?.play()
    }

    func stopAudio() {
        player?.pause()
        player = nil
    }
}
