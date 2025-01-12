import Foundation
import AudioKit
import SoundpipeAudioKit
import AVFoundation
import FirebaseStorage

class SoundManager: ObservableObject {
    static let shared = SoundManager()
    private let engine = AudioEngine()
    private var harmonicOscillators: [Oscillator] = []
    private var binauralOscillators: [Oscillator] = []
    private var pinkNoise: PinkNoise
    private var isochronicOscillator: Oscillator?
    private var currentTimer: Timer?
    private var amplitudeModulationTimer: Timer?
    private var audioPlayerManager = AudioPlayerManager()
    
    private static let baseFrequency: Float = 110
    private static let harmonicRatios: [Float] = [1, 2, 3, 4, 5]
    
    init() {
        // Initialize harmonic oscillators
        harmonicOscillators = SoundManager.harmonicRatios.map { ratio in
            Oscillator(waveform: Table(.sine), frequency: SoundManager.baseFrequency * ratio, amplitude: 0.5)
        }
        
        // Initialize binaural oscillators
        binauralOscillators = [
            Oscillator(waveform: Table(.sine), frequency: 100, amplitude: 0.5),
            Oscillator(waveform: Table(.sine), frequency: 104, amplitude: 0.5)
        ]
        
        // Initialize pink noise
        pinkNoise = PinkNoise(amplitude: 0.5)
        
        // Initialize isochronic oscillator
        let carrierFrequency: Float = 440 // A4 note, within audible range
        isochronicOscillator = Oscillator(waveform: Table(.sine), frequency: carrierFrequency, amplitude: 0.8)
        
        // Set the initial output
        engine.output = Mixer(harmonicOscillators)
        
        // Start the audio engine
        do {
            try engine.start()
            print("Audio engine started successfully.")
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    func startSound(type: SoundType) {
        stopAllSounds()
        
        switch type {
        case .binauralBeats:
            engine.output = Mixer(binauralOscillators)
            startBinauralBeats()
        case .pinkNoise:
            engine.output = pinkNoise
            pinkNoise.start()
        case .isochronicTone:
            if let isochronicOscillator = isochronicOscillator {
                engine.output = isochronicOscillator
                startIsochronicTone()
            }
        case .natureSound:
            // Handle nature sound case
            fetchDownloadURL(for: "2024-09-15-rancheria-falls.wav") { url in
                if let url = url {
                    self.playAudioFromURL(url)
                } else {
                    print("Failed to get download URL")
                }
            }
        }
    }
    
    func stopAllSounds() {
        print("Stopping all sounds")
        harmonicOscillators.forEach { $0.stop() }
        binauralOscillators.forEach { $0.stop() }
        pinkNoise.stop()
        isochronicOscillator?.stop()
        amplitudeModulationTimer?.invalidate()
        currentTimer?.invalidate()
        audioPlayerManager.stopAudio()
        print("All sounds stopped")
    }
    
    private func startBinauralBeats() {
        binauralOscillators.forEach { $0.start() }
    }

    func startIsochronicTone() {
        print("Starting isochronic tone with carrier frequency.")
        isochronicOscillator?.amplitude = 0.0
        isochronicOscillator?.start()
        startAmplitudeModulation()
    }

    private func startAmplitudeModulation() {
        amplitudeModulationTimer?.invalidate()
        amplitudeModulationTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let modulationFrequency: Double = 5
            let newAmplitude = 0.5 * (1 + sin(2 * .pi * modulationFrequency * Date().timeIntervalSinceReferenceDate))
            self.isochronicOscillator?.amplitude = AUValue(newAmplitude)
            print("Isochronic amplitude: \(newAmplitude)")
        }
    }
    
    func playAudioFromURL(_ url: URL) {
        audioPlayerManager.playAudio(from: url)
    }
    
    func fetchDownloadURL(for fileName: String, completion: @escaping (URL?) -> Void) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let fileRef = storageRef.child("nature/\(fileName)")

        fileRef.downloadURL { url, error in
            if let error = error {
                print("Error fetching download URL: \(error.localizedDescription)")
                completion(nil)
            } else {
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