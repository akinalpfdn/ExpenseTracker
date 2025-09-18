//
//  PlanDetailBottomSheet.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import SwiftUI
import Charts

struct PlanDetailBottomSheet: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var planningViewModel: PlanningViewModel

    let plan: FinancialPlan

    @State private var selectedView: PlanDetailView = .overview
    @State private var showingEditPlan = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerView
                segmentedControl
                contentView
            }
            .background(ThemeColors.backgroundColor(for: colorScheme))
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingEditPlan) {
            CreatePlanDialog(
                planningViewModel: planningViewModel,
                editingPlan: plan
            )
        }
        .confirmationDialog(
            L("delete_plan_confirmation"),
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(L("delete"), role: .destructive) {
                Task {
                    await planningViewModel.deletePlan(plan)
                    dismiss()
                }
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Button(L("close")) {
                    dismiss()
                }
                .foregroundColor(AppColors.primaryRed)

                Spacer()

                Menu {
                    Button(L("edit_plan")) {
                        showingEditPlan = true
                    }
                    Button(L("duplicate_plan")) {
                        planningViewModel.duplicatePlan(plan)
                    }
                    Divider()
                    Button(L("delete_plan"), role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(AppColors.primaryOrange)
                }
            }

            VStack(spacing: 8) {
                HStack {
                    Image(systemName: plan.planType.icon)
                        .foregroundColor(AppColors.primaryOrange)
                    Text(plan.name)
                        .font(AppTypography.titleMedium)
                        .foregroundColor(ThemeColors.textColor(for: colorScheme))
                    Spacer()
                    Text(plan.status.displayName)
                        .font(AppTypography.labelSmall)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(plan.status.color))
                }

                if !plan.description.isEmpty {
                    Text(plan.description)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .padding()
    }

    private var segmentedControl: some View {
        Picker("View", selection: $selectedView) {
            ForEach(PlanDetailView.allCases, id: \.self) { view in
                Text(view.displayName).tag(view)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
    }

    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            switch selectedView {
            case .overview:
                overviewContent
            case .progress:
                progressContent
            case .breakdown:
                breakdownContent
            case .analytics:
                analyticsContent
            }
        }
        .padding()
    }

    private var overviewContent: some View {
        VStack(spacing: 20) {
            // Key metrics
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                metricCard(L("total_income"), formatCurrency(plan.totalIncome), "plus.circle.fill", AppColors.successGreen)
                metricCard(L("monthly_budget"), formatCurrency(plan.totalBudget), "chart.pie.fill", .blue)
                metricCard(L("savings_goal"), formatCurrency(plan.savingsGoal), "target", AppColors.primaryOrange)
                metricCard(L("emergency_fund"), formatCurrency(plan.emergencyFundGoal), "shield.fill", AppColors.primaryRed)
            }

            // Date range
            VStack(alignment: .leading, spacing: 8) {
                Text(L("plan_duration"))
                    .font(AppTypography.cardTitle)
                    .foregroundColor(ThemeColors.textColor(for: colorScheme))

                HStack {
                    VStack(alignment: .leading) {
                        Text(L("start_date"))
                            .font(AppTypography.labelMedium)
                            .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                        Text(formatDate(plan.startDate))
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(ThemeColors.textColor(for: colorScheme))
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(L("end_date"))
                            .font(AppTypography.labelMedium)
                            .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                        Text(formatDate(plan.endDate))
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(ThemeColors.textColor(for: colorScheme))
                    }
                }
            }
            .padding()
            .background(ThemeColors.cardBackgroundColor(for: colorScheme))
            .cornerRadius(12)
        }
    }

    private var progressContent: some View {
        VStack(spacing: 20) {
            // Progress indicators
            VStack(spacing: 16) {
                progressItem(L("budget_usage"), 65, AppColors.primaryOrange)
                progressItem(L("savings_progress"), 45, AppColors.successGreen)
                progressItem(L("time_progress"), 30, .blue)
            }
            .padding()
            .background(ThemeColors.cardBackgroundColor(for: colorScheme))
            .cornerRadius(12)

            // Monthly breakdown chart would go here
            Text(L("monthly_progress_chart"))
                .font(AppTypography.cardTitle)
                .foregroundColor(ThemeColors.textColor(for: colorScheme))
                .frame(height: 200)
                .background(ThemeColors.cardBackgroundColor(for: colorScheme))
                .cornerRadius(12)
        }
    }

    private var breakdownContent: some View {
        VStack(spacing: 20) {
            // Category allocations
            VStack(alignment: .leading, spacing: 12) {
                Text(L("category_allocations"))
                    .font(AppTypography.cardTitle)
                    .foregroundColor(ThemeColors.textColor(for: colorScheme))

                ForEach(plan.categoryAllocations.sorted(by: { $0.value > $1.value }), id: \.key) { category, percentage in
                    HStack {
                        Text(category)
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(ThemeColors.textColor(for: colorScheme))
                        Spacer()
                        Text("\(String(format: "%.1f", percentage))%")
                            .font(AppTypography.labelMedium)
                            .foregroundColor(AppColors.primaryOrange)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(ThemeColors.cardBackgroundColor(for: colorScheme))
            .cornerRadius(12)
        }
    }

    private var analyticsContent: some View {
        VStack(spacing: 20) {
            Text(L("analytics_coming_soon"))
                .font(AppTypography.bodyLarge)
                .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                .frame(height: 200)
        }
    }

    private func metricCard(_ title: String, _ value: String, _ icon: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            Text(title)
                .font(AppTypography.labelMedium)
                .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
            Text(value)
                .font(AppTypography.bodyLarge)
                .foregroundColor(ThemeColors.textColor(for: colorScheme))
        }
        .padding()
        .background(ThemeColors.cardBackgroundColor(for: colorScheme))
        .cornerRadius(8)
    }

    private func progressItem(_ title: String, _ percentage: Double, _ color: Color) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(ThemeColors.textColor(for: colorScheme))
                Spacer()
                Text("\(String(format: "%.0f", percentage))%")
                    .font(AppTypography.labelMedium)
                    .foregroundColor(color)
            }
            ProgressView(value: percentage / 100)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = plan.currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("MMM d, yyyy")
        return formatter.string(from: date)
    }
}

enum PlanDetailView: String, CaseIterable {
    case overview = "overview"
    case progress = "progress"
    case breakdown = "breakdown"
    case analytics = "analytics"

    var displayName: String {
        switch self {
        case .overview: return L("overview")
        case .progress: return L("progress")
        case .breakdown: return L("breakdown")
        case .analytics: return L("analytics")
        }
    }
}

#if DEBUG
struct PlanDetailBottomSheet_Previews: PreviewProvider {
    static var previews: some View {
        let mockPlan = FinancialPlan(
            name: "Emergency Fund",
            description: "Build emergency savings",
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
            categoryAllocations: ["housing": 30, "food": 20, "transport": 15],
            fixedExpenses: [:],
            variableExpenseBudgets: [:],
            isActive: true,
            planType: .emergencyFund,
            status: .active,
            createdAt: Date(),
            updatedAt: Date()
        )

        PlanDetailBottomSheet(
            planningViewModel: PlanningViewModel.preview,
            plan: mockPlan
        )
    }
}
#endif