//
//  SoundsView.swift
//  BoxFanNoise
//

import SwiftUI
import SuperwallKit
import Lottie

struct SoundsView: View {
    @State private var engine = SoundEngine.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                topBar
                    .padding(.top, 12)

                FanCenterpiece(isPlaying: engine.isPlaying)
                    .frame(height: 260)

                playButton
                soundGrid

                if !engine.activeSounds.isEmpty {
                    mixSection
                }

                timerSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    // MARK: Top bar — Get Premium

    private var topBar: some View {
        HStack {
            Spacer()
            Button {
                Superwall.shared.register(placement: "campaign_trigger")
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill")
                    Text("Get Premium")
                }
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.65, blue: 0.0),
                                     Color(red: 1.0, green: 0.45, blue: 0.0)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                )
            }
        }
    }

    // MARK: Play button

    private var playButton: some View {
        Button {
            engine.toggle()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: engine.isPlaying ? "pause.fill" : "play.fill")
                Text(engine.isPlaying ? "Pause" : "Play")
                    .font(.system(.title3, design: .rounded, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 40)
            .frame(height: 54)
            .background(Capsule().fill(Color.accentBlue))
        }
        .disabled(engine.activeSounds.isEmpty)
        .opacity(engine.activeSounds.isEmpty ? 0.45 : 1.0)
    }

    // MARK: Sound grid (2 columns)

    private var soundGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(SoundType.allSounds) { sound in
                SoundCard(
                    sound: sound,
                    isActive: engine.activeSounds.contains(where: { $0.soundId == sound.id }),
                    isPremium: !SoundEngine.freeSoundIds.contains(sound.id),
                    onTap: {
                        if engine.activeSounds.contains(where: { $0.soundId == sound.id }) {
                            engine.removeSound(sound.id)
                        } else {
                            engine.addSound(sound)
                        }
                    }
                )
            }
        }
    }

    // MARK: Mix section

    private var mixSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Mix")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
            }

            HStack(alignment: .top, spacing: 24) {
                ForEach(engine.activeSounds, id: \.id) { active in
                    if let soundType = SoundType.allSounds.first(where: { $0.id == active.soundId }) {
                        MixerColumn(
                            soundType: soundType,
                            volume: Binding(
                                get: { active.volume },
                                set: { engine.updateVolume(for: active.soundId, volume: $0) }
                            ),
                            onRemove: { engine.removeSound(active.soundId) }
                        )
                    }
                }
                Spacer()
            }
        }
    }

    // MARK: Timer section

    private var timerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sleep Timer")
                .font(.system(.callout, design: .rounded, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .center)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TimerOption.allCases, id: \.self) { option in
                        let isPremium = !SoundEngine.freeTimerOptions.contains(option)
                        Button {
                            engine.setTimer(option)
                        } label: {
                            HStack(spacing: 4) {
                                if isPremium {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(Color.orange.opacity(0.9))
                                }
                                Text(option.label)
                                    .font(.system(.callout, design: .rounded, weight: .semibold))
                                    .foregroundStyle(engine.selectedTimer == option ? Color.accentBlue : .white)
                            }
                            .frame(minWidth: 56, minHeight: 40)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.cardBg)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(engine.selectedTimer == option ? Color.accentBlue : .clear, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Fan Centerpiece (Lottie)

private struct FanCenterpiece: View {
    let isPlaying: Bool
    @State private var dotLottie: DotLottieFile?

    var body: some View {
        ZStack {
            if let dl = dotLottie {
                LottieView(dotLottieFile: dl)
                    .playbackMode(
                        isPlaying
                        ? .playing(.fromProgress(0, toProgress: 1, loopMode: .loop))
                        : .paused
                    )
                    .animationSpeed(1.0)
            } else {
                // Fallback while the file loads
                Image(systemName: "fanblades.fill")
                    .font(.system(size: 140, weight: .light))
                    .foregroundStyle(Color.accentBlue)
                    .rotationEffect(.degrees(isPlaying ? 360 : 0))
                    .animation(
                        isPlaying
                        ? .linear(duration: 1.2).repeatForever(autoreverses: false)
                        : .default,
                        value: isPlaying
                    )
            }
        }
        .task {
            dotLottie = try? await DotLottieFile.named("Fan")
        }
    }
}

// MARK: - Sound Card

private struct SoundCard: View {
    let sound: SoundType
    let isActive: Bool
    let isPremium: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 10) {
                    Image(systemName: sound.icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(isActive ? Color.accentBlue : .white)
                        .frame(height: 40)

                    Text(sound.name)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(isActive ? Color.accentBlue : .white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(sound.description)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 150)

                if isPremium {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(
                            Capsule().fill(LinearGradient(
                                colors: [Color(red: 1.0, green: 0.65, blue: 0.0),
                                         Color(red: 1.0, green: 0.45, blue: 0.0)],
                                startPoint: .leading, endPoint: .trailing
                            ))
                        )
                        .padding(10)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isActive ? Color.cardBgActive : Color.cardBg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isActive ? Color.accentBlue : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mixer column

private struct MixerColumn: View {
    let soundType: SoundType
    @Binding var volume: Float
    let onRemove: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Button(action: onRemove) {
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentBlue)
                            .frame(width: 32, height: 32)
                        Image(systemName: soundType.icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.white, Color.gray)
                        .offset(x: 10, y: -10)
                }
            }
            .buttonStyle(.plain)

            Text(soundType.name)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: 56)

            VerticalSlider(value: $volume)
                .frame(width: 28, height: 120)

            Text("\(Int(volume * 100))%")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.55))
        }
    }
}

// MARK: - Vertical slider

private struct VerticalSlider: View {
    @Binding var value: Float

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.10))
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentBlue)
                    .frame(height: geo.size.height * CGFloat(value))
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        let raw = 1.0 - Float(drag.location.y / geo.size.height)
                        value = max(0, min(1, raw))
                    }
            )
        }
    }
}
