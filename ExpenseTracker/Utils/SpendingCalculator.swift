//
//  SpendingCalculator.swift
//  ExpenseTracker
//
//  The arithmetic behind the overview screen, kept free of Core Data and SwiftUI so
//  it can be tested directly. `now` is a parameter rather than a call to `Date()` so
//  tests are not sensitive to the day they run on.
//

import Foundation

struct SpendingCalculator {

    private let calendar: Calendar
    private let defaultCurrency: String

    init(defaultCurrency: String, calendar: Calendar = .current) {
        self.defaultCurrency = defaultCurrency
        self.calendar = calendar
    }

    // MARK: - Current Month

    /// What has been spent in the month containing `date`, as of `asOf`.
    ///
    /// Occurrences dated later than `asOf` are excluded. Recurring expenses are stored
    /// as rows a year ahead, so a subscription due on the 25th would otherwise read as
    /// money already gone on the 9th — wrong under a heading that says "spent", and
    /// wrong as the basis for a limit warning.
    func monthSpending(expenses: [Expense], in date: Date, asOf: Date) -> Double {
        guard let month = monthInterval(containing: date) else { return 0 }
        return amount(of: expenses.filter { month.contains($0.date) && $0.date <= asOf })
    }

    /// The month containing `now`, up to `now`.
    func currentMonthSpending(expenses: [Expense], now: Date) -> Double {
        return monthSpending(expenses: expenses, in: now, asOf: now)
    }

    /// Income minus what has been spent this month. Goes negative when overspent,
    /// which the caller is expected to show rather than clamp.
    func remaining(monthlyIncome: Double, currentMonthSpending: Double) -> Double {
        return monthlyIncome - currentMonthSpending
    }

    // MARK: - Spending Trend

    /// Actual monthly totals, oldest first, ending with the month containing `now`.
    /// The final entry is a partial month.
    func spendingTrend(expenses: [Expense], range: TrendRange, now: Date) -> [MonthlyAmountPoint] {
        let monthCount = range.rawValue

        return (0..<monthCount).reversed().compactMap { monthsAgo in
            guard let monthStart = calendar.date(byAdding: .month, value: -monthsAgo, to: startOfMonth(for: now)),
                  let interval = monthInterval(containing: monthStart) else {
                return nil
            }

            return MonthlyAmountPoint(
                month: monthStart,
                amount: total(of: expenses, within: interval)
            )
        }
    }

    // MARK: - Forecast

    /// Projected spending for each of the next `months` months, starting with the
    /// month containing `now`.
    ///
    /// Each month is its own recurring expenses plus a flat allowance for one-time
    /// spending, taken as the average of the last three months. Recurring occurrences
    /// are already stored as individual rows up to a year ahead, so future months are
    /// read from real data rather than extrapolated.
    func forecast(expenses: [Expense], now: Date, months: Int = 12) -> [MonthlyAmountPoint] {
        let oneTimeAllowance = averageMonthlyOneTimeSpending(expenses: expenses, now: now)

        return (0..<months).compactMap { monthsAhead in
            guard let monthStart = calendar.date(byAdding: .month, value: monthsAhead, to: startOfMonth(for: now)),
                  let interval = monthInterval(containing: monthStart) else {
                return nil
            }

            let recurring = total(
                of: expenses.filter { $0.recurrenceType != .NONE },
                within: interval
            )

            return MonthlyAmountPoint(month: monthStart, amount: recurring + oneTimeAllowance)
        }
    }

    /// Mean monthly one-time spending over the three months before `now`.
    ///
    /// The current month is excluded: it is partial, and including it would drag the
    /// average down by however far into the month the user happens to be.
    func averageMonthlyOneTimeSpending(expenses: [Expense], now: Date, monthsBack: Int = 3) -> Double {
        guard monthsBack > 0 else { return 0 }

        let currentMonthStart = startOfMonth(for: now)
        guard let windowStart = calendar.date(byAdding: .month, value: -monthsBack, to: currentMonthStart) else {
            return 0
        }

        let oneTime = expenses.filter {
            $0.recurrenceType == .NONE && $0.date >= windowStart && $0.date < currentMonthStart
        }

        return amount(of: oneTime) / Double(monthsBack)
    }

    // MARK: - Cumulative Balance

    /// Running total of what is left over each month, so the last point is the
    /// projected balance at the end of the forecast.
    func cumulativeBalance(forecast: [MonthlyAmountPoint], monthlyIncome: Double) -> [CumulativeBalancePoint] {
        var running = 0.0

        return forecast.map { point in
            running += monthlyIncome - point.amount
            return CumulativeBalancePoint(month: point.month, balance: running)
        }
    }

    // MARK: - Helpers

    private func startOfMonth(for date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }

    /// Half-open interval `[start of month, start of next month)`, so an expense
    /// timestamped at the last instant of a month is not lost to a rounding edge.
    private func monthInterval(containing date: Date) -> Range<Date>? {
        let start = startOfMonth(for: date)
        guard let end = calendar.date(byAdding: .month, value: 1, to: start) else { return nil }
        return start..<end
    }

    private func total(of expenses: [Expense], within interval: Range<Date>) -> Double {
        return amount(of: expenses.filter { interval.contains($0.date) })
    }

    /// Always converts. An expense in a foreign currency counted at face value would
    /// silently distort every figure on this screen.
    private func amount(of expenses: [Expense]) -> Double {
        return expenses.reduce(0.0) {
            $0 + $1.getAmountInDefaultCurrency(defaultCurrency: defaultCurrency)
        }
    }
}
