//
//  OverviewCalculatorTests.swift
//  ExpenseTrackerTests
//
//  The overview screen is entirely derived numbers, so these cover the arithmetic
//  rather than the rendering.
//

import XCTest
@testable import ExpenseTracker

final class OverviewCalculatorTests: XCTestCase {

    private let currency = "₺"
    private var calculator: OverviewCalculator!

    /// Fixed reference point so nothing depends on the day the suite runs.
    /// 15 June 2026, mid-month, so "current month is partial" is exercised.
    private let now = date("2026-06-15")

    override func setUp() {
        super.setUp()
        calculator = OverviewCalculator(defaultCurrency: currency)
    }

    // MARK: - Current Month

    func testCurrentMonthSpendingCountsOnlyThisMonth() {
        let expenses = [
            expense(amount: 100, on: "2026-06-01"),
            expense(amount: 250, on: "2026-06-15"),
            expense(amount: 999, on: "2026-05-31"),   // last month
            expense(amount: 999, on: "2026-07-01")    // next month
        ]

        XCTAssertEqual(calculator.currentMonthSpending(expenses: expenses, now: now), 350)
    }

    /// An expense timestamped on the last day of the month must not fall through the
    /// interval boundary.
    func testCurrentMonthIncludesTheFinalDay() {
        let expenses = [expense(amount: 75, on: "2026-06-30")]
        XCTAssertEqual(calculator.currentMonthSpending(expenses: expenses, now: now), 75)
    }

    func testForeignCurrencyIsConverted() {
        let expenses = [
            expense(amount: 100, on: "2026-06-10", currency: "$", exchangeRate: 40)
        ]

        // Counted at 4000, not 100.
        XCTAssertEqual(calculator.currentMonthSpending(expenses: expenses, now: now), 4000)
    }

    // MARK: - Remaining

    /// The relationship read off the screenshot: 89.775 − 14.461 = 75.314.
    func testRemainingIsIncomeMinusSpending() {
        let remaining = calculator.remaining(monthlyIncome: 89_775, currentMonthSpending: 14_461)
        XCTAssertEqual(remaining, 75_314)
    }

    func testRemainingGoesNegativeWhenOverspent() {
        let remaining = calculator.remaining(monthlyIncome: 10_000, currentMonthSpending: 12_500)
        XCTAssertEqual(remaining, -2_500)
    }

    // MARK: - Spending Trend

    func testTrendReturnsOnePointPerMonthOldestFirst() {
        let trend = calculator.spendingTrend(expenses: [], range: .threeMonths, now: now)

        XCTAssertEqual(trend.count, 3)
        XCTAssertEqual(trend.map { monthString($0.month) }, ["2026-04", "2026-05", "2026-06"])
    }

    func testTrendRangesHaveTheExpectedLengths() {
        for range in TrendRange.allCases {
            let trend = calculator.spendingTrend(expenses: [], range: range, now: now)
            XCTAssertEqual(trend.count, range.rawValue, "\(range) produced \(trend.count) points")
        }
    }

    func testTrendBucketsExpensesIntoTheRightMonths() {
        let expenses = [
            expense(amount: 100, on: "2026-04-10"),
            expense(amount: 200, on: "2026-05-10"),
            expense(amount: 50, on: "2026-05-20"),
            expense(amount: 300, on: "2026-06-01")
        ]

        let trend = calculator.spendingTrend(expenses: expenses, range: .threeMonths, now: now)
        XCTAssertEqual(trend.map(\.amount), [100, 250, 300])
    }

    /// The screenshot's footer: 889.100 over 12 months averages 74.091,67.
    func testTrendTotalAndAverageAgree() {
        let expenses = (0..<12).map { monthsAgo -> Expense in
            let month = Calendar.current.date(byAdding: .month, value: -monthsAgo, to: now)!
            return expense(amount: 1000, on: month)
        }

        let trend = calculator.spendingTrend(expenses: expenses, range: .oneYear, now: now)
        let total = trend.reduce(0) { $0 + $1.amount }

        XCTAssertEqual(total, 12_000)
        XCTAssertEqual(total / Double(trend.count), 1000)
    }

    // MARK: - Average One-Time Spending

    /// The current month is partial; including it would drag the average down by
    /// however far into the month we happen to be.
    func testAverageExcludesTheCurrentMonth() {
        let expenses = [
            expense(amount: 300, on: "2026-03-10"),
            expense(amount: 300, on: "2026-04-10"),
            expense(amount: 300, on: "2026-05-10"),
            expense(amount: 9_999, on: "2026-06-10")   // current month, must be ignored
        ]

        let average = calculator.averageMonthlyOneTimeSpending(expenses: expenses, now: now)
        XCTAssertEqual(average, 300)
    }

    func testAverageIgnoresRecurringExpenses() {
        let expenses = [
            expense(amount: 300, on: "2026-05-10"),
            expense(amount: 9_999, on: "2026-05-11", recurrence: .MONTHLY)
        ]

        let average = calculator.averageMonthlyOneTimeSpending(expenses: expenses, now: now)
        XCTAssertEqual(average, 100, "Recurring spending leaked into the one-time average")
    }

    func testAverageIsZeroWithNoHistory() {
        XCTAssertEqual(calculator.averageMonthlyOneTimeSpending(expenses: [], now: now), 0)
    }

    // MARK: - Forecast

    func testForecastCoversTwelveMonthsStartingThisMonth() {
        let forecast = calculator.forecast(expenses: [], now: now)

        XCTAssertEqual(forecast.count, 12)
        XCTAssertEqual(monthString(forecast.first!.month), "2026-06")
        XCTAssertEqual(monthString(forecast.last!.month), "2027-05")
    }

    func testForecastIsRecurringPlusTheOneTimeAllowance() {
        let expenses = [
            // History: 600 of one-time spending over three months, so 200/month.
            expense(amount: 600, on: "2026-04-10"),

            // A recurring charge landing in July only.
            expense(amount: 1_000, on: "2026-07-05", recurrence: .MONTHLY)
        ]

        let forecast = calculator.forecast(expenses: expenses, now: now)

        XCTAssertEqual(forecast[0].amount, 200, "June: allowance only")
        XCTAssertEqual(forecast[1].amount, 1_200, "July: allowance plus the recurring charge")
        XCTAssertEqual(forecast[2].amount, 200, "August: allowance only")
    }

    /// Recurring series that stop partway through are what produce the stepped
    /// decline in the forecast.
    func testForecastStepsDownAsRecurringSeriesEnd() {
        var expenses: [Expense] = []
        for monthsAhead in 0..<3 {
            let month = Calendar.current.date(byAdding: .month, value: monthsAhead, to: now)!
            expenses.append(expense(amount: 500, on: month, recurrence: .MONTHLY))
        }

        let forecast = calculator.forecast(expenses: expenses, now: now)

        XCTAssertEqual(forecast[0].amount, 500)
        XCTAssertEqual(forecast[2].amount, 500)
        XCTAssertEqual(forecast[3].amount, 0, "Nothing recurring left after the series ends")
    }

    // MARK: - Cumulative Balance

    /// The screenshot's first point: 89.775 − 35.717,33 = 54.057,67.
    func testFirstCumulativePointIsIncomeMinusFirstForecast() {
        let forecast = [MonthlyAmountPoint(month: now, amount: 35_717.33)]
        let balance = calculator.cumulativeBalance(forecast: forecast, monthlyIncome: 89_775)

        XCTAssertEqual(balance.first!.balance, 54_057.67, accuracy: 0.01)
    }

    func testCumulativeBalanceAccumulates() {
        let forecast = (0..<3).map { index in
            MonthlyAmountPoint(
                month: Calendar.current.date(byAdding: .month, value: index, to: now)!,
                amount: 400
            )
        }

        let balance = calculator.cumulativeBalance(forecast: forecast, monthlyIncome: 1_000)

        XCTAssertEqual(balance.map(\.balance), [600, 1_200, 1_800])
    }

    func testCumulativeBalanceFallsWhenSpendingExceedsIncome() {
        let forecast = (0..<2).map { index in
            MonthlyAmountPoint(
                month: Calendar.current.date(byAdding: .month, value: index, to: now)!,
                amount: 1_500
            )
        }

        let balance = calculator.cumulativeBalance(forecast: forecast, monthlyIncome: 1_000)
        XCTAssertEqual(balance.map(\.balance), [-500, -1_000])
    }

    func testCumulativeBalanceIsEmptyWithoutAForecast() {
        XCTAssertTrue(calculator.cumulativeBalance(forecast: [], monthlyIncome: 5_000).isEmpty)
    }
}

// MARK: - Fixtures

private extension OverviewCalculatorTests {

    func expense(
        amount: Double,
        on dateString: String,
        currency: String = "₺",
        exchangeRate: Double? = nil,
        recurrence: RecurrenceType = .NONE
    ) -> Expense {
        return expense(
            amount: amount,
            on: OverviewCalculatorTests.date(dateString),
            currency: currency,
            exchangeRate: exchangeRate,
            recurrence: recurrence
        )
    }

    func expense(
        amount: Double,
        on date: Date,
        currency: String = "₺",
        exchangeRate: Double? = nil,
        recurrence: RecurrenceType = .NONE
    ) -> Expense {
        return Expense(
            amount: amount,
            currency: currency,
            categoryId: "food",
            subCategoryId: "sub1",
            description: "test",
            date: date,
            dailyLimitAtCreation: 0,
            monthlyLimitAtCreation: 0,
            exchangeRate: exchangeRate,
            recurrenceType: recurrence
        )
    }

    func monthString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }

    static func date(_ string: String) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.date(from: string)!
    }
}

private func date(_ string: String) -> Date {
    return OverviewCalculatorTests.date(string)
}
