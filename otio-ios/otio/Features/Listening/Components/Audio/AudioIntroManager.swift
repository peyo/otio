import Foundation
import AVFoundation

class AudioIntroManager {
    private let natureSoundManager = NatureSoundManager()
    private var isPlayingRecommendedIntro = false
    private var pendingSound: SoundType?
    private var pendingNormalizedScore: Double?
    private var pendingIsRecommended = false
    private var currentSound: SoundType?
    private var isStopping = false
    private var isPlayingEmotionIntro = false
    private var isSkipped = false
    
    var onIntroFinished: ((SoundType, Double?, Bool) -> Void)?
    var onIntroStatusChanged: ((Bool, Bool) -> Void)?
    
    func playIntroFor(sound: SoundType, normalizedScore: Double? = nil, isRecommendedButton: Bool = false) {
        // Reset stopping flag when starting a new sound
        isStopping = false
        currentSound = sound
        
        // Reset intro playing states and notify
        isPlayingRecommendedIntro = false
        isPlayingEmotionIntro = false
        onIntroStatusChanged?(false, false)
        
        print("AudioIntroManager: Playing intro for \(sound.rawValue), isRecommended: \(isRecommendedButton)")
        
        guard let introFile = sound.introAudioFile else {
            print("AudioIntroManager: No intro file found for \(sound.rawValue)")
            // No intro file, call completion immediately
            onIntroFinished?(sound, normalizedScore, isRecommendedButton)
            return
        }
        
        // For recommended sound, we'll play two intros
        if sound == .recommendedSound {
            print("AudioIntroManager: Playing recommended sound intro")
            isPlayingRecommendedIntro = true
            isPlayingEmotionIntro = false
            onIntroStatusChanged?(true, false)
            // Use the global function to determine the specific sound
            pendingSound = determineRecommendedSound(from: normalizedScore ?? 0.5)
            pendingNormalizedScore = normalizedScore
            pendingIsRecommended = true
            
            print("AudioIntroManager: Determined recommended sound: \(pendingSound?.rawValue ?? "none")")
            
            // Play the recommended intro first
            natureSoundManager.playNatureSound(
                fileName: introFile,
                directory: "meditation",
                initialVolume: 1.0
            ) { [weak self] in
                guard let self = self, !self.isStopping else { 
                    print("AudioIntroManager: Stopping after recommended intro")
                    return 
                }
                
                print("AudioIntroManager: Recommended intro finished, waiting to play specific intro")
                // Add a small pause (3 seconds)
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    guard !self.isStopping else { return }
                    
                    // Now play the specific emotion intro
                    if let pendingSound = self.pendingSound {
                        print("AudioIntroManager: Now playing specific intro for \(pendingSound.rawValue)")
                        self.isPlayingRecommendedIntro = false
                        self.isPlayingEmotionIntro = true
                        self.onIntroStatusChanged?(false, true)
                        self.playIntroFor(
                            sound: pendingSound,
                            normalizedScore: self.pendingNormalizedScore,
                            isRecommendedButton: self.pendingIsRecommended
                        )
                    }
                }
            }
        } else {
            // Play the regular intro for emotion sounds
            print("AudioIntroManager: Playing regular intro for \(sound.rawValue)")
            // Set the emotion intro playing state
            isPlayingEmotionIntro = true
            onIntroStatusChanged?(false, true)
            
            natureSoundManager.playNatureSound(
                fileName: introFile,
                directory: "meditation",
                initialVolume: 1.0
            ) { [weak self] in
                guard let self = self, !self.isStopping else { return }
                
                print("AudioIntroManager: Regular intro finished, waiting to start main sound")
                // Reset the emotion intro playing state
                self.isPlayingEmotionIntro = false
                self.onIntroStatusChanged?(false, false)
                
                // Add a small pause (3 seconds)
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    guard !self.isStopping else { return }
                    print("AudioIntroManager: Starting main sound after intro")
                    self.onIntroFinished?(sound, normalizedScore, isRecommendedButton)
                }
            }
        }
    }
    
    func skipIntro() {
        print("AudioIntroManager: Skipping intro")
        natureSoundManager.stopCurrentSound()
        
        if isStopping {
            print("AudioIntroManager: Skip ignored because stopping is in progress")
            return
        }
        
        if isPlayingRecommendedIntro, let pendingSound = pendingSound {
            // If we're playing the recommended intro, skip to the specific emotion intro
            print("AudioIntroManager: Skipping to specific emotion intro")
            isPlayingRecommendedIntro = false
            isPlayingEmotionIntro = true
            onIntroStatusChanged?(false, true)
            playIntroFor(
                sound: pendingSound,
                normalizedScore: pendingNormalizedScore,
                isRecommendedButton: pendingIsRecommended
            )
        } else {
            // If we're playing a specific emotion intro, skip to the main sound
            print("AudioIntroManager: Skipping to main sound")
            // Reset the emotion intro playing state
            isPlayingEmotionIntro = false
            onIntroStatusChanged?(false, false)
            
            // Use the current sound if pendingSound is nil
            let soundToPlay = pendingSound ?? currentSound
            
            if let sound = soundToPlay {
                // Add a small pause (3 seconds)
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    if !self.isStopping {
                        print("AudioIntroManager: Calling onIntroFinished after skip")
                        self.onIntroFinished?(sound, self.pendingNormalizedScore, self.pendingIsRecommended)
                    } else {
                        print("AudioIntroManager: Skipping onIntroFinished because stopping is in progress")
                    }
                }
            }
        }
    }
    
    func stopEverything() {
        print("AudioIntroManager: Stopping everything")
        isStopping = true
        natureSoundManager.stopCurrentSound()
        isPlayingRecommendedIntro = false
        isPlayingEmotionIntro = false
        onIntroStatusChanged?(false, false)
        isSkipped = false
    }
}