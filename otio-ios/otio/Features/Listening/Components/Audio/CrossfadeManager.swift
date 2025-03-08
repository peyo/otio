import Foundation

class CrossfadeManager {
    private weak var oscillatorManager: OscillatorManager?
    private weak var natureSoundManager: NatureSoundManager?
    
    private var crossfadeTimer: Timer?
    private var fadeTimer: Timer?
    private var isTransitioning = false
    private var currentVolume: Float = 0.0
    
    init(oscillatorManager: OscillatorManager, natureSoundManager: NatureSoundManager) {
        self.oscillatorManager = oscillatorManager
        self.natureSoundManager = natureSoundManager
    }
    
    func startCrossfadeTimer(duration: TimeInterval = 600) { // 10 minutes (600) before crossfading
        crossfadeTimer?.invalidate()
        print("CrossfadeManager: Starting crossfade timer for \(duration) seconds")
        
        crossfadeTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            print("CrossfadeManager: Timer fired - initiating crossfade")
            self?.crossfadeToRancheriaFalls()
        }
        
        print("CrossfadeManager: Timer scheduled")
    }
    
    func crossfadeToRancheriaFalls() {
        guard !isTransitioning else {
            print("CrossfadeManager: Already transitioning, skipping")
            return
        }
        
        print("CrossfadeManager: Beginning transition")
        isTransitioning = true
        
        let crossfadeDuration: TimeInterval = 15.0
        print("CrossfadeManager: Starting crossfade over \(crossfadeDuration) seconds")
        
        // Start nature sound at 0 volume
        print("CrossfadeManager: Starting Rancheria Falls with 0 volume")
        natureSoundManager?.playNatureSound(
            fileName: "2024-09-15-rancheria-falls.mp3",
            initialVolume: 0.0
        ) {
            // This closure will be called when the nature sound finishes playing
            print("CrossfadeManager: Nature sound playback finished")
            self.natureSoundManager?.stopCurrentSound()
            self.isTransitioning = false
            NotificationCenter.default.post(name: .soundPlaybackFinished, object: nil)
        }
        
        // Start the volume crossfade
        fadeTimer?.invalidate()
        currentVolume = 0.0
        
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            // Increment nature sound volume up
            self.currentVolume += 0.1 / Float(crossfadeDuration)
            self.natureSoundManager?.setVolume(self.currentVolume)
            
            // Decrement oscillator volume down
            self.oscillatorManager?.setVolume(1.0 - self.currentVolume)
            
            if self.currentVolume >= 1.0 {
                self.currentVolume = 1.0
                self.natureSoundManager?.setVolume(1.0)
                self.oscillatorManager?.setVolume(0.0)
                timer.invalidate()
                self.fadeTimer = nil
                self.isTransitioning = false
                print("CrossfadeManager: Crossfade complete")
            }
        }
    }
    
    func cancelCrossfade() {
        crossfadeTimer?.invalidate()
        crossfadeTimer = nil
        fadeTimer?.invalidate()
        fadeTimer = nil
        isTransitioning = false
        print("CrossfadeManager: Crossfade cancelled")
    }
    
    deinit {
        cancelCrossfade()
    }
}