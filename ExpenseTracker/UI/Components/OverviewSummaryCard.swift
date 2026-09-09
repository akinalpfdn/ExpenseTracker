//
//  OverviewSummaryCard.swift
//  ExpenseTracker
//
//  The card at the top of the overview: what was spent this month, what comes in,
//  and what is left.
//

import SwiftUI

struct OverviewSummaryCard: View {
    let currentMonthSpending: Double
    let monthlyIncome: Double
    let remaining: Double
    let hasIncomeConfigured: Bool
    let currency: String
    let isDarkTheme: Bool

    let onEditIncome: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            spendingSection

            Divider()
                .background(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme).opacity(0.3))

            incomeSection
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ThemeColors.getCardBackgroundColor(isDarkTheme: isDarkTheme))
        .cornerRadius(16)
    }
}

// MARK: - Sections

private extension OverviewSummaryCard {

    var spendingSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("this_month_spending".localized)
                .font(.system(size: 14))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))

            Text(formatted(currentMonthSpending))
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
    }

    var incomeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("monthly_net_income".localized)
                        .font(.system(size: 14))
                        .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))

                    Text(hasIncomeConfigured ? formatted(monthlyIncome) : "not_set".localized)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }

                Spacer()

                Button(action: onEditIncome) {
                    Image(systemName: "pencil")
                        .font(.system(size: 18))
                        .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                        .padding(8)
                }
                .accessibilityLabel("edit_monthly_income".localized)
            }

            if hasIncomeConfigured {
                remainingRow
            }
        }
    }

    /// Only shown once income is known — "remaining" against an income of zero would
    /// read as a large negative number and mean nothing.
    var remainingRow: some View {
        HStack {
            Text("remaining".localized)
                .font(.system(size: 14))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))

            Spacer()

            Text(formatted(remaining))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(
                    remaining < 0
                        ? ThemeColors.getDeleteRedColor(isDarkTheme: isDarkTheme)
                        : ThemeColors.getSuccessGreenColor(isDarkTheme: isDarkTheme)
                )
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
    }

    func formatted(_ value: Double) -> String {
        return "\(currency) \(CurrencyInputFormatter.format(value))"
    }
}
