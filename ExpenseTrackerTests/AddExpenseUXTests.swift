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

        let ranking = CategoryUsageRanking(expenses: expenses)
        let ordered = ranking.sorted([
            category(id: "transport", name: "Transport"),
            category(id: "food", name: "Food")
        ])

        XCTAssertEqual(ordered.map(\.id), ["food", "transport"])
    }

    /// Without this, frequency ordering would leave never-used categories in an
    /// arbitrary order, which reads as broken.
    func testTiesFallBackToAlphabetical() {
        let ranking = CategoryUsageRanking(expenses: [])
        let ordered = ranking.sorted([
            category(id: "c", name: "Zebra"),
            category(id: "a", name: "Apple"),
            category(id: "b", name: "Mango")
        ])

        XCTAssertEqual(ordered.map(\.name), ["Apple", "Mango", "Zebra"])
    }

    func testUnusedCategoriesSinkBelowUsedOnes() {
        let expenses = [expense(categoryId: "zebra", subCategoryId: "s1")]

        let ranking = CategoryUsageRanking(expenses: expenses)
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

        let ranking = CategoryUsageRanking(expenses: expenses)
        let ordered = ranking.sorted([
            subCategory(id: "restaurant", name: "Restaurant"),
            subCategory(id: "kitchen", name: "Kitchen")
        ])

        XCTAssertEqual(ordered.map(\.id), ["kitchen", "restaurant"])
    }

    func testCategoryCountSumsItsSubcategories() {
        let expenses = [
            expense(categoryId: "food", subCategoryId: "kitchen"),
            expense(categoryId: "food", subCategoryId: "restaurant")
        ]

        let ranking = CategoryUsageRanking(expenses: expenses)

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

private func expense(categoryId: String, subCategoryId: String) -> Expense {
    return Expense(
        amount: 100,
        currency: "₺",
        categoryId: categoryId,
        subCategoryId: subCategoryId,
        description: "test",
        date: Date(),
        dailyLimitAtCreation: 0,
        monthlyLimitAtCreation: 0
    )
}
