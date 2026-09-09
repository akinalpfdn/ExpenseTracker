//
//  OverviewViewModel.swift
//  ExpenseTracker
//
//  Derives the overview screen's figures from the expenses the app already holds.
//  All arithmetic lives in SpendingCalculator; this only decides when to run it.
//

import Foundation
import Combine

@MainActor
class OverviewViewModel: ObservableObject {

    @Published var selectedRange: TrendRange = .oneYear

    @Published private(set) var currentMonthSpending: Double = 0
    @Published private(set) var remaining: Double = 0
    @Published private(set) var spendingTrend: [MonthlyAmountPoint] = []
    @Published private(set) var forecast: [MonthlyAmountPoint] = []
    @Published private(set) var cumulativeBalance: [CumulativeBalancePoint] = []

    private var cancellables = Set<AnyCancellable>()

    /// The forecast horizon, also the number of points on the cumulative line.
    private let forecastMonths = 12

    // MARK: - Derived Figures

    var trendTotal: Double {
        spendingTrend.reduce(0) { $0 + $1.amount }
    }

    var trendAverage: Double {
        spendingTrend.isEmpty ? 0 : trendTotal / Double(spendingTrend.count)
    }

    /// Balance at the end of the forecast — the figure shown under the line chart.
    var projectedBalance: Double {
        cumulativeBalance.last?.balance ?? 0
    }

    /// Nothing to project against until the user has told us what they earn.
    var hasIncomeConfigured: Bool {
        monthlyIncome > 0
    }

    private var monthlyIncome: Double {
        preferencesManager.monthlyNetIncomeValue
    }

    // MARK: - Dependencies

    private let expenseViewModel: ExpenseViewModel
    private let preferencesManager: PreferencesManager

    init(expenseViewModel: ExpenseViewModel, preferencesManager: PreferencesManager) {
        self.expenseViewModel = expenseViewModel
        self.preferencesManager = preferencesManager

        observeInputs()
        recalculate()
    }

    // MARK: - Recalculation

    /// Recompute whenever anything the figures depend on moves: the expense set, the
    /// income, the currency, or the selected range.
    private func observeInputs() {
        expenseViewModel.$expenses
            .sink { [weak self] _ in self?.recalculate() }
            .store(in: &cancellables)

        preferencesManager.$monthlyNetIncome
            .sink { [weak self] _ in self?.recalculate() }
            .store(in: &cancellables)

        preferencesManager.$defaultCurrency
            .sink { [weak self] _ in self?.recalculate() }
            .store(in: &cancellables)

        $selectedRange
            .sink { [weak self] range in self?.recalculateTrend(range: range) }
            .store(in: &cancellables)
    }

    func recalculate() {
        let calculator = makeCalculator()
        let expenses = expenseViewModel.expenses
        let now = Date()

        currentMonthSpending = calculator.currentMonthSpending(expenses: expenses, now: now)
        remaining = calculator.remaining(
            monthlyIncome: monthlyIncome,
            currentMonthSpending: currentMonthSpending
        )

        spendingTrend = calculator.spendingTrend(expenses: expenses, range: selectedRange, now: now)

        forecast = calculator.forecast(expenses: expenses, now: now, months: forecastMonths)
        cumulativeBalance = calculator.cumulativeBalance(
            forecast: forecast,
            monthlyIncome: monthlyIncome
        )
    }

    /// Changing the range only moves the trend chart; the forecast is fixed at twelve
    /// months, so there is no reason to redo it.
    private func recalculateTrend(range: TrendRange) {
        spendingTrend = makeCalculator().spendingTrend(
            expenses: expenseViewModel.expenses,
            range: range,
            now: Date()
        )
    }

    private func makeCalculator() -> SpendingCalculator {
        return SpendingCalculator(defaultCurrency: preferencesManager.defaultCurrency)
    }
}
