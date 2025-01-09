import Foundation
import AudioKit
import SoundpipeAudioKit

class SoundManager {
    private let engine = AudioEngine()
    private let harmonicOscillators: [Oscillator]
    private let binauralOscillators: [Oscillator]
    private let pinkNoise: PinkNoise
    private let isochronicOscillator: Oscillator
    private var currentTimer: Timer?
    private var amplitudeModulationTimer: Timer?
    
    private static let baseFrequency: Float = 110
    private static let harmonicRatios: [Float] = [1, 2, 3, 4, 5]
    
    init() {
        harmonicOscillators = SoundManager.harmonicRatios.map { ratio in
            Oscillator(waveform: Table(.sine), frequency: SoundManager.baseFrequency * ratio, amplitude: 0.2)
        }
        
        binauralOscillators = [
            Oscillator(waveform: Table(.sine), frequency: 100, amplitude: 0.2),
            Oscillator(waveform: Table(.sine), frequency: 104, amplitude: 0.2)
        ]
        
        pinkNoise = PinkNoise(amplitude: 0.2)
        
        isochronicOscillator = Oscillator(waveform: Table(.sine), frequency: 10, amplitude: 0.5)
        
        engine.output = isochronicOscillator
        
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
        case .harmonicSeries:
            startHarmonicSeries()
        case .binauralBeats:
            startBinauralBeats()
        case .pinkNoise:
            pinkNoise.start()
        case .isochronicTone:
            startIsochronicTone()
        }
    }
    
    func stopAllSounds() {
        currentTimer?.invalidate()
        harmonicOscillators.forEach { $0.stop() }
        binauralOscillators.forEach { $0.stop() }
        pinkNoise.stop()
        isochronicOscillator.stop()
        amplitudeModulationTimer?.invalidate()
    }
    
    private func startHarmonicSeries() {
        // Start with base frequency
        harmonicOscillators[0].start()
        var currentIndex = 1
        var isAscending = true
        
        currentTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            
            if isAscending {
                if currentIndex < self.harmonicOscillators.count {
                    self.harmonicOscillators[currentIndex].start()
                    currentIndex += 1
                } else {
                    isAscending = false
                }
            } else {
                if currentIndex > 0 {
                    self.harmonicOscillators[currentIndex - 1].stop()
                    currentIndex -= 1
                } else {
                    isAscending = true
                }
            }
        }
    }
    
    private func startBinauralBeats() {
        binauralOscillators.forEach { $0.start() }
    }
    
    func startIsochronicTone() {
        print("Starting isochronic tone.")
        isochronicOscillator.start()
        startAmplitudeModulation()
    }
    
    private func startAmplitudeModulation() {
        amplitudeModulationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let newAmplitude = 0.1 + 0.1 * sin(2 * .pi * 0.5 * Date().timeIntervalSinceReferenceDate)
            self.isochronicOscillator.amplitude = AUValue(newAmplitude)
            print("Isochronic amplitude: \(newAmplitude)")
        }
    }
}