//
//  SettingsView.swift
//  BoxFanNoise
//

import SwiftUI
import SuperwallKit

struct SettingsView: View {
    @State private var engine = SoundEngine.shared
    @State private var stats = StatsManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("Settings")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.top, 16)
                    .padding(.horizontal, 16)

                playbackSection
                statsSection
                legalSection
                supportSection
                aboutSection
            }
            .padding(.bottom, 24)
        }
    }

    // MARK: Playback

    private var playbackSection: some View {
        SettingsSection(title: "Playback") {
            VStack(spacing: 14) {
                FadeSlider(label: "Fade In",
                           value: Binding(get: { engine.fadeInDuration }, set: { engine.fadeInDuration = $0 }),
                           range: 0...10)
                Divider().background(Color.white.opacity(0.08))
                FadeSlider(label: "Fade Out",
                           value: Binding(get: { engine.fadeOutDuration }, set: { engine.fadeOutDuration = $0 }),
                           range: 0...10)
            }
            .padding(16)
        }
    }

    // MARK: Stats

    private var statsSection: some View {
        SettingsSection(title: "Your Stats") {
            VStack(spacing: 0) {
                StatRow(icon: "clock.fill", label: "Total Listening Time", value: stats.formattedTotalTime)
                Divider().background(Color.white.opacity(0.08))
                StatRow(icon: "play.circle.fill", label: "Total Sessions", value: "\(stats.totalSessions)")
                Divider().background(Color.white.opacity(0.08))
                StatRow(icon: "flame.fill", label: "Current Streak", value: "\(stats.currentStreak) day\(stats.currentStreak == 1 ? "" : "s")")
                Divider().background(Color.white.opacity(0.08))
                Button {
                    stats.resetAllStats()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset Stats")
                        Spacer()
                    }
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundStyle(.red)
                    .padding(14)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Legal

    private var legalSection: some View {
        SettingsSection(title: "Legal") {
            VStack(spacing: 0) {
                LinkRow(icon: "hand.raised.fill", label: "Privacy Policy",
                        url: URL(string: "https://boxfannoise.web.app/privacy.html")!)
                Divider().background(Color.white.opacity(0.08))
                LinkRow(icon: "doc.text.fill", label: "Terms of Service",
                        url: URL(string: "https://boxfannoise.web.app/terms.html")!)
            }
        }
    }

    // MARK: Support

    private var supportSection: some View {
        SettingsSection(title: "Support") {
            VStack(spacing: 0) {
                LinkRow(icon: "questionmark.circle.fill", label: "Help & Support",
                        url: URL(string: "https://boxfannoise.web.app/support.html")!)
                Divider().background(Color.white.opacity(0.08))
                LinkRow(icon: "envelope.fill", label: "Contact Us",
                        trailing: "admin@emberforgeapps.com",
                        url: URL(string: "mailto:admin@emberforgeapps.com")!)
                Divider().background(Color.white.opacity(0.08))
                Button {
                    Task { try? await Superwall.shared.restorePurchases() }
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .frame(width: 22)
                            .foregroundStyle(Color.accentBlue)
                        Text("Restore Purchases")
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .font(.system(.body, design: .rounded))
                    .padding(14)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: About

    private var aboutSection: some View {
        SettingsSection(title: "About") {
            VStack(spacing: 0) {
                StatRow(icon: "info.circle.fill", label: "Version", value: appVersion())
                Divider().background(Color.white.opacity(0.08))
                StatRow(icon: "person.fill", label: "Developer", value: "EmberForge Apps")
            }
        }
    }

    private func appVersion() -> String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return v
    }
}

// MARK: - Section wrapper

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(1)
                .padding(.horizontal, 24)

            content()
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBg))
                .padding(.horizontal, 16)
        }
    }
}

// MARK: - Reusable rows

private struct FadeSlider: View {
    let label: String
    @Binding var value: TimeInterval
    let range: ClosedRange<Double>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(Int(value))s")
                    .font(.system(.callout, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
            }
            Slider(value: $value, in: range, step: 1).tint(Color.accentBlue)
        }
    }
}

private struct StatRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 22)
                .foregroundStyle(Color.accentBlue)
            Text(label)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
            Text(value)
                .font(.system(.callout, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
        }
        .padding(14)
    }
}

private struct LinkRow: View {
    let icon: String
    let label: String
    var trailing: String? = nil
    let url: URL

    var body: some View {
        Link(destination: url) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .frame(width: 22)
                    .foregroundStyle(Color.accentBlue)
                Text(label)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                if let trailing = trailing {
                    Text(trailing)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(Color.accentBlue)
                } else {
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .padding(14)
        }
    }
}
