//
//  PlanCard.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import SwiftUI

struct PlanCard: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var planningViewModel: PlanningViewModel

    let plan: FinancialPlan
    let isSelected: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showingDeleteConfirmation = false
    @State private var isPressed = false

    private var progressPercentage: Double {
        guard plan.totalBudget > 0 else { return 0 }
        let currentSpending = planningViewModel.getCurrentSpending(for: plan)
        return min(currentSpending / plan.totalBudget, 1.0) * 100
    }

    private var remainingBudget: Double {
        let currentSpending = planningViewModel.getCurrentSpending(for: plan)
        return max(0, plan.totalBudget - currentSpending)
    }

    private var daysRemaining: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: Date(), to: plan.endDate).day ?? 0
    }

    private var isOverBudget: Bool {
        progressPercentage > 100
    }

    private var statusColor: Color {
        switch plan.status {
        case .active:
            return isOverBudget ? AppColors.primaryRed : AppColors.successGreen
        case .paused:
            return .orange
        case .completed:
            return .blue
        case .cancelled:
            return .red
        case .draft:
            return .gray
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            cardHeader

            cardContent

            cardFooter
        }
        .background(cardBackground)
        .overlay(cardBorder)
        .cornerRadius(16)
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowOffset)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                onTap()
            }
        }
        .contextMenu {
            contextMenuItems
        }
        .confirmationDialog(
            L("delete_plan_confirmation"),
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(L("delete"), role: .destructive) {
                onDelete()
            }
            Button(L("cancel"), role: .cancel) {}
        } message: {
            Text(L("delete_plan_confirmation_message", plan.name))
        }
    }

    private var cardHeader: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: plan.planType.icon)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(statusColor)

                Text(plan.name)
                    .font(AppTypography.cardTitle)
                    .foregroundColor(ThemeColors.textColor(for: colorScheme))
                    .lineLimit(1)
            }

            Spacer()

            statusBadge
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private var statusBadge: some View {
        Text(plan.status.displayName)
            .font(AppTypography.labelSmall)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(statusColor)
            )
    }

    private var cardContent: some View {
        VStack(spacing: 12) {
            if !plan.description.isEmpty {
                HStack {
                    Text(plan.description)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Spacer()
                }
            }

            planMetricsView

            progressSection
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var planMetricsView: some View {
        VStack(spacing: 8) {
            HStack {
                metricItem(
                    title: L("total_income"),
                    value: formatCurrency(plan.totalIncome),
                    icon: "plus.circle.fill",
                    color: AppColors.successGreen
                )

                Spacer()

                metricItem(
                    title: L("savings_goal"),
                    value: formatCurrency(plan.savingsGoal),
                    icon: "target",
                    color: AppColors.primaryOrange
                )
            }

            HStack {
                metricItem(
                    title: L("monthly_budget"),
                    value: formatCurrency(plan.totalBudget),
                    icon: "chart.pie.fill",
                    color: .blue
                )

                Spacer()

                metricItem(
                    title: L("remaining"),
                    value: formatCurrency(remainingBudget),
                    icon: "banknote.fill",
                    color: isOverBudget ? AppColors.primaryRed : AppColors.successGreen
                )
            }
        }
    }

    private func metricItem(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(AppTypography.labelSmall)
                    .foregroundColor(color)

                Text(title)
                    .font(AppTypography.labelSmall)
                    .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
            }

            Text(value)
                .font(AppTypography.labelMedium)
                .foregroundColor(ThemeColors.textColor(for: colorScheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var progressSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text(L("budget_usage"))
                    .font(AppTypography.labelMedium)
                    .foregroundColor(ThemeColors.textColor(for: colorScheme))

                Spacer()

                Text("\(String(format: "%.1f", progressPercentage))%")
                    .font(AppTypography.labelMedium)
                    .foregroundColor(isOverBudget ? AppColors.primaryRed : AppColors.primaryOrange)
            }

            ProgressView(value: min(progressPercentage / 100, 1.0))
                .progressViewStyle(LinearProgressViewStyle(tint: isOverBudget ? AppColors.primaryRed : AppColors.primaryOrange))
                .scaleEffect(x: 1, y: 1.5, anchor: .center)

            if isOverBudget {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.primaryRed)

                    Text(L("over_budget_warning"))
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.primaryRed)

                    Spacer()
                }
            }
        }
    }

    private var cardFooter: some View {
        HStack {
            HStack(spacing: 16) {
                footerItem(
                    icon: "calendar",
                    text: formatDateRange(),
                    color: ThemeColors.textGrayColor(for: colorScheme)
                )

                if daysRemaining > 0 {
                    footerItem(
                        icon: "clock",
                        text: L("days_remaining", daysRemaining),
                        color: daysRemaining < 30 ? AppColors.primaryRed : ThemeColors.textGrayColor(for: colorScheme)
                    )
                }
            }

            Spacer()

            if plan.status == .active {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.primaryOrange)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private func footerItem(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(AppTypography.labelSmall)
                .foregroundColor(color)

            Text(text)
                .font(AppTypography.labelSmall)
                .foregroundColor(color)
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(isSelected ?
                  statusColor.opacity(0.05) :
                  ThemeColors.cardBackgroundColor(for: colorScheme))
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(
                isSelected ?
                statusColor.opacity(0.3) :
                ThemeColors.textGrayColor(for: colorScheme).opacity(0.1),
                lineWidth: isSelected ? 2 : 1
            )
    }

    private var shadowColor: Color {
        if isSelected {
            return statusColor.opacity(0.2)
        } else {
            return Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1)
        }
    }

    private var shadowRadius: CGFloat {
        isSelected ? 8 : 4
    }

    private var shadowOffset: CGFloat {
        isSelected ? 4 : 2
    }

    @ViewBuilder
    private var contextMenuItems: some View {
        Button(action: onTap) {
            Label(L("view_details"), systemImage: "eye")
        }

        if plan.status == .active || plan.status == .paused {
            Button(action: onEdit) {
                Label(L("edit_plan"), systemImage: "pencil")
            }
        }

        if plan.status == .active {
            Button(action: {
                Task {
                    await planningViewModel.deactivatePlan(plan)
                }
            }) {
                Label(L("pause_plan"), systemImage: "pause")
            }
        } else if plan.status == .paused {
            Button(action: {
                Task {
                    await planningViewModel.activatePlan(plan)
                }
            }) {
                Label(L("resume_plan"), systemImage: "play")
            }
        }

        Divider()

        Button(action: {
            planningViewModel.duplicatePlan(plan)
        }) {
            Label(L("duplicate_plan"), systemImage: "doc.on.doc")
        }

        Button(role: .destructive, action: {
            showingDeleteConfirmation = true
        }) {
            Label(L("delete_plan"), systemImage: "trash")
        }
    }

    // MARK: - Helper Functions

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = plan.currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"
    }

    private func formatDateRange() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("MMM d")

        let startString = formatter.string(from: plan.startDate)
        let endString = formatter.string(from: plan.endDate)

        return "\(startString) - \(endString)"
    }
}

// MARK: - PlanningViewModel Extension

extension PlanningViewModel {
    func getCurrentSpending(for plan: FinancialPlan) -> Double {
        let calendar = Calendar.current
        let now = Date()

        // Get expenses for current month
        guard let monthStart = calendar.dateInterval(of: .month, for: now)?.start,
              let monthEnd = calendar.dateInterval(of: .month, for: now)?.end else {
            return 0
        }

        // This would typically come from expense data filtered by the plan's date range
        // For now, returning a placeholder calculation
        return plan.totalBudget * 0.65 // Placeholder: 65% of budget used
    }
}

// MARK: - Plan Grid View

struct PlanGridView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var planningViewModel: PlanningViewModel

    let plans: [FinancialPlan]
    let selectedPlan: FinancialPlan?
    let onPlanSelected: (FinancialPlan) -> Void
    let onPlanEdit: (FinancialPlan) -> Void
    let onPlanDelete: (FinancialPlan) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(plans, id: \.id) { plan in
                PlanCard(
                    planningViewModel: planningViewModel,
                    plan: plan,
                    isSelected: selectedPlan?.id == plan.id,
                    onTap: {
                        onPlanSelected(plan)
                    },
                    onEdit: {
                        onPlanEdit(plan)
                    },
                    onDelete: {
                        onPlanDelete(plan)
                    }
                )
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct PlanCard_Previews: PreviewProvider {
    static var previews: some View {
        let mockPlan = FinancialPlan(
            name: "Emergency Fund",
            description: "Build an emergency fund for unexpected expenses",
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date(),
            totalIncome: 5000,
            totalBudget: 3500,
            savingsGoal: 10000,
            emergencyFundGoal: 15000,
            interestType: .compound,
            annualInterestRate: 0.05,
            compoundingFrequency: 12,
            currency: "USD",
            categoryAllocations: [:],
            fixedExpenses: [:],
            variableExpenseBudgets: [:],
            isActive: true,
            planType: .emergencyFund,
            status: .active,
            createdAt: Date(),
            updatedAt: Date()
        )

        VStack(spacing: 20) {
            PlanCard(
                planningViewModel: PlanningViewModel.preview,
                plan: mockPlan,
                isSelected: false,
                onTap: {},
                onEdit: {},
                onDelete: {}
            )

            PlanCard(
                planningViewModel: PlanningViewModel.preview,
                plan: mockPlan.withStatus(.paused),
                isSelected: true,
                onTap: {},
                onEdit: {},
                onDelete: {}
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

extension FinancialPlan {
    func withStatus(_ newStatus: PlanStatus) -> FinancialPlan {
        return FinancialPlan(
            id: self.id,
            name: self.name,
            description: self.description,
            startDate: self.startDate,
            endDate: self.endDate,
            totalIncome: self.totalIncome,
            totalBudget: self.totalBudget,
            savingsGoal: self.savingsGoal,
            emergencyFundGoal: self.emergencyFundGoal,
            interestType: self.interestType,
            annualInterestRate: self.annualInterestRate,
            compoundingFrequency: self.compoundingFrequency,
            currency: self.currency,
            categoryAllocations: self.categoryAllocations,
            fixedExpenses: self.fixedExpenses,
            variableExpenseBudgets: self.variableExpenseBudgets,
            isActive: self.isActive,
            planType: self.planType,
            status: newStatus,
            createdAt: self.createdAt,
            updatedAt: Date()
        )
    }
}
#endif