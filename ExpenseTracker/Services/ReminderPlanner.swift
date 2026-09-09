//
//  ReminderPlanner.swift
//  ExpenseTracker
//
//  Decides which days should carry a reminder. Kept free of UserNotifications so the
//  rules can be tested without the notification centre or a device.
//

import Foundation

struct ReminderPlanner {

    /// How far ahead reminders are queued.
    ///
    /// iOS keeps at most 64 pending local notifications and silently drops the rest,
    /// so this stays well under. The window is topped up every time the app opens,
    /// which for an app someone logs into daily is often enough that it never empties.
    static let horizonDays = 14

    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    /// The exact moments a reminder should fire, soonest first.
    ///
    /// - Parameters:
    ///   - now: reference point; anything at or before this is in the past.
    ///   - hour/minute: the time of day the user chose.
    ///   - daysWithExpenses: days already logged, as start-of-day dates.
    func reminderDates(
        from now: Date,
        hour: Int,
        minute: Int,
        daysWithExpenses: Set<Date>,
        horizonDays: Int = ReminderPlanner.horizonDays
    ) -> [Date] {
        let today = calendar.startOfDay(for: now)

        return (0..<horizonDays).compactMap { dayOffset in
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: today) else {
                return nil
            }

            // Nothing to remind about on a day that is already logged. Only meaningful
            // for today — future days cannot have expenses yet, barring back-dated
            // entries and recurring occurrences, which are handled by the caller
            // deciding what counts as "logged".
            guard !daysWithExpenses.contains(day) else { return nil }

            guard let fireDate = calendar.date(
                bySettingHour: hour, minute: minute, second: 0, of: day
            ) else {
                return nil
            }

            // Today's time may already have passed; scheduling it would either fire
            // immediately or be dropped.
            guard fireDate > now else { return nil }

            return fireDate
        }
    }

    /// Stable identifier per day, so a day's reminder can be cancelled on its own when
    /// the user logs something.
    func identifier(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0

        return String(format: "daily-reminder-%04d-%02d-%02d", year, month, day)
    }

    /// Start-of-day for every date given, for comparison against the planner's days.
    func daysWithExpenses(from expenses: [Expense]) -> Set<Date> {
        return Set(expenses.map { calendar.startOfDay(for: $0.date) })
    }
}
