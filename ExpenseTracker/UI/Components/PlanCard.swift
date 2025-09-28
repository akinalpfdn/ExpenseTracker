//
//  PlanCard.swift
//  ExpenseTracker
//
//  Created by migration from Android PlanCard.kt
//

import SwiftUI

struct PlanCard: View {
    let planWithBreakdowns: PlanWithBreakdowns
    let onCardClick: () -> Void
    let onDeleteClick: () -> Void
    let isDarkTheme: Bool
    let defaultCurrency: String

    init(
        planWithBreakdowns: PlanWithBreakdowns,
        onCardClick: @escaping () -> Void = { },
        onDeleteClick: @escaping () -> Void = { },
        isDarkTheme: Bool = true,
        defaultCurrency: String = "₺"
    ) {
        self.planWithBreakdowns = planWithBreakdowns
        self.onCardClick = onCardClick
        self.onDeleteClick = onDeleteClick
        self.isDarkTheme = isDarkTheme
        self.defaultCurrency = defaultCurrency
    }

    var body: some View {
        Button(action: onCardClick) {
            cardContent
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture {
            onDeleteClick()
        }
    }
}

// MARK: - Card Content
extension PlanCard {
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection
            averageIncomeExpenseRow
            netWorthSummaryRow
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ThemeColors.getCardBackgroundColor(isDarkTheme: isDarkTheme))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(plan.name)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                .lineLimit(1)

            Text(PlanningUtils.formatPlanDateRange(startDate: plan.startDate, endDate: plan.endDate))
                .font(.system(size: 14))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
        }
    }

    private var averageIncomeExpenseRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("avg_monthly_income".localized)
                    .font(.system(size: 12))
                    .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))

                Text("\(NumberFormatter.formatAmount(avgMonthlyIncome)) \(defaultCurrency)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ThemeColors.getSuccessGreenColor(isDarkTheme: isDarkTheme))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("avg_monthly_expense".localized)
                    .font(.system(size: 12))
                    .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))

                Text("\(NumberFormatter.formatAmount(avgMonthlyExpenses)) \(defaultCurrency)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ThemeColors.getDeleteRedColor(isDarkTheme: isDarkTheme))
            }
        }
    }

    private var netWorthSummaryRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("current_net".localized)
                    .font(.system(size: 12))
                    .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))

                Text("\(NumberFormatter.formatAmount(currentNet)) \(defaultCurrency)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(currentNet >= 0 ?
                        ThemeColors.getSuccessGreenColor(isDarkTheme: isDarkTheme) :
                        ThemeColors.getDeleteRedColor(isDarkTheme: isDarkTheme))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: totalProjectedSavings >= 0 ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis")
                        .foregroundColor(totalProjectedSavings >= 0 ?
                            ThemeColors.getSuccessGreenColor(isDarkTheme: isDarkTheme) :
                            ThemeColors.getDeleteRedColor(isDarkTheme: isDarkTheme))
                        .font(.system(size: 16))

                    Text("target_net".localized)
                        .font(.system(size: 12))
                        .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                }

                Text("\(NumberFormatter.formatAmount(totalProjectedSavings)) \(defaultCurrency)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(totalProjectedSavings >= 0 ?
                        ThemeColors.getSuccessGreenColor(isDarkTheme: isDarkTheme) :
                        ThemeColors.getDeleteRedColor(isDarkTheme: isDarkTheme))
            }
        }
    }
}

// MARK: - Computed Properties
extension PlanCard {
    private var plan: FinancialPlan {
        planWithBreakdowns.plan
    }

    private var breakdowns: [PlanMonthlyBreakdown] {
        planWithBreakdowns.breakdowns
    }

    private var totalProjectedSavings: Double {
        PlanningUtils.calculateTotalProjectedSavings(breakdowns: breakdowns)
    }

    private var monthsElapsed: Int {
        plan.getMonthsElapsed()
    }

    private var currentNet: Double {
        if monthsElapsed > 0 && monthsElapsed <= breakdowns.count {
            return breakdowns[monthsElapsed - 1].cumulativeNet
        }
        return 0.0
    }

    private var avgMonthlyIncome: Double {
        if !breakdowns.isEmpty {
            return breakdowns.reduce(0) { $0 + $1.projectedIncome } / Double(breakdowns.count)
        }
        return plan.monthlyIncome
    }

    private var avgMonthlyExpenses: Double {
        if !breakdowns.isEmpty {
            return breakdowns.reduce(0) { $0 + $1.totalProjectedExpenses } / Double(breakdowns.count)
        }
        return 0.0
    }
}


// MARK: - Preview
struct PlanCard_Previews: PreviewProvider {
    static var previews: some View {
        let samplePlan = FinancialPlan(
            name: "5 Year Savings Plan",
            startDate: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date(),
            durationInMonths: 60,
            monthlyIncome: 8000.0,
            manualMonthlyExpenses: 5000.0,
            useAppExpenseData: true,
            isInflationApplied: true,
            inflationRate: 3.0,
            isInterestApplied: true,
            interestRate: 2.5,
            interestType: .compound,
            defaultCurrency: "₺"
        )

        let sampleBreakdowns = [
            PlanMonthlyBreakdown(
                planId: samplePlan.id,
                monthIndex: 0,
                projectedIncome: 8000.0,
                fixedExpenses: 3000.0,
                averageExpenses: 2200.0,
                totalProjectedExpenses: 5200.0,
                netAmount: 2800.0,
                cumulativeNet: 2800.0
            ),
            PlanMonthlyBreakdown(
                planId: samplePlan.id,
                monthIndex: 1,
                projectedIncome: 8000.0,
                fixedExpenses: 3100.0,
                averageExpenses: 2200.0,
                totalProjectedExpenses: 5300.0,
                netAmount: 2700.0,
                cumulativeNet: 5500.0
            )
        ]

        let samplePlanWithBreakdowns = PlanWithBreakdowns(
            plan: samplePlan,
            breakdowns: sampleBreakdowns
        )

        VStack(spacing: 16) {
            PlanCard(
                planWithBreakdowns: samplePlanWithBreakdowns,
                isDarkTheme: true,
                defaultCurrency: "₺"
            )

            PlanCard(
                planWithBreakdowns: samplePlanWithBreakdowns,
                isDarkTheme: false,
                defaultCurrency: "$"
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}