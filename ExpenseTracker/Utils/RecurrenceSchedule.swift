//
//  RecurrenceSchedule.swift
//  ExpenseTracker
//
//  Converts between "how many times will this happen" and "when does it stop".
//
//  The first occurrence falls on the start date, so N occurrences end N-1 intervals
//  later. Six monthly instalments beginning 9 September end on 9 February, not
//  9 March. Getting that wrong charges the user an extra time.
//

import Foundation

struct RecurrenceSchedule {

    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    /// The date of the `count`-th occurrence, counting the one on `startDate` as the
    /// first. Returns nil for a non-recurring expense or a count below 1.
    func endDate(startDate: Date, recurrence: RecurrenceType, occurrences count: Int) -> Date? {
        guard recurrence != .NONE, count >= 1 else { return nil }

        let intervals = count - 1
        let start = calendar.startOfDay(for: startDate)

        switch recurrence {
        case .DAILY:
            return calendar.date(byAdding: .day, value: intervals, to: start)

        case .WEEKLY:
            return calendar.date(byAdding: .weekOfYear, value: intervals, to: start)

        case .MONTHLY:
            return calendar.date(byAdding: .month, value: intervals, to: start)

        case .WEEKDAYS:
            // Even a single occurrence goes through the walk: a Saturday start has
            // its first occurrence on the Monday, and an early return for count == 1
            // used to skip that rule and hand back the Saturday.
            return weekdayDate(from: start, advancing: intervals)

        case .NONE:
            return nil
        }
    }

    /// How many occurrences fit between the two dates inclusive — the inverse of the
    /// above, so the two fields on the form can never disagree.
    ///
    /// Always at least 1: an end date on or before the start still means the first
    /// occurrence happens.
    func occurrenceCount(startDate: Date, endDate: Date, recurrence: RecurrenceType) -> Int? {
        guard recurrence != .NONE else { return nil }

        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        guard end > start else { return 1 }

        switch recurrence {
        case .DAILY:
            return (calendar.dateComponents([.day], from: start, to: end).day ?? 0) + 1

        case .WEEKLY:
            return (calendar.dateComponents([.weekOfYear], from: start, to: end).weekOfYear ?? 0) + 1

        case .MONTHLY:
            return (calendar.dateComponents([.month], from: start, to: end).month ?? 0) + 1

        case .WEEKDAYS:
            return weekdayCount(from: start, to: end)

        case .NONE:
            return nil
        }
    }

    // MARK: - Weekdays

    /// Walks forward day by day, counting only Monday to Friday. Stepping by weeks
    /// would not survive a start date that falls on a weekend.
    private func weekdayDate(from start: Date, advancing intervals: Int) -> Date? {
        var current = start
        var remaining = intervals

        // A start on a weekend has its first occurrence on the following Monday.
        while isWeekend(current) {
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { return nil }
            current = next
        }

        while remaining > 0 {
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { return nil }
            current = next

            if !isWeekend(current) {
                remaining -= 1
            }
        }

        return current
    }

    private func weekdayCount(from start: Date, to end: Date) -> Int {
        var current = start
        var count = 0

        while current <= end {
            if !isWeekend(current) {
                count += 1
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        return max(count, 1)
    }

    private func isWeekend(_ date: Date) -> Bool {
        return calendar.isDateInWeekend(date)
    }
}
