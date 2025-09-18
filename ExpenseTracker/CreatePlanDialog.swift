//
//  CreatePlanDialog.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import SwiftUI

struct CreatePlanDialog: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var planningViewModel: PlanningViewModel

    let editingPlan: FinancialPlan?

    @State private var currentStep: PlanCreationStep = .basicInfo
    @State private var formData = PlanFormData()
    @State private var formErrors: [String: String] = [:]
    @State private var isLoading = false

    private var isEditing: Bool {
        editingPlan != nil
    }

    private var isLastStep: Bool {
        currentStep == .review
    }

    private var canProceed: Bool {
        validateCurrentStep()
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerView
                progressIndicator
                stepContent
                actionButtons
            }
            .background(ThemeColors.backgroundColor(for: colorScheme))
            .navigationBarHidden(true)
            .onAppear {
                if let plan = editingPlan {
                    formData.populateFrom(plan)
                }
            }
        }
    }

    private var headerView: some View {
        HStack {
            Button(L("cancel")) {
                dismiss()
            }
            .foregroundColor(AppColors.primaryRed)

            Spacer()

            Text(isEditing ? L("edit_plan") : L("create_plan"))
                .font(AppTypography.navigationTitle)
                .foregroundColor(ThemeColors.textColor(for: colorScheme))

            Spacer()

            if isLastStep {
                Button(isEditing ? L("save") : L("create")) {
                    Task {
                        await savePlan()
                    }
                }
                .foregroundColor(canProceed ? AppColors.primaryOrange : ThemeColors.textGrayColor(for: colorScheme))
                .disabled(!canProceed || isLoading)
            } else {
                Button(L("next")) {
                    nextStep()
                }
                .foregroundColor(canProceed ? AppColors.primaryOrange : ThemeColors.textGrayColor(for: colorScheme))
                .disabled(!canProceed)
            }
        }
        .padding()
    }

    private var progressIndicator: some View {
        HStack {
            ForEach(PlanCreationStep.allCases, id: \.self) { step in
                Circle()
                    .fill(stepColor(step))
                    .frame(width: 8, height: 8)

                if step != PlanCreationStep.allCases.last {
                    Rectangle()
                        .fill(stepConnectorColor(step))
                        .frame(height: 2)
                }
            }
        }
        .padding()
    }

    @ViewBuilder
    private var stepContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                stepHeaderView

                switch currentStep {
                case .basicInfo:
                    basicInfoStep
                case .budgetAllocation:
                    budgetAllocationStep
                case .goalSetting:
                    goalSettingStep
                case .review:
                    reviewStep
                }
            }
            .padding()
        }
    }

    private var stepHeaderView: some View {
        VStack(spacing: 8) {
            Text(currentStep.title)
                .font(AppTypography.titleMedium)
                .foregroundColor(ThemeColors.textColor(for: colorScheme))

            Text(currentStep.subtitle)
                .font(AppTypography.bodyMedium)
                .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                .multilineTextAlignment(.center)
        }
    }

    private var basicInfoStep: some View {
        VStack(spacing: 16) {
            // Plan name
            FormField(
                title: L("plan_name"),
                text: $formData.name,
                placeholder: L("enter_plan_name"),
                error: formErrors["name"]
            )

            // Plan description
            FormField(
                title: L("description"),
                text: $formData.description,
                placeholder: L("enter_description"),
                isMultiline: true
            )

            // Plan type
            VStack(alignment: .leading, spacing: 8) {
                Text(L("plan_type"))
                    .font(AppTypography.fieldLabel)
                    .foregroundColor(ThemeColors.textColor(for: colorScheme))

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(PlanType.allCases, id: \.self) { type in
                        PlanTypeCard(
                            type: type,
                            isSelected: formData.planType == type,
                            colorScheme: colorScheme
                        ) {
                            formData.planType = type
                        }
                    }
                }
            }

            // Date range
            HStack {
                DatePicker(L("start_date"), selection: $formData.startDate, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())

                DatePicker(L("end_date"), selection: $formData.endDate, in: formData.startDate..., displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
            }
        }
    }

    private var budgetAllocationStep: some View {
        VStack(spacing: 16) {
            // Total income
            FormField(
                title: L("monthly_income"),
                value: $formData.totalIncome,
                placeholder: "0",
                error: formErrors["income"]
            )

            // Budget percentage
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(L("budget_percentage"))
                        .font(AppTypography.fieldLabel)
                        .foregroundColor(ThemeColors.textColor(for: colorScheme))

                    Spacer()

                    Text("\(Int(formData.budgetPercentage))%")
                        .font(AppTypography.labelMedium)
                        .foregroundColor(AppColors.primaryOrange)
                }

                Slider(value: $formData.budgetPercentage, in: 50...95, step: 5)
                    .accentColor(AppColors.primaryOrange)

                Text(L("budget_amount_will_be", formatCurrency(formData.totalIncome * formData.budgetPercentage / 100)))
                    .font(AppTypography.labelSmall)
                    .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
            }

            // Category allocations
            VStack(alignment: .leading, spacing: 12) {
                Text(L("category_allocations"))
                    .font(AppTypography.fieldLabel)
                    .foregroundColor(ThemeColors.textColor(for: colorScheme))

                ForEach(Array(formData.categoryAllocations.keys.sorted()), id: \.self) { category in
                    CategoryAllocationRow(
                        category: category,
                        percentage: Binding(
                            get: { formData.categoryAllocations[category] ?? 0 },
                            set: { formData.categoryAllocations[category] = $0 }
                        ),
                        colorScheme: colorScheme
                    )
                }

                Button(L("add_category")) {
                    // Add new category allocation
                }
                .foregroundColor(AppColors.primaryOrange)
            }
        }
    }

    private var goalSettingStep: some View {
        VStack(spacing: 16) {
            // Savings goal
            FormField(
                title: L("savings_goal"),
                value: $formData.savingsGoal,
                placeholder: "0",
                error: formErrors["savingsGoal"]
            )

            // Emergency fund
            FormField(
                title: L("emergency_fund_goal"),
                value: $formData.emergencyFundGoal,
                placeholder: "0"
            )

            // Interest settings
            VStack(alignment: .leading, spacing: 12) {
                Text(L("interest_settings"))
                    .font(AppTypography.fieldLabel)
                    .foregroundColor(ThemeColors.textColor(for: colorScheme))

                Picker(L("interest_type"), selection: $formData.interestType) {
                    ForEach(InterestType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())

                FormField(
                    title: L("annual_rate_percentage"),
                    value: $formData.annualInterestRate,
                    placeholder: "5.0",
                    isPercentage: true
                )
            }
        }
    }

    private var reviewStep: some View {
        VStack(spacing: 20) {
            // Summary cards
            VStack(spacing: 12) {
                reviewCard(L("basic_info"), [
                    (L("name"), formData.name),
                    (L("type"), formData.planType.displayName),
                    (L("duration"), formatDateRange())
                ])

                reviewCard(L("budget"), [
                    (L("monthly_income"), formatCurrency(formData.totalIncome)),
                    (L("monthly_budget"), formatCurrency(formData.totalIncome * formData.budgetPercentage / 100)),
                    (L("savings_rate"), "\(Int(100 - formData.budgetPercentage))%")
                ])

                reviewCard(L("goals"), [
                    (L("savings_goal"), formatCurrency(formData.savingsGoal)),
                    (L("emergency_fund"), formatCurrency(formData.emergencyFundGoal)),
                    (L("interest_rate"), "\(String(format: "%.1f", formData.annualInterestRate))%")
                ])
            }

            if !formErrors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(AppColors.primaryRed)
                        Text(L("please_fix_errors"))
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.primaryRed)
                    }

                    ForEach(Array(formErrors.values), id: \.self) { error in
                        Text("• \(error)")
                            .font(AppTypography.labelMedium)
                            .foregroundColor(AppColors.primaryRed)
                    }
                }
                .padding()
                .background(AppColors.primaryRed.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }

    private var actionButtons: some View {
        HStack {
            if currentStep != .basicInfo {
                Button(L("back")) {
                    previousStep()
                }
                .font(AppTypography.buttonText)
                .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
            }

            Spacer()

            if !isLastStep {
                Button(L("next")) {
                    nextStep()
                }
                .font(AppTypography.buttonText)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(canProceed ? AppColors.primaryGradient : Color.gray)
                )
                .disabled(!canProceed)
            }
        }
        .padding()
    }

    // MARK: - Helper Methods

    private func nextStep() {
        guard validateCurrentStep() else { return }

        switch currentStep {
        case .basicInfo:
            currentStep = .budgetAllocation
        case .budgetAllocation:
            currentStep = .goalSetting
        case .goalSetting:
            currentStep = .review
        case .review:
            break
        }
    }

    private func previousStep() {
        switch currentStep {
        case .basicInfo:
            break
        case .budgetAllocation:
            currentStep = .basicInfo
        case .goalSetting:
            currentStep = .budgetAllocation
        case .review:
            currentStep = .goalSetting
        }
    }

    private func validateCurrentStep() -> Bool {
        formErrors.removeAll()

        switch currentStep {
        case .basicInfo:
            if formData.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                formErrors["name"] = L("error_missing_plan_name")
            }
            if formData.startDate >= formData.endDate {
                formErrors["dateRange"] = L("error_invalid_date_range")
            }

        case .budgetAllocation:
            if formData.totalIncome <= 0 {
                formErrors["income"] = L("error_invalid_income")
            }

        case .goalSetting:
            if formData.savingsGoal < 0 {
                formErrors["savingsGoal"] = L("error_invalid_savings_goal")
            }

        case .review:
            // Final validation
            return validateCurrentStep()
        }

        return formErrors.isEmpty
    }

    private func savePlan() async {
        isLoading = true
        defer { isLoading = false }

        guard validateCurrentStep() else { return }

        if isEditing {
            planningViewModel.editPlanForm.populateFrom(formData)
            await planningViewModel.updatePlan()
        } else {
            planningViewModel.newPlanForm.populateFrom(formData)
            await planningViewModel.createPlan()
        }

        dismiss()
    }

    private func stepColor(_ step: PlanCreationStep) -> Color {
        if step.stepNumber <= currentStep.stepNumber {
            return AppColors.primaryOrange
        } else {
            return ThemeColors.textGrayColor(for: colorScheme).opacity(0.3)
        }
    }

    private func stepConnectorColor(_ step: PlanCreationStep) -> Color {
        if step.stepNumber < currentStep.stepNumber {
            return AppColors.primaryOrange
        } else {
            return ThemeColors.textGrayColor(for: colorScheme).opacity(0.3)
        }
    }

    private func reviewCard(_ title: String, _ items: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(AppTypography.cardTitle)
                .foregroundColor(ThemeColors.textColor(for: colorScheme))

            ForEach(items, id: \.0) { key, value in
                HStack {
                    Text(key)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                    Spacer()
                    Text(value)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(ThemeColors.textColor(for: colorScheme))
                }
            }
        }
        .padding()
        .background(ThemeColors.cardBackgroundColor(for: colorScheme))
        .cornerRadius(12)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = formData.currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"
    }

    private func formatDateRange() -> String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM yyyy")
        return "\(formatter.string(from: formData.startDate)) - \(formatter.string(from: formData.endDate))"
    }
}

// MARK: - Supporting Types and Views

class PlanFormData: ObservableObject {
    @Published var name = ""
    @Published var description = ""
    @Published var planType: PlanType = .general
    @Published var startDate = Date()
    @Published var endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @Published var totalIncome: Double = 0
    @Published var budgetPercentage: Double = 80
    @Published var savingsGoal: Double = 0
    @Published var emergencyFundGoal: Double = 0
    @Published var interestType: InterestType = .compound
    @Published var annualInterestRate: Double = 5.0
    @Published var currency = "USD"
    @Published var categoryAllocations: [String: Double] = [
        "housing": 30,
        "food": 20,
        "transport": 15,
        "entertainment": 10,
        "other": 25
    ]

    func populateFrom(_ plan: FinancialPlan) {
        name = plan.name
        description = plan.description
        planType = plan.planType
        startDate = plan.startDate
        endDate = plan.endDate
        totalIncome = plan.totalIncome
        savingsGoal = plan.savingsGoal
        emergencyFundGoal = plan.emergencyFundGoal
        interestType = plan.interestType
        annualInterestRate = plan.annualInterestRate * 100
        currency = plan.currency
        categoryAllocations = plan.categoryAllocations
    }
}

extension PlanFormState {
    func populateFrom(_ formData: PlanFormData) {
        name = formData.name
        description = formData.description
        planType = formData.planType
        startDate = formData.startDate
        endDate = formData.endDate
        totalIncome = formData.totalIncome
        totalBudget = formData.totalIncome * formData.budgetPercentage / 100
        savingsGoal = formData.savingsGoal
        emergencyFundGoal = formData.emergencyFundGoal
        interestType = formData.interestType
        annualInterestRate = formData.annualInterestRate / 100
        currency = formData.currency
        categoryAllocations = formData.categoryAllocations
    }
}

// Additional form components would be defined here (FormField, PlanTypeCard, CategoryAllocationRow)

#if DEBUG
struct CreatePlanDialog_Previews: PreviewProvider {
    static var previews: some View {
        CreatePlanDialog(
            planningViewModel: PlanningViewModel.preview,
            editingPlan: nil
        )
    }
}
#endif