//
//  CreatePlanDialog.swift
//  ExpenseTracker
//
//  Created by migration from Android CreatePlanDialog.kt
//

import SwiftUI

struct CreatePlanDialog: View {
    let onDismiss: () -> Void
    let onCreatePlan: (String, Int, Double, Double, Bool, Bool, Double, Bool, Double, InterestType) -> Void
    let isDarkTheme: Bool
    let defaultCurrency: String

    @State private var planName = ""
    @State private var monthlyIncome = ""
    @State private var monthlyExpenses = ""
    @State private var selectedDuration = 12
    @State private var useAppExpenseData = true
    @State private var isInflationApplied = false
    @State private var inflationRate = ""
    @State private var isInterestApplied = false
    @State private var interestRate = ""
    @State private var selectedInterestType: InterestType = .compound

    init(
        onDismiss: @escaping () -> Void = { },
        onCreatePlan: @escaping (String, Int, Double, Double, Bool, Bool, Double, Bool, Double, InterestType) -> Void = { _, _, _, _, _, _, _, _, _, _ in },
        isDarkTheme: Bool = true,
        defaultCurrency: String = "₺"
    ) {
        self.onDismiss = onDismiss
        self.onCreatePlan = onCreatePlan
        self.isDarkTheme = isDarkTheme
        self.defaultCurrency = defaultCurrency
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                planNameSection
                durationSection
                interestSection
                monthlyIncomeSection
                expenseDataSection
                inflationSection
                actionButtons
            }
            .padding(24)
        }
    }
}

// MARK: - Computed Properties
extension CreatePlanDialog {
    private var suggestedDurations: [PlanDurationOption] {
        PlanningUtils.getSuggestedPlanDurations()
    }

    private var isFormValid: Bool {
        !planName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !monthlyIncome.isEmpty
    }
}

// MARK: - View Components
extension CreatePlanDialog {
    private var headerSection: some View {
        Text("create_new_plan".localized)
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
            .multilineTextAlignment(.center)
    }

    private var planNameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("plan_name".localized)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            TextField("plan_name_example".localized, text: $planName)
                .textFieldStyle(CustomTextFieldStyle(isDarkTheme: isDarkTheme))
        }
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("plan_duration".localized)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(suggestedDurations, id: \.months) { option in
                        FilterChip(
                            text: option.displayText,
                            isSelected: selectedDuration == option.months,
                            isDarkTheme: isDarkTheme
                        ) {
                            selectedDuration = option.months
                        }
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }

    private var interestSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("apply_interest_to_savings".localized)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

                Spacer()

                Toggle("", isOn: $isInterestApplied)
                    .toggleStyle(CustomToggleStyle(isDarkTheme: isDarkTheme))
            }

            if isInterestApplied {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        FilterChip(
                            text: "simple_interest".localized,
                            isSelected: selectedInterestType == .simple,
                            isDarkTheme: isDarkTheme
                        ) {
                            selectedInterestType = .simple
                        }

                        FilterChip(
                            text: "compound_interest".localized,
                            isSelected: selectedInterestType == .compound,
                            isDarkTheme: isDarkTheme
                        ) {
                            selectedInterestType = .compound
                        }

                        Spacer()
                    }

                    TextField("annual_interest_rate".localized, text: $interestRate)
                        .textFieldStyle(CustomTextFieldStyle(isDarkTheme: isDarkTheme))
                        .keyboardType(.decimalPad)

                    Text("interest_applied_to_positive_savings".localized)
                        .font(.system(size: 12))
                        .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("interest_type".localized)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var monthlyIncomeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("monthly_income_currency".localized.replacingOccurrences(of: "%s", with: defaultCurrency))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            TextField("0", text: $monthlyIncome)
                .textFieldStyle(CustomTextFieldStyle(isDarkTheme: isDarkTheme))
                .keyboardType(.decimalPad)
        }
    }

    private var expenseDataSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: useAppExpenseData ? "checkmark.square.fill" : "square")
                    .foregroundColor(useAppExpenseData ? AppColors.primaryOrange : ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                    .onTapGesture {
                        useAppExpenseData.toggle()
                    }

                Text("use_app_expense_data".localized)
                    .font(.system(size: 14))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

                Spacer()
            }

            if !useAppExpenseData {
                VStack(alignment: .leading, spacing: 8) {
                    Text("monthly_expenses_currency".localized.replacingOccurrences(of: "%s", with: defaultCurrency))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

                    TextField("manual_monthly_expense_amount".localized, text: $monthlyExpenses)
                        .textFieldStyle(CustomTextFieldStyle(isDarkTheme: isDarkTheme))
                        .keyboardType(.decimalPad)

                    Text("enter_manual_expense_amount".localized)
                        .font(.system(size: 12))
                        .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                }
            }
        }
    }

    private var inflationSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("apply_inflation".localized)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

                Spacer()

                Toggle("", isOn: $isInflationApplied)
                    .toggleStyle(CustomToggleStyle(isDarkTheme: isDarkTheme))
            }

            if isInflationApplied {
                TextField("annual_percentage_rate".localized, text: $inflationRate)
                    .textFieldStyle(CustomTextFieldStyle(isDarkTheme: isDarkTheme))
                    .keyboardType(.decimalPad)
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: onDismiss) {
                Text("cancel".localized)
                    .font(.system(size: 16))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme).opacity(0.5), lineWidth: 1)
                    )
            }

            Button(action: createPlan) {
                Text("create".localized)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(AppColors.primaryOrange)
                    .cornerRadius(8)
            }
            .disabled(!isFormValid)
        }
    }
}

// MARK: - Helper Methods
extension CreatePlanDialog {
    private func createPlan() {
        let income = Double(monthlyIncome) ?? 0.0
        let expenses = Double(monthlyExpenses) ?? 0.0
        let inflation = isInflationApplied ? (Double(inflationRate) ?? 0.0) : 0.0
        let interest = isInterestApplied ? (Double(interestRate) ?? 0.0) : 0.0

        onCreatePlan(
            planName.trimmingCharacters(in: .whitespacesAndNewlines),
            selectedDuration,
            income,
            expenses,
            useAppExpenseData,
            isInflationApplied,
            inflation,
            isInterestApplied,
            interest,
            selectedInterestType
        )
    }
}

// MARK: - Custom Components
struct FilterChip: View {
    let text: String
    let isSelected: Bool
    let isDarkTheme: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(isSelected ? AppColors.primaryOrange : ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    isSelected ?
                    AppColors.primaryOrange.opacity(0.2) :
                    ThemeColors.getInputBackgroundColor(isDarkTheme: isDarkTheme)
                )
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected ? AppColors.primaryOrange : ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme).opacity(0.3),
                            lineWidth: 1
                        )
                )
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    let isDarkTheme: Bool

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(16)
            .background(ThemeColors.getInputBackgroundColor(isDarkTheme: isDarkTheme))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme).opacity(0.3), lineWidth: 1)
            )
    }
}

struct CustomToggleStyle: ToggleStyle {
    let isDarkTheme: Bool

    func makeBody(configuration: Configuration) -> some View {
        Button(action: { configuration.isOn.toggle() }) {
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? AppColors.primaryOrange : ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme).opacity(0.3))
                .frame(width: 50, height: 30)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 26, height: 26)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                )
        }
    }
}

// MARK: - Preview
struct CreatePlanDialog_Previews: PreviewProvider {
    static var previews: some View {
        CreatePlanDialog(
            isDarkTheme: true,
            defaultCurrency: "₺"
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}