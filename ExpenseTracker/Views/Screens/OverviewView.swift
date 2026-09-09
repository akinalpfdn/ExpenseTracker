//
//  OverviewView.swift
//  ExpenseTracker
//
//  Where the money went this month, where it has been going, and where it is heading.
//

import SwiftUI

struct OverviewView: View {
    @EnvironmentObject var expenseViewModel: ExpenseViewModel
    @EnvironmentObject var preferencesManager: PreferencesManager

    @StateObject private var viewModel: OverviewViewModel

    let isDarkTheme: Bool

    @State private var showingIncomeEditor = false

    init(isDarkTheme: Bool, expenseViewModel: ExpenseViewModel, preferencesManager: PreferencesManager) {
        self.isDarkTheme = isDarkTheme
        self._viewModel = StateObject(wrappedValue: OverviewViewModel(
            expenseViewModel: expenseViewModel,
            preferencesManager: preferencesManager
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                title
                summaryCard
                rangeSelector
                trendCard
                forecastCard

                // Room for the page indicator that sits over the bottom of the screen.
                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .background(ThemeColors.getBackgroundColor(isDarkTheme: isDarkTheme))
        .sheet(isPresented: $showingIncomeEditor) {
            EditMonthlyIncomeDialog(
                isDarkTheme: isDarkTheme,
                onDismiss: { showingIncomeEditor = false }
            )
            .environmentObject(preferencesManager)
        }
    }
}

// MARK: - Sections

private extension OverviewView {

    var title: some View {
        Text("overview".localized)
            .font(.system(size: 28, weight: .bold))
            .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
    }

    var summaryCard: some View {
        OverviewSummaryCard(
            currentMonthSpending: viewModel.currentMonthSpending,
            monthlyIncome: preferencesManager.monthlyNetIncomeValue,
            remaining: viewModel.remaining,
            hasIncomeConfigured: viewModel.hasIncomeConfigured,
            currency: preferencesManager.defaultCurrency,
            isDarkTheme: isDarkTheme,
            onEditIncome: { showingIncomeEditor = true }
        )
    }

    var rangeSelector: some View {
        HStack(spacing: 12) {
            ForEach(TrendRange.allCases) { range in
                Button(action: { viewModel.selectedRange = range }) {
                    Text(range.displayName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(
                            viewModel.selectedRange == range
                                ? AppColors.textWhite
                                : ThemeColors.getTextColor(isDarkTheme: isDarkTheme)
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            viewModel.selectedRange == range
                                ? AppColors.primaryOrange
                                : ThemeColors.getCardBackgroundColor(isDarkTheme: isDarkTheme)
                        )
                        .cornerRadius(22)
                }
            }
        }
    }

    var trendCard: some View {
        card {
            VStack(alignment: .leading, spacing: 16) {
                Text("spending_trend".localized)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

                OverviewBarChart(
                    points: viewModel.spendingTrend,
                    barColor: AppColors.primaryOrange,
                    isDarkTheme: isDarkTheme
                )

                trendFooter
            }
        }
    }

    var trendFooter: some View {
        HStack {
            Text("\("average".localized): \(formatted(viewModel.trendAverage))")
            Spacer()
            Text("\("total".localized): \(formatted(viewModel.trendTotal))")
        }
        .font(.system(size: 13))
        .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
    }

    var forecastCard: some View {
        card {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("forecast_12_months".localized)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

                    Text("forecast_description".localized)
                        .font(.system(size: 13))
                        .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                        .fixedSize(horizontal: false, vertical: true)
                }

                OverviewBarChart(
                    points: viewModel.forecast,
                    barColor: AppColors.forecastBlue,
                    isDarkTheme: isDarkTheme
                )

                // The balance projection is meaningless without an income to project
                // against, so it stays hidden until one is set.
                if viewModel.hasIncomeConfigured {
                    Divider()
                        .background(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme).opacity(0.3))

                    cumulativeSection
                }
            }
        }
    }

    var cumulativeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("cumulative_balance".localized)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            CumulativeBalanceChart(
                points: viewModel.cumulativeBalance,
                isDarkTheme: isDarkTheme
            )

            HStack {
                Text("after_12_months".localized)
                    .font(.system(size: 13))
                    .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))

                Spacer()

                Text(formatted(viewModel.projectedBalance))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(
                        viewModel.projectedBalance < 0
                            ? ThemeColors.getDeleteRedColor(isDarkTheme: isDarkTheme)
                            : ThemeColors.getSuccessGreenColor(isDarkTheme: isDarkTheme)
                    )
            }
        }
    }
}

// MARK: - Helpers

private extension OverviewView {

    func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ThemeColors.getCardBackgroundColor(isDarkTheme: isDarkTheme))
            .cornerRadius(16)
    }

    func formatted(_ value: Double) -> String {
        return "\(preferencesManager.defaultCurrency) \(CurrencyInputFormatter.format(value))"
    }
}
