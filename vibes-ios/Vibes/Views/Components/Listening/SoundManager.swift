import Foundation
import AudioKit
import SoundpipeAudioKit
import AVFoundation
import FirebaseStorage

class SoundManager: ObservableObject {
    static let shared = SoundManager()
    private let engine = AudioEngine()
    private var isEngineRunning = false
    private var happyChordOscillators: [Oscillator] = []
    private var sadChordOscillators: [Oscillator] = []
    private var anxiousChordOscillators: [Oscillator] = []
    private var angryOscillators: [Oscillator] = []
    private var audioPlayerManager = AudioPlayerManager()
    private var naturePlayer: AVPlayer?
    
    private var crossfadeTimer: Timer?
    private var volumeIncreaseTimer: Timer?
    private var oscillatorFadeTimer: Timer?
    
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
    
    func startSound(type: SoundType, normalizedScore: Double? = nil, isRecommendedButton: Bool = false) {
        if !isRecommendedButton {
            stopAllSounds()
        }
        print("isRecommendedButton: \(isRecommendedButton)")

        // Ensure the audio engine is running
        if !isEngineRunning {
            do {
                try engine.start()
                isEngineRunning = true
                print("Audio engine started successfully.")
            } catch {
                print("Failed to start audio engine: \(error)")
            }
        }

        // Handle the actual sound playing
        switch type {
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
        case .recommendedSound: break
        }

        // If it's the recommended button, start the crossfade timer after starting the sound
        if isRecommendedButton {
            print("Starting crossfade timer.")
            startCrossfadeTimer()
        }
    }
    
    func stopAllSounds() {
        print("Stopping all sounds")
        
        // Invalidate all timers including the crossfade timer
        crossfadeTimer?.invalidate()
        crossfadeTimer = nil
        
        volumeIncreaseTimer?.invalidate()
        volumeIncreaseTimer = nil
        
        oscillatorFadeTimer?.invalidate()
        oscillatorFadeTimer = nil
        
        // Stop all oscillators and reset their amplitudes
        happyChordOscillators.forEach { 
            $0.stop()
            $0.amplitude = 0.5  // Reset to initial amplitude
        }
        sadChordOscillators.forEach { 
            $0.stop()
            $0.amplitude = 0.4  // Reset to initial amplitude
        }
        anxiousChordOscillators.forEach { 
            $0.stop()
            $0.amplitude = 0.3  // Reset to initial amplitude
        }
        angryOscillators.forEach { 
            $0.stop()
            $0.amplitude = 0.3  // Reset to initial amplitude
        }
        
        // Stop and clear the nature player
        naturePlayer?.pause()
        naturePlayer = nil
        
        audioPlayerManager.stopAudio()
        print("All sounds stopped and reset")
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

    func playAudioFromURL(_ url: URL, completion: (() -> Void)? = nil) {
        audioPlayerManager.playAudio(from: url, completion: completion)
    }
    
    func fetchDownloadURL(for fileName: String, completion: @escaping (URL?) -> Void) {
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

    private func startCrossfadeTimer() {
        crossfadeTimer?.invalidate() // Invalidate any existing timer
        print("Starting crossfade timer")
        
        // Create timer differently
        let timer = Timer(timeInterval: 600, repeats: false) { [weak self] _ in
            print("Timer exists and is firing")
            guard let self = self else {
                print("Self is nil in timer closure")
                return
            }
            
            print("Crossfade timer triggered")
            self.crossfadeToRancheriaFalls()
        }
        
        // Store the reference
        crossfadeTimer = timer
        
        // Schedule the timer on the main run loop
        RunLoop.main.add(timer, forMode: .common)
        
        print("Timer was successfully created and scheduled")
    }

    private func crossfadeToRancheriaFalls() {
        let crossfadeDuration: TimeInterval = 15.0
        print("Starting crossfade to Rancheria Falls over \(crossfadeDuration) seconds")
        
        fetchDownloadURL(for: "2024-09-15-rancheria-falls.wav") { [weak self] url in
            guard let self = self, let url = url else {
                print("Failed to get download URL")
                return
            }

            self.naturePlayer = AVPlayer(url: url)
            self.naturePlayer?.volume = 0.0
            self.naturePlayer?.play()
            print("Playing Rancheria Falls")

            // Store reference to volume increase timer
            self.volumeIncreaseTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
                guard let self = self, let player = self.naturePlayer else {
                    timer.invalidate()
                    return
                }
                
                if player.rate == 0 {
                    player.play()
                }
                player.volume += 0.1 / Float(crossfadeDuration)
                print("Increasing Rancheria Falls volume to \(player.volume)")
                if player.volume >= 1.0 {
                    player.volume = 1.0
                    timer.invalidate()
                    print("Rancheria Falls volume reached maximum")
                }
            }

            // Store reference to oscillator fade timer
            self.oscillatorFadeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                
                let allOscillators = self.happyChordOscillators + 
                                   self.sadChordOscillators + 
                                   self.anxiousChordOscillators + 
                                   self.angryOscillators
                
                var allStopped = true
                allOscillators.forEach { oscillator in
                    oscillator.amplitude -= 0.1 / Float(crossfadeDuration)
                    if oscillator.amplitude > 0 {
                        allStopped = false
                    } else {
                        oscillator.stop()
                    }
                }
                
                if allStopped {
                    timer.invalidate()
                    print("All oscillators stopped")
                }
            }
        }
    }

    func stopAllAudio() {
        print("SoundManager: stopAllAudio called")
        audioPlayerManager.stopAudio()
        print("SoundManager: audioPlayerManager stopped")
        naturePlayer?.pause()
        naturePlayer = nil
        print("SoundManager: naturePlayer cleared")
        
        let allOscillators = happyChordOscillators + 
                           sadChordOscillators + 
                           anxiousChordOscillators + 
                           angryOscillators
        
        allOscillators.forEach { oscillator in
            oscillator.stop()
        }
        print("SoundManager: all oscillators stopped")
    }
}

class AudioPlayerManager: NSObject {
    private var player: AVPlayer?
    private var isObserving = false
    var onPlaybackFinished: (() -> Void)?
    
    func playAudio(from url: URL, completion: (() -> Void)? = nil) {
        print("AudioPlayerManager: starting audio playback at \(Date())")
        player = AVPlayer(url: url)
        
        // Add observer for playback finished
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem
        )
        
        // Add observer for status changes
        if let playerItem = player?.currentItem {
            playerItem.addObserver(self, 
                forKeyPath: "status", 
                options: [.new], 
                context: nil)
            isObserving = true
        }
        
        onPlaybackFinished = completion
        player?.play()
    }
    
    override func observeValue(forKeyPath keyPath: String?, 
                             of object: Any?, 
                             change: [NSKeyValueChangeKey : Any]?, 
                             context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if let item = object as? AVPlayerItem {
                switch item.status {
                case .readyToPlay:
                    print("AudioPlayerManager: Audio ready to play at \(Date())")
                case .failed:
                    print("AudioPlayerManager: Audio failed to load")
                case .unknown:
                    print("AudioPlayerManager: Audio status unknown")
                @unknown default:
                    break
                }
            }
        }
    }
    
    func stopAudio() {
        print("AudioPlayerManager: stopping audio")
        
        // Remove notification observer
        NotificationCenter.default.removeObserver(
            self,
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem
        )
        
        // Safely remove KVO observer
        if isObserving {
            player?.currentItem?.removeObserver(self, forKeyPath: "status")
            isObserving = false
        }
        
        player?.pause()
        player = nil
        print("AudioPlayerManager: player cleared")
    }
    
    @objc private func playerDidFinishPlaying() {
        print("AudioPlayerManager: audio finished playing at \(Date())")
        DispatchQueue.main.async {
            self.onPlaybackFinished?()
        }
        
        // Remove observers
        NotificationCenter.default.removeObserver(
            self,
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem
        )
        
        if isObserving {
            player?.currentItem?.removeObserver(self, forKeyPath: "status")
            isObserving = false
        }
    }
    
    deinit {
        if isObserving {
            player?.currentItem?.removeObserver(self, forKeyPath: "status")
        }
    }
}
