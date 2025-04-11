import Foundation
import AudioKit
import SoundpipeAudioKit
import AudioKitEX
import AVFoundation

class EnhancedBinauralGenerator {
    private var leftOscillator: Oscillator?
    private var rightOscillator: Oscillator?
    private var harmonicOscillator: Oscillator?
    private var limiter: PeakLimiter?
    private let engine: AudioEngine
    private var isPlaying = false
    
    private struct FreqConstants {
        static let carrierBase: Float = 108.0  // 432/4 Hz - two octaves lower
        static let maxBeatFreq: Float = 12.0
        static let harmonicRatio: Float = 2.02
        static let harmonicVolume: Float = 0.1
        static let mixerVolume: Float = 0.7
        static let limiterPreGain: Float = 0.0
    }
    
    init(engine: AudioEngine) {
        self.engine = engine
        print("\n=== EnhancedBinaural: Starting Initialization ===")
        setupOscillators()
        print("=== EnhancedBinaural: Initialization Complete ===\n")
    }
    
    private func setupOscillators() {
        print("EnhancedBinaural: Creating oscillators...")
        
        leftOscillator = Oscillator(waveform: Table(.sine))
        rightOscillator = Oscillator(waveform: Table(.sine))
        harmonicOscillator = Oscillator(waveform: Table(.sine))
        
        if let left = leftOscillator,
           let right = rightOscillator,
           let harmonic = harmonicOscillator {
            
            let mixer = Mixer([left, right, harmonic])
            mixer.volume = FreqConstants.mixerVolume
            
            limiter = PeakLimiter(mixer)
            if let limiter = limiter {
                limiter.preGain = FreqConstants.limiterPreGain
                limiter.attackTime = 0.001
                limiter.decayTime = 0.05
                print("EnhancedBinaural: PeakLimiter configured")
            }
            
            left.amplitude = 0.0
            right.amplitude = 0.0
            harmonic.amplitude = 0.0
            
            engine.output = limiter
            
            print("EnhancedBinaural: Signal chain completed")
        }
    }
    
    func start(frequency: Float) {
        print("\n=== EnhancedBinaural: Starting Sound ===")
        guard let left = leftOscillator,
              let right = rightOscillator,
              let harmonic = harmonicOscillator else {
            print("EnhancedBinaural: No oscillators available!")
            return
        }
        
        guard !isPlaying else {
            print("EnhancedBinaural: Already playing")
            return
        }
        
        do {
            let beatFreq = min(frequency, FreqConstants.maxBeatFreq)
            let leftFreq = FreqConstants.carrierBase
            let rightFreq = leftFreq + beatFreq
            let harmonicFreq = leftFreq * FreqConstants.harmonicRatio
            
            left.frequency = leftFreq
            right.frequency = rightFreq
            harmonic.frequency = harmonicFreq
            
            print("EnhancedBinaural: Setting frequencies:")
            print("- Left: \(leftFreq)Hz")
            print("- Right: \(rightFreq)Hz")
            print("- Beat: \(beatFreq)Hz")
            print("- Harmonic: \(harmonicFreq)Hz")
            
            if !engine.avEngine.isRunning {
                try engine.start()
                print("EnhancedBinaural: Engine started")
            }
            
            left.start()
            right.start()
            harmonic.start()
            
            print("EnhancedBinaural: Oscillators started")
            
            let baseAmp: Float = 0.3
            left.$amplitude.ramp(to: baseAmp, duration: 0.5)
            right.$amplitude.ramp(to: baseAmp, duration: 0.5)
            harmonic.$amplitude.ramp(to: FreqConstants.harmonicVolume, duration: 0.5)
            
            try AVAudioSession.sharedInstance().setActive(true)
            isPlaying = true
            
        } catch {
            print("EnhancedBinaural: Error: \(error)")
        }
    }
    
    func stop() {
        guard isPlaying else {
            print("EnhancedBinaural: Already stopped")
            return
        }
        
        print("EnhancedBinaural: Stopping sound")
        
        // Immediately mark as not playing so new sounds can start
        isPlaying = false
        
        // Start fade out
        leftOscillator?.$amplitude.ramp(to: 0.0, duration: 0.3)
        rightOscillator?.$amplitude.ramp(to: 0.0, duration: 0.3)
        harmonicOscillator?.$amplitude.ramp(to: 0.0, duration: 0.3)
        
        // Clean up after fade
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.leftOscillator?.stop()
            self?.rightOscillator?.stop()
            self?.harmonicOscillator?.stop()
            
            try? AVAudioSession.sharedInstance().setActive(false)
            print("EnhancedBinaural: Fully stopped")
        }
    }
    
    func fadeOut(duration: TimeInterval) {
        print("EnhancedBinaural: Fading out")
        leftOscillator?.$amplitude.ramp(to: 0.0, duration: Float(duration))
        rightOscillator?.$amplitude.ramp(to: 0.0, duration: Float(duration))
    }
    
    func setVolume(_ volume: Float) {
        let clampedVolume = max(0, min(1, volume))
        let baseAmp = clampedVolume * 0.3
        
        leftOscillator?.$amplitude.ramp(to: baseAmp, duration: 0.1)
        rightOscillator?.$amplitude.ramp(to: baseAmp, duration: 0.1)
        harmonicOscillator?.$amplitude.ramp(to: baseAmp * FreqConstants.harmonicVolume, duration: 0.1)
    }
}
