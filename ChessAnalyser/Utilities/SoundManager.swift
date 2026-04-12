import AVFoundation
import UIKit

/// Manages chess piece sounds and haptic feedback.
final class SoundManager {
    static let shared = SoundManager()

    private var movePlayer: AVAudioPlayer?
    private var capturePlayer: AVAudioPlayer?
    private var checkPlayer: AVAudioPlayer?

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()

    var soundEnabled = true

    private init() {
        // Activate audio session first
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)

        // Pre-generate sounds
        movePlayer = generateTonePlayer(frequency: 600, duration: 0.06, volume: 0.3)
        capturePlayer = generateTonePlayer(frequency: 400, duration: 0.1, volume: 0.5)
        checkPlayer = generateTonePlayer(frequency: 800, duration: 0.12, volume: 0.4)

        lightImpact.prepare()
        mediumImpact.prepare()
    }

    /// Play move sound + haptic
    func playMove() {
        guard soundEnabled else { return }
        lightImpact.impactOccurred()
        movePlayer?.currentTime = 0
        movePlayer?.play()
    }

    /// Play capture sound + haptic
    func playCapture() {
        guard soundEnabled else { return }
        mediumImpact.impactOccurred()
        capturePlayer?.currentTime = 0
        capturePlayer?.play()
    }

    /// Play check sound + haptic
    func playCheck() {
        guard soundEnabled else { return }
        notification.notificationOccurred(.warning)
        checkPlayer?.currentTime = 0
        checkPlayer?.play()
    }

    /// Play castle sound
    func playCastle() {
        guard soundEnabled else { return }
        lightImpact.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            lightImpact.impactOccurred()
        }
        movePlayer?.currentTime = 0
        movePlayer?.play()
    }

    /// Play checkmate sound
    func playCheckmate() {
        guard soundEnabled else { return }
        heavyImpact.impactOccurred()
        notification.notificationOccurred(.success)
    }

    /// Play appropriate sound for a move result
    func playForMove(isCapture: Bool, isCheck: Bool, isCheckmate: Bool, isCastling: Bool) {
        if isCheckmate {
            playCheckmate()
        } else if isCheck {
            playCheck()
        } else if isCapture {
            playCapture()
        } else if isCastling {
            playCastle()
        } else {
            playMove()
        }
    }

    // MARK: - Tone Generation

    /// Generate a simple sine wave tone as an AVAudioPlayer
    private func generateTonePlayer(frequency: Double, duration: Double, volume: Float) -> AVAudioPlayer? {
        let sampleRate = 44100.0
        let numSamples = Int(sampleRate * duration)

        var samples = [Float](repeating: 0, count: numSamples)
        for i in 0..<numSamples {
            let t = Double(i) / sampleRate
            // Sine wave with exponential decay envelope
            let envelope = exp(-t * 20.0) // Quick decay
            let sample = Float(sin(2.0 * .pi * frequency * t) * envelope)
            samples[i] = sample * volume
        }

        // Create WAV data
        guard let wavData = createWAVData(samples: samples, sampleRate: Int(sampleRate)) else { return nil }

        do {
            let player = try AVAudioPlayer(data: wavData)
            player.prepareToPlay()
            return player
        } catch {
            return nil
        }
    }

    /// Create WAV file data from raw float samples
    private func createWAVData(samples: [Float], sampleRate: Int) -> Data? {
        let numChannels: Int16 = 1
        let bitsPerSample: Int16 = 16
        let bytesPerSample = Int(bitsPerSample / 8)
        let dataSize = samples.count * bytesPerSample

        var data = Data()

        // RIFF header
        data.append(contentsOf: "RIFF".utf8)
        var fileSize = UInt32(36 + dataSize)
        data.append(Data(bytes: &fileSize, count: 4))
        data.append(contentsOf: "WAVE".utf8)

        // fmt chunk
        data.append(contentsOf: "fmt ".utf8)
        var fmtSize: UInt32 = 16
        data.append(Data(bytes: &fmtSize, count: 4))
        var audioFormat: UInt16 = 1 // PCM
        data.append(Data(bytes: &audioFormat, count: 2))
        var channels = UInt16(numChannels)
        data.append(Data(bytes: &channels, count: 2))
        var rate = UInt32(sampleRate)
        data.append(Data(bytes: &rate, count: 4))
        var byteRate = UInt32(sampleRate * Int(numChannels) * bytesPerSample)
        data.append(Data(bytes: &byteRate, count: 4))
        var blockAlign = UInt16(Int(numChannels) * bytesPerSample)
        data.append(Data(bytes: &blockAlign, count: 2))
        var bits = UInt16(bitsPerSample)
        data.append(Data(bytes: &bits, count: 2))

        // data chunk
        data.append(contentsOf: "data".utf8)
        var chunkSize = UInt32(dataSize)
        data.append(Data(bytes: &chunkSize, count: 4))

        // Convert float samples to Int16
        for sample in samples {
            var intSample = Int16(max(-1, min(1, sample)) * Float(Int16.max))
            data.append(Data(bytes: &intSample, count: 2))
        }

        return data
    }
}
