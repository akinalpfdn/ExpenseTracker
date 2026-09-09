//
//  ReminderPlannerTests.swift
//  ExpenseTrackerTests
//
//  Which days get a reminder. The scheduling itself is a thin wrapper over
//  UNUserNotificationCenter; the rules worth testing are all here.
//

import XCTest
@testable import ExpenseTracker

final class ReminderPlannerTests: XCTestCase {

    private let planner = ReminderPlanner()
    private let calendar = Calendar.current

    /// Mid-afternoon, so a 21:00 reminder is still ahead of us today.
    private lazy var now = dateTime("2026-09-09 14:00")

    // MARK: - Basic Shape

    func testSchedulesOneReminderPerDayAcrossTheHorizon() {
        let dates = planner.reminderDates(
            from: now, hour: 21, minute: 0, daysWithExpenses: [], horizonDays: 14
        )

        XCTAssertEqual(dates.count, 14)
    }

    func testRemindersLandAtTheChosenTime() {
        let dates = planner.reminderDates(
            from: now, hour: 21, minute: 30, daysWithExpenses: [], horizonDays: 3
        )

        for date in dates {
            let components = calendar.dateComponents([.hour, .minute], from: date)
            XCTAssertEqual(components.hour, 21)
            XCTAssertEqual(components.minute, 30)
        }
    }

    func testRemindersAreInChronologicalOrder() {
        let dates = planner.reminderDates(
            from: now, hour: 21, minute: 0, daysWithExpenses: [], horizonDays: 5
        )

        XCTAssertEqual(dates, dates.sorted())
    }

    // MARK: - Skipping Logged Days

    /// The whole point of the feature: no nagging on a day already logged.
    func testTodayIsSkippedWhenSomethingWasLogged() {
        let today = calendar.startOfDay(for: now)

        let dates = planner.reminderDates(
            from: now, hour: 21, minute: 0, daysWithExpenses: [today], horizonDays: 3
        )

        XCTAssertEqual(dates.count, 2)
        XCTAssertFalse(dates.contains { calendar.isDate($0, inSameDayAs: today) })
    }

    func testOtherDaysSurviveWhenTodayIsSkipped() {
        let today = calendar.startOfDay(for: now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        let dates = planner.reminderDates(
            from: now, hour: 21, minute: 0, daysWithExpenses: [today], horizonDays: 3
        )

        XCTAssertTrue(dates.contains { calendar.isDate($0, inSameDayAs: tomorrow) })
    }

    // MARK: - Times Already Past

    /// A 21:00 reminder set at 22:00 must not be scheduled for an hour ago; it would
    /// either fire at once or be dropped.
    func testTodayIsSkippedWhenItsTimeHasPassed() {
        let lateEvening = dateTime("2026-09-09 22:00")
        let today = calendar.startOfDay(for: lateEvening)

        let dates = planner.reminderDates(
            from: lateEvening, hour: 21, minute: 0, daysWithExpenses: [], horizonDays: 3
        )

        XCTAssertFalse(dates.contains { calendar.isDate($0, inSameDayAs: today) })
        XCTAssertEqual(dates.count, 2)
    }

    func testEveryScheduledDateIsInTheFuture() {
        let lateEvening = dateTime("2026-09-09 23:59")

        let dates = planner.reminderDates(
            from: lateEvening, hour: 21, minute: 0, daysWithExpenses: [], horizonDays: 14
        )

        for date in dates {
            XCTAssertGreaterThan(date, lateEvening)
        }
    }

    // MARK: - Identifiers

    /// Each day needs its own id so logging an expense can cancel just that day.
    func testEachDayGetsADistinctStableIdentifier() {
        let dates = planner.reminderDates(
            from: now, hour: 21, minute: 0, daysWithExpenses: [], horizonDays: 14
        )

        let identifiers = dates.map { planner.identifier(for: $0) }

        XCTAssertEqual(Set(identifiers).count, identifiers.count, "Identifiers collided")
        XCTAssertEqual(planner.identifier(for: dates[0]), planner.identifier(for: dates[0]))
    }

    func testIdentifiersCarryThePrefixTheSchedulerFiltersOn() {
        let identifier = planner.identifier(for: now)
        XCTAssertTrue(identifier.hasPrefix(ReminderScheduler.identifierPrefix))
    }

    // MARK: - Logged Days From Expenses

    func testExpensesCollapseToTheDaysTheyFallOn() {
        let expenses = [
            expense(on: dateTime("2026-09-09 09:00")),
            expense(on: dateTime("2026-09-09 18:30")),
            expense(on: dateTime("2026-09-08 12:00"))
        ]

        let days = planner.daysWithExpenses(from: expenses)

        XCTAssertEqual(days.count, 2, "Two expenses on one day should collapse to one")
        XCTAssertTrue(days.contains(calendar.startOfDay(for: dateTime("2026-09-09 00:00"))))
    }

    func testNoExpensesMeansNoLoggedDays() {
        XCTAssertTrue(planner.daysWithExpenses(from: []).isEmpty)
    }
}

// MARK: - Fixtures

private extension ReminderPlannerTests {

    func dateTime(_ string: String) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.date(from: string)!
    }

    func expense(on date: Date) -> Expense {
        return Expense(
            amount: 100,
            currency: "₺",
            categoryId: "food",
            subCategoryId: "sub1",
            description: "test",
            date: date,
            dailyLimitAtCreation: 0,
            monthlyLimitAtCreation: 0
        )
    }
}
