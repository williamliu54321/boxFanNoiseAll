//
//  StatsManager.swift
//  BoxFanNoise
//

import SwiftUI

@Observable
class StatsManager {
    static let shared = StatsManager()

    private let userDefaults = UserDefaults.standard

    private let totalListeningTimeKey = "totalListeningTime"
    private let totalSessionsKey = "totalSessions"
    private let longestSessionKey = "longestSession"
    private let dailyStatsKey = "dailyStats"
    private let soundUsageKey = "soundUsage"
    private let streakKey = "currentStreak"
    private let lastUseDateKey = "lastUseDate"

    var totalListeningTime: TimeInterval {
        get { userDefaults.double(forKey: totalListeningTimeKey) }
        set { userDefaults.set(newValue, forKey: totalListeningTimeKey) }
    }

    var totalSessions: Int {
        get { userDefaults.integer(forKey: totalSessionsKey) }
        set { userDefaults.set(newValue, forKey: totalSessionsKey) }
    }

    var longestSession: TimeInterval {
        get { userDefaults.double(forKey: longestSessionKey) }
        set { userDefaults.set(newValue, forKey: longestSessionKey) }
    }

    var currentStreak: Int {
        get { userDefaults.integer(forKey: streakKey) }
        set { userDefaults.set(newValue, forKey: streakKey) }
    }

    var soundUsage: [String: Int] {
        get {
            if let data = userDefaults.data(forKey: soundUsageKey),
               let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
                return decoded
            }
            return [:]
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                userDefaults.set(encoded, forKey: soundUsageKey)
            }
        }
    }

    private var sessionStartTime: Date?
    private var sessionTimer: Timer?
    private(set) var currentSessionDuration: TimeInterval = 0

    var isInSession: Bool { sessionStartTime != nil }

    private init() {
        updateStreak()
    }

    func startSession(soundIds: [String]) {
        sessionStartTime = Date()
        totalSessions += 1

        var usage = soundUsage
        for soundId in soundIds {
            usage[soundId, default: 0] += 1
        }
        soundUsage = usage

        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.sessionStartTime else { return }
            self.currentSessionDuration = Date().timeIntervalSince(start)
        }
    }

    func endSession() {
        sessionTimer?.invalidate()
        sessionTimer = nil

        guard let start = sessionStartTime else { return }

        let duration = Date().timeIntervalSince(start)
        totalListeningTime += duration

        if duration > longestSession {
            longestSession = duration
        }

        updateStreak()
        saveDailyStat(duration: duration)

        sessionStartTime = nil
        currentSessionDuration = 0
    }

    private func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastUseDateTimestamp = userDefaults.object(forKey: lastUseDateKey) as? Date {
            let lastUseDate = calendar.startOfDay(for: lastUseDateTimestamp)

            if lastUseDate == today {
                return
            }

            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            if lastUseDate == yesterday {
                currentStreak += 1
            } else {
                currentStreak = 1
            }
        } else {
            currentStreak = 1
        }

        userDefaults.set(today, forKey: lastUseDateKey)
    }

    struct DailyStat: Codable {
        let date: Date
        var totalTime: TimeInterval
        var sessions: Int
    }

    var dailyStats: [DailyStat] {
        get {
            if let data = userDefaults.data(forKey: dailyStatsKey),
               let decoded = try? JSONDecoder().decode([DailyStat].self, from: data) {
                return decoded
            }
            return []
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                userDefaults.set(encoded, forKey: dailyStatsKey)
            }
        }
    }

    private func saveDailyStat(duration: TimeInterval) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var stats = dailyStats

        if let index = stats.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            stats[index].totalTime += duration
            stats[index].sessions += 1
        } else {
            stats.append(DailyStat(date: today, totalTime: duration, sessions: 1))
        }

        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today)!
        stats = stats.filter { $0.date >= thirtyDaysAgo }

        dailyStats = stats
    }

    var formattedTotalTime: String {
        formatDuration(totalListeningTime)
    }

    var formattedLongestSession: String {
        formatDuration(longestSession)
    }

    var formattedCurrentSession: String {
        formatDuration(currentSessionDuration)
    }

    var averageSessionLength: TimeInterval {
        guard totalSessions > 0 else { return 0 }
        return totalListeningTime / Double(totalSessions)
    }

    var formattedAverageSession: String {
        formatDuration(averageSessionLength)
    }

    var weeklyListeningTime: TimeInterval {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return dailyStats.filter { $0.date >= weekAgo }.reduce(0) { $0 + $1.totalTime }
    }

    var formattedWeeklyTime: String {
        formatDuration(weeklyListeningTime)
    }

    var mostUsedSound: String? {
        soundUsage.max(by: { $0.value < $1.value })?.key
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    func resetAllStats() {
        totalListeningTime = 0
        totalSessions = 0
        longestSession = 0
        currentStreak = 0
        soundUsage = [:]
        dailyStats = []
        userDefaults.removeObject(forKey: lastUseDateKey)
    }
}
