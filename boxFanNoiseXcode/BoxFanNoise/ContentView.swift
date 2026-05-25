//
//  ContentView.swift
//  BoxFanNoise
//

import SwiftUI

enum AppTab: Hashable {
    case sounds, presets, stats, settings
}

struct ContentView: View {
    @State private var tab: AppTab = .sounds

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            Group {
                switch tab {
                case .sounds:   SoundsView()
                case .presets:  PresetsView()
                case .stats:    StatsView()
                case .settings: SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 90)

            CustomTabBar(selection: $tab)
                .padding(.bottom, 14)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 4) {
            tabButton(.sounds, "waveform", "Sounds")
            tabButton(.presets, "square.grid.2x2.fill", "Presets")
            tabButton(.stats, "chart.bar.fill", "Stats")
            tabButton(.settings, "gearshape.fill", "Settings")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Capsule().fill(Color(white: 0.12)))
        .padding(.horizontal, 14)
    }

    private func tabButton(_ value: AppTab, _ icon: String, _ label: String) -> some View {
        let isSelected = selection == value
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                selection = value
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(label)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(isSelected ? Color.accentBlue : Color.white.opacity(0.55))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(isSelected ? Color.white.opacity(0.10) : .clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shared style

extension Color {
    static let accentBlue = Color(red: 0.0, green: 0.52, blue: 1.0)
    static let cardBg = Color(white: 0.10)
    static let cardBgActive = Color(red: 0.08, green: 0.20, blue: 0.40)
}

#Preview {
    ContentView()
}
