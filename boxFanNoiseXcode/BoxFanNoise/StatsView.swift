//
//  StatsView.swift
//  BoxFanNoise
//

import SwiftUI

struct StatsView: View {
    @State private var stats = StatsManager.shared

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                streakCard.padding(.top, 16)

                LazyVGrid(columns: columns, spacing: 12) {
                    StatCard(icon: "clock.fill", iconColor: .accentBlue,
                             value: stats.formattedTotalTime, label: "Total Time")
                    StatCard(icon: "play.circle.fill", iconColor: .green,
                             value: "\(stats.totalSessions)", label: "Sessions")
                    StatCard(icon: "trophy.fill", iconColor: .yellow,
                             value: stats.formattedLongestSession, label: "Longest Session")
                    StatCard(icon: "chart.bar.fill", iconColor: .purple,
                             value: stats.formattedAverageSession, label: "Avg Session")
                    StatCard(icon: "calendar", iconColor: .orange,
                             value: stats.formattedWeeklyTime, label: "This Week")
                    StatCard(icon: "speaker.wave.2.fill", iconColor: .red,
                             value: favoriteSoundName(),
                             label: "Favorite Sound",
                             valueLines: 1)
                }

                weeklyChart
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private func favoriteSoundName() -> String {
        guard let id = stats.mostUsedSound,
              let s = SoundType.allSounds.first(where: { $0.id == id }) else { return "—" }
        return s.name
    }

    // MARK: Streak card

    private var streakCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text("🔥")
                    Text("Current Streak")
                        .font(.system(.callout, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }

                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text("\(stats.currentStreak)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(stats.currentStreak == 1 ? "day" : "days")
                        .font(.system(.title3, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            Spacer()
            Text("🔥")
                .font(.system(size: 70))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(LinearGradient(
                    colors: [Color(red: 0.25, green: 0.12, blue: 0.04),
                             Color(red: 0.45, green: 0.16, blue: 0.05)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
        )
    }

    // MARK: Weekly chart

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 8)

            let week = lastSevenDays()
            let maxVal = max(week.map(\.value).max() ?? 1, 1)

            HStack(alignment: .bottom, spacing: 14) {
                ForEach(week, id: \.label) { day in
                    VStack(spacing: 6) {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.06))
                                .frame(width: 24, height: 80)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.accentBlue)
                                .frame(width: 24, height: max(4, CGFloat(day.value / maxVal) * 80))
                        }
                        Text(day.label)
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18).fill(Color.cardBg)
        )
    }

    private struct DayPoint { let label: String; let value: Double }

    private func lastSevenDays() -> [DayPoint] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        return (0..<7).reversed().map { offset in
            let day = cal.date(byAdding: .day, value: -offset, to: today)!
            let stat = stats.dailyStats.first(where: { cal.isDate($0.date, inSameDayAs: day) })
            return DayPoint(label: formatter.string(from: day), value: stat?.totalTime ?? 0)
        }
    }
}

// MARK: - Stat card

private struct StatCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String
    var valueLines: Int = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                Circle().fill(iconColor.opacity(0.20)).frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(valueLines)
                    .minimumScaleFactor(0.6)
                Text(label)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 110)
        .background(
            RoundedRectangle(cornerRadius: 18).fill(Color.cardBg)
        )
    }
}
