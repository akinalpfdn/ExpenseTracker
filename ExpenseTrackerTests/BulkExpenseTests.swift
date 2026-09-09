//
//  BulkExpenseTests.swift
//  ExpenseTrackerTests
//
//  The bulk paths a recurring series goes through. Each runs against an in-memory
//  store so the app's own database is never touched.
//

import XCTest
import CoreData
@testable import ExpenseTracker

final class BulkExpenseTests: XCTestCase {

    private var dataAccess: ExpenseDataAccess!

    override func setUpWithError() throws {
        try super.setUpWithError()
        dataAccess = ExpenseDataAccess(context: try makeInMemoryContext())
    }

    // MARK: - Insert

    /// A daily recurring expense is around 365 rows. These used to go in one at a
    /// time, each with its own save.
    func testABigSeriesGoesInWhole() async throws {
        let series = recurringSeries(count: 365)

        try await dataAccess.insertExpenses(series)

        let stored = try await dataAccess.getAllExpenses()
        XCTAssertEqual(stored.count, 365)
    }

    func testInsertingNothingIsHarmless() async throws {
        try await dataAccess.insertExpenses([])
        let stored = try await dataAccess.getAllExpenses()
        XCTAssertTrue(stored.isEmpty)
    }

    func testInsertedValuesSurvive() async throws {
        let expense = makeExpense(id: "e1", amount: 250, on: date("2026-09-09"))

        try await dataAccess.insertExpenses([expense])

        let stored = try await dataAccess.getAllExpenses()
        XCTAssertEqual(stored.first?.id, "e1")
        XCTAssertEqual(stored.first?.amount, 250)
    }

    // MARK: - Update

    func testUpdatingASeriesRewritesEveryOccurrence() async throws {
        let series = recurringSeries(count: 50, amount: 100)
        try await dataAccess.insertExpenses(series)

        let raised = series.map { occurrence in
            makeExpense(id: occurrence.id, amount: 175, on: occurrence.date)
        }
        try await dataAccess.updateExpenses(raised)

        let stored = try await dataAccess.getAllExpenses()
        XCTAssertEqual(stored.count, 50)
        XCTAssertTrue(stored.allSatisfy { $0.amount == 175 })
    }

    /// Editing a series from a date onwards must leave the occurrences before it alone.
    func testUpdatingSomeLeavesTheRestUntouched() async throws {
        let series = recurringSeries(count: 10, amount: 100)
        try await dataAccess.insertExpenses(series)

        let tail = series.suffix(4).map { makeExpense(id: $0.id, amount: 999, on: $0.date) }
        try await dataAccess.updateExpenses(Array(tail))

        let stored = try await dataAccess.getAllExpenses()
        XCTAssertEqual(stored.filter { $0.amount == 999 }.count, 4)
        XCTAssertEqual(stored.filter { $0.amount == 100 }.count, 6)
    }

    // MARK: - Delete

    func testDeletingASeriesRemovesAllOfIt() async throws {
        let series = recurringSeries(count: 200)
        try await dataAccess.insertExpenses(series)

        try await dataAccess.deleteExpenses(series)

        let stored = try await dataAccess.getAllExpenses()
        XCTAssertTrue(stored.isEmpty)
    }

    func testDeletingSomeKeepsTheRest() async throws {
        let series = recurringSeries(count: 10)
        try await dataAccess.insertExpenses(series)

        try await dataAccess.deleteExpenses(Array(series.prefix(3)))

        let stored = try await dataAccess.getAllExpenses()
        XCTAssertEqual(stored.count, 7)
    }

    func testDeletingNothingIsHarmless() async throws {
        try await dataAccess.insertExpenses(recurringSeries(count: 5))
        try await dataAccess.deleteExpenses([])

        let stored = try await dataAccess.getAllExpenses()
        XCTAssertEqual(stored.count, 5)
    }

    /// Rows the store has never seen should not disturb the ones it has.
    func testDeletingUnknownRowsIsHarmless() async throws {
        try await dataAccess.insertExpenses(recurringSeries(count: 5))

        let stranger = makeExpense(id: "not-in-store", amount: 1, on: date("2026-09-09"))
        try await dataAccess.deleteExpenses([stranger])

        let stored = try await dataAccess.getAllExpenses()
        XCTAssertEqual(stored.count, 5)
    }
}

// MARK: - Fixtures

private extension BulkExpenseTests {

    func makeInMemoryContext() throws -> NSManagedObjectContext {
        let container = NSPersistentContainer(name: "ExpenseTracker")

        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        var loadError: Error?
        container.loadPersistentStores { _, error in loadError = error }
        if let loadError = loadError { throw loadError }

        return container.viewContext
    }

    func makeExpense(id: String, amount: Double, on date: Date) -> Expense {
        return Expense(
            id: id,
            amount: amount,
            currency: "₺",
            categoryId: "food",
            subCategoryId: "sub1",
            description: "test",
            date: date,
            dailyLimitAtCreation: 0,
            monthlyLimitAtCreation: 0,
            recurrenceType: .DAILY,
            recurrenceGroupId: "series-1"
        )
    }

    func recurringSeries(count: Int, amount: Double = 100) -> [Expense] {
        let start = date("2026-09-09")

        return (0..<count).map { dayOffset in
            let day = Calendar.current.date(byAdding: .day, value: dayOffset, to: start)!
            return makeExpense(id: "occurrence-\(dayOffset)", amount: amount, on: day)
        }
    }

    func date(_ string: String) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)!
    }
}
