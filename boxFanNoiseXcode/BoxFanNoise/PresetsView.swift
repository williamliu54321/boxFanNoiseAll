//
//  PresetsView.swift
//  BoxFanNoise
//

import SwiftUI

struct PresetsView: View {
    @State private var engine = SoundEngine.shared
    @ObservedObject private var premium = PremiumStatus.shared

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Quick Start")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(SoundPreset.defaults) { preset in
                        let isPremium = preset.sounds.contains { !SoundEngine.freeSoundIds.contains($0.soundId) } && !premium.isPremium
                        PresetCard(preset: preset, isPremium: isPremium, onTap: { engine.loadPreset(preset) })
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Preset Card

private struct PresetCard: View {
    let preset: SoundPreset
    let isPremium: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: preset.icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(Color.accentBlue)
                        .frame(height: 32, alignment: .leading)

                    Text(preset.name)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    HStack(spacing: 6) {
                        ForEach(preset.sounds.prefix(3), id: \.id) { active in
                            if let s = SoundType.allSounds.first(where: { $0.id == active.soundId }) {
                                Image(systemName: s.icon)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white.opacity(0.55))
                            }
                        }
                    }

                    Spacer(minLength: 4)

                    Text("\(preset.sounds.count) sound\(preset.sounds.count == 1 ? "" : "s")")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: 165)

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
                    .fill(Color.cardBg)
            )
        }
        .buttonStyle(.plain)
    }
}
