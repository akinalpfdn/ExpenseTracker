//
//  PlanDetailBottomSheet.swift
//  ExpenseTracker
//
//  Created by migration from Android PlanDetailBottomSheet.kt
//

import SwiftUI

struct EditingCell: Equatable {
    let rowIndex: Int
    let cellType: String // "income" or "expenses"
}

struct PlanDetailBottomSheet: View {
    let planWithBreakdowns: PlanWithBreakdowns
    let onUpdateBreakdown: (PlanMonthlyBreakdown) -> Void
    let onUpdateExpenseData: () -> Void
    let isDarkTheme: Bool
    let defaultCurrency: String

    @State private var editingCell: EditingCell?
    @State private var editedValue = ""

    init(
        planWithBreakdowns: PlanWithBreakdowns,
        onUpdateBreakdown: @escaping (PlanMonthlyBreakdown) -> Void = { _ in },
        onUpdateExpenseData: @escaping () -> Void = { },
        isDarkTheme: Bool = true,
        defaultCurrency: String = "₺"
    ) {
        self.planWithBreakdowns = planWithBreakdowns
        self.onUpdateBreakdown = onUpdateBreakdown
        self.onUpdateExpenseData = onUpdateExpenseData
        self.isDarkTheme = isDarkTheme
        self.defaultCurrency = defaultCurrency
    }

    var body: some View {
        VStack(spacing: 16) {
            headerSection
            if plan.useAppExpenseData {
                updateExpenseDataSection
            }
            summaryCard
            tableView
        }
        .padding(16)
    }
}

// MARK: - Computed Properties
extension PlanDetailBottomSheet {
    private var plan: FinancialPlan {
        planWithBreakdowns.plan
    }

    private var breakdowns: [PlanMonthlyBreakdown] {
        planWithBreakdowns.breakdowns
    }

    private var totalNetValue: Double {
        breakdowns.last?.cumulativeNet ?? 0.0
    }
}

// MARK: - View Components
extension PlanDetailBottomSheet {
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(plan.name)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                .multilineTextAlignment(.center)

            Text(PlanningUtils.formatPlanDateRange(startDate: plan.startDate, endDate: plan.endDate))
                .font(.system(size: 14))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                .multilineTextAlignment(.center)
        }
    }

    private var updateExpenseDataSection: some View {
        VStack(spacing: 4) {
            Button(action: onUpdateExpenseData) {
                Text("update_expense_data".localized)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.primaryOrange)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppColors.primaryOrange, lineWidth: 1)
                    )
            }

            Text("update_expense_data_description".localized)
                .font(.system(size: 12))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                .multilineTextAlignment(.center)
        }
    }

    private var summaryCard: some View {
        VStack(spacing: 8) {
            Text("total_net_value".localized)
                .font(.system(size: 14))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))

            Text("\(NumberFormatter.formatAmount(totalNetValue)) \(defaultCurrency)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(totalNetValue >= 0 ?
                    ThemeColors.getSuccessGreenColor(isDarkTheme: isDarkTheme) :
                    ThemeColors.getDeleteRedColor(isDarkTheme: isDarkTheme))
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(AppColors.primaryOrange.opacity(0.1))
        .cornerRadius(12)
    }

    private var tableView: some View {
        VStack(spacing: 0) {
            tableHeader
            Rectangle()
                .fill(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme).opacity(0.2))
                .frame(height: 1)
            tableContent
        }
    }

    private var tableHeader: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                Spacer().frame(width: 26) // For edit button space

                headerCell("income".localized, weight: 1.6)
                headerCell("expense".localized, weight: 1.6)
                headerCell("net".localized, weight: 1.6)
                headerCell("total".localized, weight: 1.6)
                headerCell("month".localized, weight: 1.0)
            }
            .frame(width: 400)
        }
        .background(
            ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme).opacity(0.1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .clipped()
    }

    private func headerCell(_ text: String, weight: Double) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
            .frame(maxWidth: .infinity)
            .frame(width: 60 * weight)
            .multilineTextAlignment(.center)
            .padding(4)
    }

    private var tableContent: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(Array(breakdowns.enumerated()), id: \.offset) { index, breakdown in
                    tableRow(breakdown: breakdown, index: index)
                }
            }
        }
    }

    private func tableRow(breakdown: PlanMonthlyBreakdown, index: Int) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                editButtonSection(breakdown: breakdown, index: index)
                incomeCell(breakdown: breakdown, index: index)
                expensesCell(breakdown: breakdown, index: index)
                netCell(breakdown: breakdown, index: index)
                cumulativeCell(breakdown: breakdown)
                monthCell(breakdown: breakdown)
            }
            .frame(width: 400)
        }
        .background(
            index % 2 == 0 ? Color.clear :
            ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme).opacity(0.05)
        )
        .padding(.vertical, 4)
    }

    private func editButtonSection(breakdown: PlanMonthlyBreakdown, index: Int) -> some View {
        Group {
            if isEditing(index: index) {
                Button(action: { saveEdit(breakdown: breakdown, index: index) }) {
                    Image(systemName: "checkmark")
                        .foregroundColor(AppColors.primaryOrange)
                        .font(.system(size: 16))
                }
                .frame(width: 26, height: 26)
            } else {
                Spacer().frame(width: 26, height: 26)
            }
        }
    }

    private func incomeCell(breakdown: PlanMonthlyBreakdown, index: Int) -> some View {
        Group {
            if isEditingIncome(index: index) {
                TextField("", text: $editedValue)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 12))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                    .multilineTextAlignment(.center)
                    .keyboardType(.decimalPad)
                    .padding(8)
                    .background(ThemeColors.getInputBackgroundColor(isDarkTheme: isDarkTheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(AppColors.primaryOrange, lineWidth: 1)
                    )
                    .cornerRadius(6)
            } else {
                Button(action: { startEditingIncome(breakdown: breakdown, index: index) }) {
                    Text(NumberFormatter.formatAmount(breakdown.projectedIncome))
                        .font(.system(size: 12))
                        .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                        .frame(maxWidth: .infinity)
                        .padding(8)
                }
            }
        }
        .frame(width: 96)
    }

    private func expensesCell(breakdown: PlanMonthlyBreakdown, index: Int) -> some View {
        Group {
            if isEditingExpenses(index: index) {
                TextField("", text: $editedValue)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 12))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                    .multilineTextAlignment(.center)
                    .keyboardType(.decimalPad)
                    .padding(8)
                    .background(ThemeColors.getInputBackgroundColor(isDarkTheme: isDarkTheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(AppColors.primaryOrange, lineWidth: 1)
                    )
                    .cornerRadius(6)
            } else {
                Button(action: { startEditingExpenses(breakdown: breakdown, index: index) }) {
                    Text(NumberFormatter.formatAmount(breakdown.totalProjectedExpenses))
                        .font(.system(size: 12))
                        .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                        .frame(maxWidth: .infinity)
                        .padding(8)
                }
            }
        }
        .frame(width: 96)
    }

    private func netCell(breakdown: PlanMonthlyBreakdown, index: Int) -> some View {
        let currentIncome = isEditingIncome(index: index) ?
            (Double(editedValue) ?? breakdown.projectedIncome) : breakdown.projectedIncome
        let currentExpenses = isEditingExpenses(index: index) ?
            (Double(editedValue) ?? breakdown.totalProjectedExpenses) : breakdown.totalProjectedExpenses
        let netAmount = currentIncome - currentExpenses

        return Text(NumberFormatter.formatAmount(netAmount))
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(netAmount >= 0 ?
                ThemeColors.getSuccessGreenColor(isDarkTheme: isDarkTheme) :
                ThemeColors.getDeleteRedColor(isDarkTheme: isDarkTheme))
            .frame(width: 90)
            .multilineTextAlignment(.center)
            .padding(8)
    }

    private func cumulativeCell(breakdown: PlanMonthlyBreakdown) -> some View {
        Text(NumberFormatter.formatAmount(breakdown.cumulativeNet))
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(breakdown.cumulativeNet >= 0 ?
                ThemeColors.getSuccessGreenColor(isDarkTheme: isDarkTheme) :
                ThemeColors.getDeleteRedColor(isDarkTheme: isDarkTheme))
            .frame(width: 96)
            .multilineTextAlignment(.center)
            .padding(8)
    }

    private func monthCell(breakdown: PlanMonthlyBreakdown) -> some View {
        Text(PlanningUtils.getMonthName(plan: plan, monthIndex: breakdown.monthIndex))
            .font(.system(size: 12))
            .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
            .frame(width: 60)
            .multilineTextAlignment(.center)
            .padding(8)
    }
}

// MARK: - Helper Methods
extension PlanDetailBottomSheet {
    private func isEditing(index: Int) -> Bool {
        editingCell?.rowIndex == index
    }

    private func isEditingIncome(index: Int) -> Bool {
        editingCell?.rowIndex == index && editingCell?.cellType == "income"
    }

    private func isEditingExpenses(index: Int) -> Bool {
        editingCell?.rowIndex == index && editingCell?.cellType == "expenses"
    }

    private func startEditingIncome(breakdown: PlanMonthlyBreakdown, index: Int) {
        editingCell = EditingCell(rowIndex: index, cellType: "income")
        editedValue = String(format: "%.2f", breakdown.projectedIncome)
    }

    private func startEditingExpenses(breakdown: PlanMonthlyBreakdown, index: Int) {
        editingCell = EditingCell(rowIndex: index, cellType: "expenses")
        editedValue = String(format: "%.2f", breakdown.totalProjectedExpenses)
    }

    private func saveEdit(breakdown: PlanMonthlyBreakdown, index: Int) {
        guard let newValue = Double(editedValue) else { return }

        let updatedBreakdown: PlanMonthlyBreakdown

        if isEditingIncome(index: index) {
            updatedBreakdown = PlanMonthlyBreakdown(
                id: breakdown.id,
                planId: breakdown.planId,
                monthIndex: breakdown.monthIndex,
                projectedIncome: newValue,
                fixedExpenses: breakdown.fixedExpenses,
                averageExpenses: breakdown.averageExpenses,
                totalProjectedExpenses: breakdown.totalProjectedExpenses,
                netAmount: newValue - breakdown.totalProjectedExpenses,
                interestEarned: breakdown.interestEarned,
                cumulativeNet: breakdown.cumulativeNet
            )
        } else {
            updatedBreakdown = PlanMonthlyBreakdown(
                id: breakdown.id,
                planId: breakdown.planId,
                monthIndex: breakdown.monthIndex,
                projectedIncome: breakdown.projectedIncome,
                fixedExpenses: breakdown.fixedExpenses,
                averageExpenses: breakdown.averageExpenses,
                totalProjectedExpenses: newValue,
                netAmount: breakdown.projectedIncome - newValue,
                interestEarned: breakdown.interestEarned,
                cumulativeNet: breakdown.cumulativeNet
            )
        }

        onUpdateBreakdown(updatedBreakdown)
        editingCell = nil
        editedValue = ""
    }
}

// MARK: - Preview
struct PlanDetailBottomSheet_Previews: PreviewProvider {
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
            ),
            PlanMonthlyBreakdown(
                planId: samplePlan.id,
                monthIndex: 2,
                projectedIncome: 8000.0,
                fixedExpenses: 3200.0,
                averageExpenses: 2200.0,
                totalProjectedExpenses: 5400.0,
                netAmount: 2600.0,
                cumulativeNet: 8100.0
            )
        ]

        let samplePlanWithBreakdowns = PlanWithBreakdowns(
            plan: samplePlan,
            breakdowns: sampleBreakdowns
        )

        PlanDetailBottomSheet(
            planWithBreakdowns: samplePlanWithBreakdowns,
            isDarkTheme: true,
            defaultCurrency: "₺"
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}