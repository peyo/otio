import Foundation
import AudioKit
import SoundpipeAudioKit
import AVFoundation

class EnhancedBinauralGenerator {
    private var leftOscillator: Oscillator?
    private var rightOscillator: Oscillator?
    private var breathingLFO: Oscillator?
    private var harmonicOscillator: Oscillator?
    private var reverb: Reverb?  // Add reverb node
    private let engine: AudioEngine
    private var isPlaying = false  // Track playing state
    
    // Constants for frequency calculations
    private struct FreqConstants {
        static let carrierBase: Float = 100.0  // Base carrier frequency
        static let maxBeatFreq: Float = 12.0   // Maximum binaural beat frequency
        static let breathingRate: Float = 1.0   // 1 Hz breathing rate
        static let breathingDepth: Float = 0.15  // Breathing modulation depth
        static let harmonicRatio: Float = 2.02  // Slightly detuned from 2.0
        static let harmonicVolume: Float = 0.1  // 10% volume
        static let reverbMix: Float = 0.2      // 20% wet signal
    }
    
    init(engine: AudioEngine) {
        self.engine = engine
        print("\n=== EnhancedBinaural: Starting Initialization ===")
        setupOscillators()
        print("=== EnhancedBinaural: Initialization Complete ===\n")
    }
    
    private func setupOscillators() {
        print("EnhancedBinaural: Creating oscillators...")
        
        // Create all oscillators
        leftOscillator = Oscillator(waveform: Table(.sine))
        rightOscillator = Oscillator(waveform: Table(.sine))
        harmonicOscillator = Oscillator(waveform: Table(.sine))
        breathingLFO = Oscillator(waveform: Table(.sine))
        
        if let left = leftOscillator,
           let right = rightOscillator,
           let harmonic = harmonicOscillator,
           let breath = breathingLFO {
            
            // Configure breathing LFO
            breath.frequency = FreqConstants.breathingRate
            breath.amplitude = FreqConstants.breathingDepth
            
            // Create mixer for oscillators
            let mixer = Mixer([left, right, harmonic])
            mixer.volume = 1.0
            
            // Create and configure reverb
            reverb = Reverb(mixer)
            if let reverb = reverb {
                reverb.dryWetMix = FreqConstants.reverbMix
                print("EnhancedBinaural: Reverb configured")
            }
            
            // Set initial states
            left.amplitude = 0.0
            right.amplitude = 0.0
            harmonic.amplitude = 0.0
            
            // Connect breathing LFO
            breath.start()
            
            // Connect reverb to engine
            engine.output = reverb
            
            print("EnhancedBinaural: Signal chain completed")
        }
    }
    
    func start(frequency: Float) {
        print("\n=== EnhancedBinaural: Starting Sound ===")
        guard let left = leftOscillator,
              let right = rightOscillator,
              let harmonic = harmonicOscillator,
              let breath = breathingLFO else {
            print("EnhancedBinaural: No oscillators available!")
            return
        }
        
        // Don't start if already playing
        guard !isPlaying else {
            print("EnhancedBinaural: Already playing")
            return
        }
        
        do {
            // Calculate frequencies
            let beatFreq = min(frequency, FreqConstants.maxBeatFreq)
            let leftFreq = FreqConstants.carrierBase
            let rightFreq = leftFreq + beatFreq
            let harmonicFreq = leftFreq * FreqConstants.harmonicRatio
            
            // Set frequencies
            left.frequency = leftFreq
            right.frequency = rightFreq
            harmonic.frequency = harmonicFreq
            breath.frequency = FreqConstants.breathingRate
            
            print("EnhancedBinaural: Setting frequencies:")
            print("- Left: \(leftFreq)Hz")
            print("- Right: \(rightFreq)Hz")
            print("- Beat: \(beatFreq)Hz")
            print("- Harmonic: \(harmonicFreq)Hz")
            print("- Breathing: \(FreqConstants.breathingRate)Hz")
            print("- Reverb Mix: \(FreqConstants.reverbMix * 100)%")
            
            // Ensure engine is running
            if !engine.avEngine.isRunning {
                try engine.start()
                print("EnhancedBinaural: Engine started")
            }
            
            // Start oscillators
            left.start()
            right.start()
            harmonic.start()
            breath.start()
            
            print("EnhancedBinaural: Oscillators started")
            
            // Base amplitude for carriers (slightly reduced to allow for breathing modulation)
            let baseAmp: Float = 0.4  // Reduced from 0.45 to allow headroom for modulation
            
            // Set amplitudes with ramping
            left.$amplitude.ramp(to: baseAmp, duration: 0.5)
            right.$amplitude.ramp(to: baseAmp, duration: 0.5)
            harmonic.$amplitude.ramp(to: FreqConstants.harmonicVolume, duration: 0.5)
            breath.$amplitude.ramp(to: FreqConstants.breathingDepth, duration: 0.5)
            
            print("EnhancedBinaural: Amplitudes set and ramping")
            
            // Keep strong reference to engine
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
        
        // Ramp down amplitudes
        leftOscillator?.$amplitude.ramp(to: 0.0, duration: 0.1)
        rightOscillator?.$amplitude.ramp(to: 0.0, duration: 0.1)
        harmonicOscillator?.$amplitude.ramp(to: 0.0, duration: 0.1)
        breathingLFO?.$amplitude.ramp(to: 0.0, duration: 0.1)
        
        // Allow reverb tail to decay naturally
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            // Stop oscillators after reverb tail starts
            self?.leftOscillator?.stop()
            self?.rightOscillator?.stop()
            self?.harmonicOscillator?.stop()
            self?.breathingLFO?.stop()
            self?.isPlaying = false
        }
    }
    
    func fadeOut(duration: TimeInterval) {
        print("EnhancedBinaural: Fading out")
        leftOscillator?.$amplitude.ramp(to: 0.0, duration: Float(duration))
        rightOscillator?.$amplitude.ramp(to: 0.0, duration: Float(duration))
    }
}