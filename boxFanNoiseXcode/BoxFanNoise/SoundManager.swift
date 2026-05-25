//
//  SoundManager.swift
//  BoxFanNoise
//

import SwiftUI
import AVFoundation
import SuperwallKit

// MARK: - Sound Types

struct SoundType: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let icon: String
    let description: String

    static func == (lhs: SoundType, rhs: SoundType) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static let allSounds: [SoundType] = [
        SoundType(id: "box_fan", name: "Box Fan", icon: "square.fill", description: "Classic box fan with gentle whir"),
        SoundType(id: "oscillating_fan", name: "Oscillating Fan", icon: "arrow.left.arrow.right", description: "Sweeping fan sound"),
        SoundType(id: "industrial_fan", name: "Industrial Fan", icon: "gearshape.2.fill", description: "Powerful workshop fan"),
        SoundType(id: "air_conditioner", name: "Air Conditioner", icon: "air.conditioner.horizontal.fill", description: "Steady AC hum"),
    ]
}

// MARK: - Active Sound (for mixer)

struct ActiveSound: Identifiable, Codable, Equatable {
    let id: String
    var soundId: String
    var volume: Float

    init(soundId: String, volume: Float = 0.5) {
        self.id = UUID().uuidString
        self.soundId = soundId
        self.volume = volume
    }
}

// MARK: - Preset

struct SoundPreset: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var icon: String
    var sounds: [ActiveSound]
    var createdAt: Date = Date()

    static let defaults: [SoundPreset] = [
        SoundPreset(name: "Classic Box Fan", icon: "fanblades.fill", sounds: [
            ActiveSound(soundId: "box_fan", volume: 0.7)
        ]),
        SoundPreset(name: "Cool Breeze", icon: "wind", sounds: [
            ActiveSound(soundId: "box_fan", volume: 0.5),
            ActiveSound(soundId: "oscillating_fan", volume: 0.4)
        ]),
        SoundPreset(name: "Workshop", icon: "gearshape.2.fill", sounds: [
            ActiveSound(soundId: "industrial_fan", volume: 0.6),
            ActiveSound(soundId: "air_conditioner", volume: 0.3)
        ]),
        SoundPreset(name: "Summer Night", icon: "moon.fill", sounds: [
            ActiveSound(soundId: "box_fan", volume: 0.6),
            ActiveSound(soundId: "air_conditioner", volume: 0.2)
        ]),
    ]
}

// MARK: - Sound Engine

@Observable
class SoundEngine {
    static let shared = SoundEngine()

    var isPlaying = false
    var activeSounds: [ActiveSound] = []
    var masterVolume: Float = 1.0
    var fadeInDuration: TimeInterval = 0
    var fadeOutDuration: TimeInterval = 3

    private var audioEngine: AVAudioEngine?
    private var playerNodes: [String: AVAudioPlayerNode] = [:]
    private var buffers: [String: AVAudioPCMBuffer] = [:]
    private var fadeTimer: Timer?

    // Timer
    var selectedTimer: TimerOption = .off
    var timerRemaining: Int = 0
    private var timer: Timer?

    var timerDisplayString: String {
        let minutes = timerRemaining / 60
        let seconds = timerRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private init() {
        setupAudioEngine()
    }

    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    /// Sounds that are free for everyone. Anything else is gated by Superwall.
    static let freeSoundIds: Set<String> = ["box_fan"]

    /// Sleep timer options that are free for everyone. Anything else is gated.
    static let freeTimerOptions: Set<TimerOption> = [.off, .fifteen, .thirty]

    func addSound(_ soundType: SoundType, volume: Float = 0.5) {
        if SoundEngine.freeSoundIds.contains(soundType.id) {
            _addSound(soundType, volume: volume)
        } else {
            Superwall.shared.register(placement: "campaign_trigger") { [weak self] in
                self?._addSound(soundType, volume: volume)
            }
        }
    }

    private func _addSound(_ soundType: SoundType, volume: Float = 0.5) {
        guard !activeSounds.contains(where: { $0.soundId == soundType.id }) else { return }

        let activeSound = ActiveSound(soundId: soundType.id, volume: volume)
        activeSounds.append(activeSound)

        if isPlaying {
            startSound(activeSound, soundType: soundType)
        }
    }

    func removeSound(_ soundId: String) {
        stopSound(soundId)
        activeSounds.removeAll { $0.soundId == soundId }
    }

    func updateVolume(for soundId: String, volume: Float) {
        if let index = activeSounds.firstIndex(where: { $0.soundId == soundId }) {
            activeSounds[index].volume = volume
            playerNodes[soundId]?.volume = volume * masterVolume
        }
    }

    func play() {
        // If a fade-out is in progress, cancel it and resume immediately.
        // No need to restart engine or session — they're still running.
        if fadeTimer != nil {
            cancelFade()
            isPlaying = true
            for (id, player) in playerNodes {
                if !player.isPlaying { player.play() }
                if let active = activeSounds.first(where: { $0.soundId == id }) {
                    player.volume = active.volume * masterVolume
                }
            }
            if selectedTimer != .off { startTimer() }
            return
        }

        guard !isPlaying else { return }
        guard !activeSounds.isEmpty else { return }
        guard let audioEngine = audioEngine else { return }

        for activeSound in activeSounds {
            if let soundType = SoundType.allSounds.first(where: { $0.id == activeSound.soundId }) {
                setupPlayerNode(activeSound, soundType: soundType)
            }
        }

        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
            return
        }

        isPlaying = true

        for (_, player) in playerNodes {
            player.play()
        }

        if selectedTimer != .off { startTimer() }

        if !StatsManager.shared.isInSession {
            StatsManager.shared.startSession(soundIds: activeSounds.map { $0.soundId })
        }
    }

    private func setupPlayerNode(_ activeSound: ActiveSound, soundType: SoundType) {
        guard let audioEngine = audioEngine else { return }
        guard playerNodes[soundType.id] == nil else { return }

        let playerNode = AVAudioPlayerNode()
        audioEngine.attach(playerNode)

        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: format)

        let buffer = generateNoise(for: soundType.id)
        buffers[soundType.id] = buffer
        playerNodes[soundType.id] = playerNode

        playerNode.volume = activeSound.volume * masterVolume
        playerNode.scheduleBuffer(buffer, at: nil, options: .loops)
    }

    /// User-initiated pause. Always instant — no fade delay.
    func stop() {
        guard isPlaying else { return }
        isPlaying = false
        stopTimer()
        cancelFade()
        stopImmediately()
    }

    /// Used by the sleep timer when it expires — fades out gracefully so the
    /// user isn't jolted awake by an abrupt cut-off.
    private func stopWithFade() {
        guard isPlaying else { return }
        isPlaying = false
        stopTimer()
        if fadeOutDuration > 0 {
            fadeOut { [weak self] in self?.stopImmediately() }
        } else {
            stopImmediately()
        }
    }

    private func stopImmediately() {
        // player.stop() clears the scheduled buffer — if we leave the player
        // attached, the next play() will hit a player with no audio scheduled
        // and produce silence. Detach + clear so next play() rebuilds cleanly.
        for (_, player) in playerNodes {
            player.stop()
            audioEngine?.detach(player)
        }
        playerNodes.removeAll()
        buffers.removeAll()
        masterVolume = 1.0
        StatsManager.shared.endSession()
    }

    private func cancelFade() {
        fadeTimer?.invalidate()
        fadeTimer = nil
        masterVolume = 1.0
    }

    private func fadeOut(completion: @escaping () -> Void) {
        let steps = 20
        let stepDuration = fadeOutDuration / Double(steps)
        let startingVolume = masterVolume
        let volumeStep = startingVolume / Float(steps)
        var currentStep = 0

        fadeTimer?.invalidate()
        fadeTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            currentStep += 1
            let newVolume = startingVolume - (volumeStep * Float(currentStep))

            for (_, player) in self.playerNodes {
                player.volume = max(0, newVolume)
            }

            if currentStep >= steps {
                timer.invalidate()
                self.fadeTimer = nil
                self.masterVolume = 1.0
                completion()
            }
        }
    }

    func toggle() {
        if isPlaying {
            stop()
        } else {
            play()
        }
    }

    private func startSound(_ activeSound: ActiveSound, soundType: SoundType) {
        setupPlayerNode(activeSound, soundType: soundType)
        playerNodes[soundType.id]?.play()
    }

    private func stopSound(_ soundId: String) {
        playerNodes[soundId]?.stop()
        if let player = playerNodes[soundId], let audioEngine = audioEngine {
            audioEngine.detach(player)
        }
        playerNodes.removeValue(forKey: soundId)
        buffers.removeValue(forKey: soundId)
    }

    // MARK: - Timer

    func setTimer(_ option: TimerOption) {
        if SoundEngine.freeTimerOptions.contains(option) {
            _setTimer(option)
        } else {
            Superwall.shared.register(placement: "campaign_trigger") { [weak self] in
                self?._setTimer(option)
            }
        }
    }

    private func _setTimer(_ option: TimerOption) {
        selectedTimer = option
        if option == .off {
            stopTimer()
        } else if isPlaying {
            startTimer()
        }
    }

    private func startTimer() {
        stopTimer()
        timerRemaining = selectedTimer.seconds

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.timerRemaining > 0 {
                self.timerRemaining -= 1
            } else {
                // Sleep timer expired — fade out gracefully (not abrupt).
                self.stopWithFade()
                self.selectedTimer = .off
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        timerRemaining = 0
    }

    // MARK: - Presets

    func loadPreset(_ preset: SoundPreset) {
        let containsPremium = preset.sounds.contains { !SoundEngine.freeSoundIds.contains($0.soundId) }
        if !containsPremium {
            _loadPreset(preset)
        } else {
            Superwall.shared.register(placement: "campaign_trigger") { [weak self] in
                self?._loadPreset(preset)
            }
        }
    }

    private func _loadPreset(_ preset: SoundPreset) {
        for sound in activeSounds {
            stopSound(sound.soundId)
        }
        activeSounds = []

        for sound in preset.sounds {
            if let soundType = SoundType.allSounds.first(where: { $0.id == sound.soundId }) {
                // Use private path so we don't double-trigger the paywall here
                _addSound(soundType, volume: sound.volume)
            }
        }
    }

    // MARK: - Noise Generation

    private func generateNoise(for soundId: String) -> AVAudioPCMBuffer {
        let sampleRate: Double = 44100
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frameCount = AVAudioFrameCount(sampleRate * 6)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        guard let channelData = buffer.floatChannelData?[0] else { return buffer }

        switch soundId {
        case "box_fan":
            generateBoxFan(channelData: channelData, frameCount: Int(frameCount))
        case "oscillating_fan":
            generateOscillatingFan(channelData: channelData, frameCount: Int(frameCount), sampleRate: sampleRate)
        case "industrial_fan":
            generateIndustrialFan(channelData: channelData, frameCount: Int(frameCount))
        case "air_conditioner":
            generateAirConditioner(channelData: channelData, frameCount: Int(frameCount))
        default:
            generateBoxFan(channelData: channelData, frameCount: Int(frameCount))
        }

        return buffer
    }

    private func generateBoxFan(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        var lastValue: Float = 0
        var nextClickFrame = Int.random(in: 20000...80000)

        for frame in 0..<frameCount {
            let white = Float.random(in: -1...1)
            lastValue = (lastValue + white * 0.02)
            lastValue = max(-1, min(1, lastValue))

            var sample = lastValue

            if frame == nextClickFrame {
                sample += Float.random(in: 0.05...0.15)
                nextClickFrame = frame + Int.random(in: 22000...132000)
            }

            channelData[frame] = max(-1, min(1, sample))
        }
    }

    private func generateOscillatingFan(channelData: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double) {
        var lastValue: Float = 0
        let oscillationPeriod = sampleRate * 4

        for frame in 0..<frameCount {
            let white = Float.random(in: -1...1)
            lastValue = (lastValue + white * 0.02)
            lastValue = max(-1, min(1, lastValue))

            let oscillation = sin(Double(frame) / oscillationPeriod * .pi * 2)
            let volumeMod = Float(0.5 + oscillation * 0.3)

            channelData[frame] = lastValue * volumeMod
        }
    }

    private func generateIndustrialFan(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        var lastValue: Float = 0

        for frame in 0..<frameCount {
            let white = Float.random(in: -1...1)
            lastValue = (lastValue + white * 0.025)
            lastValue = max(-1, min(1, lastValue))

            let hum = sin(Float(frame) * 0.003) * 0.1

            channelData[frame] = max(-1, min(1, lastValue + hum))
        }
    }

    private func generateAirConditioner(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        var lastValue: Float = 0

        for frame in 0..<frameCount {
            let white = Float.random(in: -1...1)
            lastValue = (lastValue + white * 0.015)
            lastValue = max(-1, min(1, lastValue))

            let hum = sin(Float(frame) * 0.002) * 0.05

            channelData[frame] = max(-1, min(1, lastValue * 0.7 + hum))
        }
    }
}

// MARK: - Timer Options

enum TimerOption: String, CaseIterable {
    case off = "Off"
    case fifteen = "15m"
    case thirty = "30m"
    case sixty = "1h"
    case ninety = "90m"
    case twoHours = "2h"

    var label: String { rawValue }

    var seconds: Int {
        switch self {
        case .off: return 0
        case .fifteen: return 15 * 60
        case .thirty: return 30 * 60
        case .sixty: return 60 * 60
        case .ninety: return 90 * 60
        case .twoHours: return 120 * 60
        }
    }
}
