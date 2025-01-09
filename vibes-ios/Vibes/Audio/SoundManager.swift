import Foundation
import AudioKit
import SoundpipeAudioKit

class SoundManager {
    private let engine = AudioEngine()
    private let harmonicOscillators: [Oscillator]
    private let binauralOscillators: [Oscillator]
    private let pinkNoise: PinkNoise
    private var isochronicOscillator: Oscillator?
    private var currentTimer: Timer?
    private var amplitudeModulationTimer: Timer?
    
    private static let baseFrequency: Float = 110
    private static let harmonicRatios: [Float] = [1, 2, 3, 4, 5]
    
    init() {
        harmonicOscillators = SoundManager.harmonicRatios.map { ratio in
            Oscillator(waveform: Table(.sine), frequency: SoundManager.baseFrequency * ratio, amplitude: 0.5)
        }
        
        binauralOscillators = [
            Oscillator(waveform: Table(.sine), frequency: 100, amplitude: 0.5),
            Oscillator(waveform: Table(.sine), frequency: 104, amplitude: 0.5)
        ]
        
        pinkNoise = PinkNoise(amplitude: 0.5)
        
        let carrierFrequency: Float = 440 // A4 note, within audible range
        isochronicOscillator = Oscillator(waveform: Table(.sine), frequency: carrierFrequency, amplitude: 0.8)
        
        engine.output = Mixer(harmonicOscillators)
        
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
            engine.output = Mixer(harmonicOscillators)
            startHarmonicSeries()
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
        }
    }
    
    func stopAllSounds() {
        harmonicOscillators.forEach { $0.stop() }
        binauralOscillators.forEach { $0.stop() }
        pinkNoise.stop()
        isochronicOscillator?.stop()
        amplitudeModulationTimer?.invalidate()
    }
    
    private func startHarmonicSeries() {
        print("Starting harmonic series.")
        harmonicOscillators.forEach { $0.stop() } // Ensure all oscillators are stopped initially
        harmonicOscillators[0].start() // Start with the base frequency
        var currentIndex = 1
        var isAscending = true
        
        currentTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            
            if isAscending {
                if currentIndex < self.harmonicOscillators.count {
                    self.harmonicOscillators[currentIndex].start()
                    self.adjustHarmonicAmplitudes(activeCount: currentIndex + 1)
                    currentIndex += 1
                } else {
                    isAscending = false
                }
            } else {
                if currentIndex > 0 {
                    self.harmonicOscillators[currentIndex - 1].stop()
                    currentIndex -= 1
                    self.adjustHarmonicAmplitudes(activeCount: currentIndex)
                } else {
                    isAscending = true
                }
            }
        }
    }
    
    private func adjustHarmonicAmplitudes(activeCount: Int) {
        let baseAmplitude: Float = 0.5
        let adjustedAmplitude = baseAmplitude / Float(activeCount)
        
        for i in 0..<activeCount {
            harmonicOscillators[i].amplitude = adjustedAmplitude
        }
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
}