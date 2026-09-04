//
//  JourneyState.swift
//  heal
//
//  Persisted Journey progress: chosen length, completed days and start date.
//  Journey progress is deliberately independent of contact streaks. Resetting
//  a streak never erases completed days.
//

import Foundation

struct JourneyState: Codable, Equatable {
    var selectedLength: Int = 30
    var completedDayNumbers: Set<Int> = []
    var startedAt: Date = Date()

    static let storageKey = "storedJourneyState"

    static func load(from string: String) -> JourneyState {
        LocalPersistence.decode(JourneyState.self, from: string) ?? JourneyState()
    }

    var encoded: String {
        LocalPersistence.encode(self)
    }

    var days: [JourneyContentDay] {
        JourneyLibrary.days(for: selectedLength)
    }

    /// Days elapsed since the Journey began, so content is paced rather than
    /// all available at once. Day 1 is unlocked immediately.
    var unlockedDayNumber: Int {
        let calendar = Calendar.current
        let elapsed = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: startedAt),
            to: calendar.startOfDay(for: Date())
        ).day ?? 0
        return min(selectedLength, max(1, elapsed + 1))
    }

    /// The earliest unlocked day that has not been completed yet.
    var currentDayNumber: Int {
        let firstIncomplete = (1...max(1, selectedLength)).first {
            $0 <= unlockedDayNumber && !completedDayNumbers.contains($0)
        }
        return firstIncomplete ?? unlockedDayNumber
    }

    var currentDay: JourneyContentDay? {
        JourneyLibrary.day(currentDayNumber)
    }

    var currentPhase: JourneyPhase {
        JourneyPhase.phase(forDay: currentDayNumber)
    }

    /// Completed days that belong to the currently selected length. Switching
    /// to a shorter Journey hides later days without discarding their progress.
    var completedCountInJourney: Int {
        completedDayNumbers.filter { $0 >= 1 && $0 <= selectedLength }.count
    }

    var progressFraction: Double {
        guard selectedLength > 0 else { return 0 }
        return min(1, Double(completedCountInJourney) / Double(selectedLength))
    }

    var progressPercent: Int {
        Int((progressFraction * 100).rounded())
    }

    /// Progress through the current phase, used for the Home phase card.
    var phaseProgressFraction: Double {
        let range = currentPhase.dayRange
        let visible = range.clamped(to: 1...max(1, selectedLength))
        let total = visible.count
        guard total > 0 else { return 0 }
        let done = completedDayNumbers.filter { visible.contains($0) }.count
        return min(1, Double(done) / Double(total))
    }

    func isCompleted(_ number: Int) -> Bool {
        completedDayNumbers.contains(number)
    }

    func isLocked(_ number: Int) -> Bool {
        number > unlockedDayNumber && !completedDayNumbers.contains(number)
    }

    mutating func markCompleted(_ number: Int) {
        completedDayNumbers.insert(number)
    }

    mutating func markIncomplete(_ number: Int) {
        completedDayNumbers.remove(number)
    }

    mutating func select(length: Int) {
        guard JourneyLibrary.availableLengths.contains(length) else { return }
        selectedLength = length
    }
}
