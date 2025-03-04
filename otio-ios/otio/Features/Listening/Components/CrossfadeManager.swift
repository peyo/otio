import Foundation

class CrossfadeManager {
    private weak var oscillatorManager: OscillatorManager?
    private weak var natureSoundManager: NatureSoundManager?
    
    private var crossfadeTimer: Timer?
    private var isTransitioning = false
    
    init(oscillatorManager: OscillatorManager, natureSoundManager: NatureSoundManager) {
        self.oscillatorManager = oscillatorManager
        self.natureSoundManager = natureSoundManager
    }
    
    func startCrossfadeTimer(duration: TimeInterval = 600) { // 10 minutes default
        crossfadeTimer?.invalidate()
        print("Starting crossfade timer for \(duration) seconds")
        
        crossfadeTimer = Timer(timeInterval: duration, repeats: false) { [weak self] _ in
            print("Crossfade timer triggered")
            self?.crossfadeToRancheriaFalls()
        }
        
        RunLoop.main.add(crossfadeTimer!, forMode: .common)
        print("Crossfade timer scheduled")
    }
    
    func crossfadeToRancheriaFalls() {
        guard !isTransitioning else { return }
        isTransitioning = true
        
        let crossfadeDuration: TimeInterval = 15.0
        print("Starting crossfade to Rancheria Falls over \(crossfadeDuration) seconds")
        
        // Start Rancheria Falls with 0 volume
        natureSoundManager?.playNatureSound(
            fileName: "2024-09-15-rancheria-falls.wav",
            initialVolume: 0.0
        )
        
        // Fade in Rancheria Falls
        natureSoundManager?.fadeIn(duration: crossfadeDuration)
        
        // Fade out all emotional sounds
        oscillatorManager?.stopAllSounds()
        
        // Reset state after transition
        DispatchQueue.main.asyncAfter(deadline: .now() + crossfadeDuration) { [weak self] in
            self?.isTransitioning = false
            print("Crossfade complete")
        }
    }
    
    func crossfadeBetweenEmotions(from currentType: SoundType, to newType: SoundType, duration: TimeInterval = 2.0) {
        guard !isTransitioning else { return }
        isTransitioning = true
        
        print("Starting crossfade from \(currentType) to \(newType)")
        
        // Start fading out current emotion
        oscillatorManager?.fadeOut(currentType, duration: duration)
        
        // Start new emotion after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + duration * 0.5) { [weak self] in
            self?.oscillatorManager?.startSound(newType)
            
            // Reset state after transition
            DispatchQueue.main.asyncAfter(deadline: .now() + duration * 0.5) {
                self?.isTransitioning = false
                print("Emotion crossfade complete")
            }
        }
    }
    
    func cancelCrossfade() {
        crossfadeTimer?.invalidate()
        crossfadeTimer = nil
        isTransitioning = false
        print("Crossfade cancelled")
    }
    
    deinit {
        cancelCrossfade()
    }
}