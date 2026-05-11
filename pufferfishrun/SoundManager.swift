//
//  SoundManager.swift
//  pufferfishrun
//
//  Created by Daniël Hommersom on 10/05/2026.
//

import AVFoundation

class SoundManager {

    static let shared = SoundManager()
    private var audioEngine = AVAudioEngine()
    private var playerNode = AVAudioPlayerNode()
    private var audioFormat: AVAudioFormat!
    
    var isMuted: Bool {
        get {
            UserDefaults.standard.bool(forKey: "isMuted")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "isMuted")
            audioEngine.mainMixerNode.outputVolume = newValue ? 0.0 : 1.0
        }
    }

    private init() {
        // Use the mixer's output format to ensure compatibility
        audioFormat = audioEngine.mainMixerNode.outputFormat(forBus: 0)
        
        audioEngine.attach(playerNode)
        audioEngine.connect(
            playerNode,
            to: audioEngine.mainMixerNode,
            format: audioFormat
        )
        try? audioEngine.start()
        
        // Apply saved mute state on launch
        audioEngine.mainMixerNode.outputVolume = isMuted ? 0.0 : 1.0
    }

    // MARK: - Inflate sound
    // Short rising bubble pop
    func playInflate() {
        guard !isMuted else { return }
        
        let sampleRate = audioFormat.sampleRate
        let channelCount = audioFormat.channelCount
        let duration: Double = 0.12
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: audioFormat,
            frameCapacity: frameCount)
        else { return }

        buffer.frameLength = frameCount
        
        // Generate sound for each channel
        for channel in 0..<Int(channelCount) {
            guard let data = buffer.floatChannelData?[channel] else { continue }
            
            for i in 0..<Int(frameCount) {
                let t = Double(i) / sampleRate
                // Rising frequency from 300Hz to 800Hz
                let freq = 300.0 + (800.0 - 300.0) * t / duration
                // Amplitude envelope: quick attack, fast decay
                let envelope = exp(-t * 18.0)
                // Clean sine wave
                data[i] = Float(
                    sin(2.0 * .pi * freq * t) * envelope * 0.6
                )
            }
        }

        playerNode.stop()
        playerNode.scheduleBuffer(buffer, at: nil)
        if !playerNode.isPlaying {
            playerNode.play()
        }
    }

    // MARK: - Game over sound
    // Descending wah-wah fail sound
    func playGameOver() {
        let sampleRate = audioFormat.sampleRate
        let channelCount = audioFormat.channelCount
        let duration: Double = 0.6
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: audioFormat,
            frameCapacity: frameCount)
        else { return }

        buffer.frameLength = frameCount
        
        // Generate sound for each channel
        for channel in 0..<Int(channelCount) {
            guard let data = buffer.floatChannelData?[channel] else { continue }
            
            for i in 0..<Int(frameCount) {
                let t = Double(i) / sampleRate
                // Descending frequency from 500Hz to 150Hz
                let freq = 500.0 - (350.0 * t / duration)
                // Slow decay envelope
                let envelope = exp(-t * 3.5)
                // Two oscillators for wah effect
                let osc1 = sin(2.0 * .pi * freq * t)
                let osc2 = sin(2.0 * .pi * freq * 1.5 * t) * 0.3
                data[i] = Float(
                    (osc1 + osc2) * envelope * 0.5)
            }
        }

        playerNode.stop()
        playerNode.scheduleBuffer(buffer, at: nil)
        if !playerNode.isPlaying {
            playerNode.play()
        }
    }
}
