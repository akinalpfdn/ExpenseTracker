//
//  AddExpenseUXTests.swift
//  ExpenseTrackerTests
//
//  Occurrence-count arithmetic and category ordering.
//

import XCTest
@testable import ExpenseTracker

final class RecurrenceScheduleTests: XCTestCase {

    private let schedule = RecurrenceSchedule()

    /// The case that motivated the feature: a PC bought in 6 monthly instalments,
    /// first payment 9 September. Payments land on 9 Sep, Oct, Nov, Dec, Jan and
    /// 9 Feb — so the end date is five months out, not six. One month too far bills
    /// the user a seventh time.
    func testSixMonthlyInstalmentsEndFiveMonthsLater() {
        let start = date("2026-09-09")
        let end = schedule.endDate(startDate: start, recurrence: .MONTHLY, occurrences: 6)

        XCTAssertEqual(dateString(end), "2027-02-09")
    }

    func testASingleOccurrenceEndsOnTheStartDate() {
        let start = date("2026-09-09")
        let end = schedule.endDate(startDate: start, recurrence: .MONTHLY, occurrences: 1)

        XCTAssertEqual(dateString(end), "2026-09-09")
    }

    func testDailyAndWeeklyUseTheSameOffByOneRule() {
        let start = date("2026-09-09")

        XCTAssertEqual(
            dateString(schedule.endDate(startDate: start, recurrence: .DAILY, occurrences: 5)),
            "2026-09-13"
        )
        XCTAssertEqual(
            dateString(schedule.endDate(startDate: start, recurrence: .WEEKLY, occurrences: 4)),
            "2026-09-30"
        )
    }

    /// 9 Sep 2026 is a Wednesday. Five weekdays from it: Wed, Thu, Fri, Mon, Tue —
    /// landing on the 15th, having stepped over the weekend.
    func testWeekdaysSkipTheWeekend() {
        let end = schedule.endDate(startDate: date("2026-09-09"), recurrence: .WEEKDAYS, occurrences: 5)
        XCTAssertEqual(dateString(end), "2026-09-15")
    }

    /// 12 Sep 2026 is a Saturday, so the first occurrence is the Monday after.
    func testWeekdaysStartingOnAWeekendBeginOnMonday() {
        let end = schedule.endDate(startDate: date("2026-09-12"), recurrence: .WEEKDAYS, occurrences: 1)
        XCTAssertEqual(dateString(end), "2026-09-14")
    }

    func testNonRecurringHasNoEndDate() {
        XCTAssertNil(schedule.endDate(startDate: date("2026-09-09"), recurrence: .NONE, occurrences: 6))
    }

    func testZeroOrNegativeCountsAreRejected() {
        let start = date("2026-09-09")
        XCTAssertNil(schedule.endDate(startDate: start, recurrence: .MONTHLY, occurrences: 0))
        XCTAssertNil(schedule.endDate(startDate: start, recurrence: .MONTHLY, occurrences: -3))
    }

    // MARK: - The Inverse

    func testCountAndEndDateAreInverses() {
        let start = date("2026-09-09")

        for recurrence in [RecurrenceType.DAILY, .WEEKLY, .MONTHLY, .WEEKDAYS] {
            for count in [1, 2, 6, 12, 24] {
                guard let end = schedule.endDate(startDate: start, recurrence: recurrence, occurrences: count) else {
                    return XCTFail("No end date for \(recurrence) x\(count)")
                }

                let roundTripped = schedule.occurrenceCount(
                    startDate: start, endDate: end, recurrence: recurrence
                )

                XCTAssertEqual(roundTripped, count, "\(recurrence) x\(count) did not round-trip")
            }
        }
    }

    func testAnEndDateBeforeTheStartStillCountsAsOne() {
        let count = schedule.occurrenceCount(
            startDate: date("2026-09-09"),
            endDate: date("2026-01-01"),
            recurrence: .MONTHLY
        )

        XCTAssertEqual(count, 1, "The first occurrence happens regardless")
    }

    func testNonRecurringHasNoCount() {
        let count = schedule.occurrenceCount(
            startDate: date("2026-09-09"),
            endDate: date("2027-09-09"),
            recurrence: .NONE
        )

        XCTAssertNil(count)
    }
}

// MARK: - Category Ordering

final class CategoryUsageRankingTests: XCTestCase {

    func testMostUsedComesFirst() {
        let expenses = [
            expense(categoryId: "food", subCategoryId: "restaurant"),
            expense(categoryId: "food", subCategoryId: "restaurant"),
            expense(categoryId: "food", subCategoryId: "restaurant"),
            expense(categoryId: "transport", subCategoryId: "fuel")
        ]

        let ranking = CategoryUsageRanking(expenses: expenses, now: referenceNow)
        let ordered = ranking.sorted([
            category(id: "transport", name: "Transport"),
            category(id: "food", name: "Food")
        ])

        XCTAssertEqual(ordered.map(\.id), ["food", "transport"])
    }

    /// Without this, frequency ordering would leave never-used categories in an
    /// arbitrary order, which reads as broken.
    func testTiesFallBackToAlphabetical() {
        let ranking = CategoryUsageRanking(expenses: [], now: referenceNow)
        let ordered = ranking.sorted([
            category(id: "c", name: "Zebra"),
            category(id: "a", name: "Apple"),
            category(id: "b", name: "Mango")
        ])

        XCTAssertEqual(ordered.map(\.name), ["Apple", "Mango", "Zebra"])
    }

    func testUnusedCategoriesSinkBelowUsedOnes() {
        let expenses = [expense(categoryId: "zebra", subCategoryId: "s1")]

        let ranking = CategoryUsageRanking(expenses: expenses, now: referenceNow)
        let ordered = ranking.sorted([
            category(id: "apple", name: "Apple"),
            category(id: "zebra", name: "Zebra")
        ])

        XCTAssertEqual(ordered.map(\.name), ["Zebra", "Apple"])
    }

    func testSubcategoriesRankIndependentlyOfTheirParent() {
        let expenses = [
            expense(categoryId: "food", subCategoryId: "kitchen"),
            expense(categoryId: "food", subCategoryId: "kitchen"),
            expense(categoryId: "food", subCategoryId: "restaurant")
        ]

        let ranking = CategoryUsageRanking(expenses: expenses, now: referenceNow)
        let ordered = ranking.sorted([
            subCategory(id: "restaurant", name: "Restaurant"),
            subCategory(id: "kitchen", name: "Kitchen")
        ])

        XCTAssertEqual(ordered.map(\.id), ["kitchen", "restaurant"])
    }

    /// The window is what the user asked for: the order should follow what they are
    /// spending on now, not what they spent on a year ago.
    func testSpendingOlderThanTheWindowIsIgnored() {
        let expenses = [
            expense(categoryId: "old", subCategoryId: "s1", on: monthsFromReference(-8)),
            expense(categoryId: "old", subCategoryId: "s1", on: monthsFromReference(-7)),
            expense(categoryId: "old", subCategoryId: "s1", on: monthsFromReference(-6)),
            expense(categoryId: "recent", subCategoryId: "s2", on: monthsFromReference(-1))
        ]

        let ranking = CategoryUsageRanking(expenses: expenses, now: referenceNow)
        let ordered = ranking.sorted([
            category(id: "old", name: "Old"),
            category(id: "recent", name: "Recent")
        ])

        XCTAssertEqual(ordered.map(\.id), ["recent", "old"])
        XCTAssertEqual(ranking.usageCount(forCategory: "old"), 0)
    }

    /// Recurring expenses are stored as individual occurrences up to a year ahead.
    /// Counting those would let one subscription set up once outrank a category the
    /// user picks by hand every week.
    func testFutureDatedOccurrencesAreIgnored() {
        var expenses = [expense(categoryId: "manual", subCategoryId: "s1", on: monthsFromReference(-1))]

        for monthsAhead in 1...12 {
            expenses.append(
                expense(categoryId: "subscription", subCategoryId: "s2", on: monthsFromReference(monthsAhead))
            )
        }

        let ranking = CategoryUsageRanking(expenses: expenses, now: referenceNow)

        XCTAssertEqual(ranking.usageCount(forCategory: "subscription"), 0)
        XCTAssertEqual(ranking.usageCount(forCategory: "manual"), 1)
    }

    /// The case the user raised: a daily transit pass generates roughly ninety rows a
    /// quarter but was chosen once. Counting rows would put it above the groceries
    /// category actually picked every week.
    func testARecurringSeriesCountsOnceNoMatterHowManyOccurrences() {
        var expenses: [Expense] = []

        for daysAgo in 1...90 {
            let day = Calendar.current.date(byAdding: .day, value: -daysAgo, to: referenceNow)!
            expenses.append(
                expense(categoryId: "transit", subCategoryId: "pass", on: day,
                        recurrence: .DAILY, groupId: "transit-pass")
            )
        }

        for weeksAgo in 1...12 {
            let day = Calendar.current.date(byAdding: .weekOfYear, value: -weeksAgo, to: referenceNow)!
            expenses.append(expense(categoryId: "groceries", subCategoryId: "market", on: day))
        }

        let ranking = CategoryUsageRanking(expenses: expenses, now: referenceNow)

        XCTAssertEqual(ranking.usageCount(forCategory: "transit"), 1)
        XCTAssertEqual(ranking.usageCount(forCategory: "groceries"), 12)

        let ordered = ranking.sorted([
            category(id: "transit", name: "Transit"),
            category(id: "groceries", name: "Groceries")
        ])
        XCTAssertEqual(ordered.map(\.id), ["groceries", "transit"])
    }

    func testSeparateSeriesCountSeparately() {
        let expenses = [
            expense(categoryId: "bills", subCategoryId: "s1", on: monthsFromReference(-1),
                    recurrence: .MONTHLY, groupId: "rent"),
            expense(categoryId: "bills", subCategoryId: "s1", on: monthsFromReference(-2),
                    recurrence: .MONTHLY, groupId: "rent"),
            expense(categoryId: "bills", subCategoryId: "s1", on: monthsFromReference(-1),
                    recurrence: .MONTHLY, groupId: "internet")
        ]

        let ranking = CategoryUsageRanking(expenses: expenses, now: referenceNow)
        XCTAssertEqual(ranking.usageCount(forCategory: "bills"), 2, "Two series, counted twice")
    }

    /// A recurring expense with no group set still counts once, rather than being
    /// merged with every other group-less recurring expense.
    func testRecurringWithoutAGroupStillCountsOnce() {
        let expenses = [
            expense(categoryId: "a", subCategoryId: "s1", on: monthsFromReference(-1), recurrence: .MONTHLY),
            expense(categoryId: "b", subCategoryId: "s2", on: monthsFromReference(-1), recurrence: .MONTHLY)
        ]

        let ranking = CategoryUsageRanking(expenses: expenses, now: referenceNow)
        XCTAssertEqual(ranking.usageCount(forCategory: "a"), 1)
        XCTAssertEqual(ranking.usageCount(forCategory: "b"), 1)
    }

    func testTheWindowBoundaryIsInclusive() {
        let expenses = [expense(categoryId: "edge", subCategoryId: "s1", on: monthsFromReference(-3))]
        let ranking = CategoryUsageRanking(expenses: expenses, now: referenceNow)

        XCTAssertEqual(ranking.usageCount(forCategory: "edge"), 1)
    }

    func testCategoryCountSumsItsSubcategories() {
        let expenses = [
            expense(categoryId: "food", subCategoryId: "kitchen"),
            expense(categoryId: "food", subCategoryId: "restaurant")
        ]

        let ranking = CategoryUsageRanking(expenses: expenses, now: referenceNow)

        XCTAssertEqual(ranking.usageCount(forCategory: "food"), 2)
        XCTAssertEqual(ranking.usageCount(forSubCategory: "kitchen"), 1)
        XCTAssertEqual(ranking.usageCount(forSubCategory: "unused"), 0)
    }
}

// MARK: - Fixtures

private func date(_ string: String) -> Date {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.date(from: string)!
}

private func dateString(_ date: Date?) -> String? {
    guard let date = date else { return nil }
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
}

private func category(id: String, name: String) -> ExpenseTracker.Category {
    return ExpenseTracker.Category(id: id, name: name, colorHex: "#FF9500", iconName: "category")
}

private func subCategory(id: String, name: String) -> SubCategory {
    return SubCategory(id: id, name: name, categoryId: "food")
}

private func expense(
    categoryId: String,
    subCategoryId: String,
    on date: Date = referenceNow,
    recurrence: RecurrenceType = .NONE,
    groupId: String? = nil
) -> Expense {
    return Expense(
        amount: 100,
        currency: "₺",
        categoryId: categoryId,
        subCategoryId: subCategoryId,
        description: "test",
        date: date,
        dailyLimitAtCreation: 0,
        monthlyLimitAtCreation: 0,
        recurrenceType: recurrence,
        recurrenceGroupId: groupId
    )
}

/// Fixed "now" for the ranking tests, so window boundaries do not depend on the day
/// the suite runs.
private let referenceNow = date("2026-09-09")

private func monthsFromReference(_ months: Int) -> Date {
    return Calendar.current.date(byAdding: .month, value: months, to: referenceNow)!
}
