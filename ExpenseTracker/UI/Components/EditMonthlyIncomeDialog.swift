//
//  EditMonthlyIncomeDialog.swift
//  ExpenseTracker
//
//  Sheet behind the pencil on the overview summary card.
//

import SwiftUI

struct EditMonthlyIncomeDialog: View {
    @EnvironmentObject var preferencesManager: PreferencesManager

    let isDarkTheme: Bool
    let onDismiss: () -> Void

    @State private var incomeText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            incomeField
            buttons
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ThemeColors.getBottomSheetBackgroundColor(isDarkTheme: isDarkTheme))
        .onAppear {
            incomeText = preferencesManager.monthlyNetIncome
        }
    }
}

// MARK: - Sections

private extension EditMonthlyIncomeDialog {

    var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("monthly_net_income".localized)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            Text("monthly_net_income_description".localized)
                .font(.system(size: 14))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    var incomeField: some View {
        TextField("enter_monthly_net_income".localized, text: $incomeText)
            .textFieldStyle(CustomTextFieldStyle(isDarkTheme: isDarkTheme))
            .keyboardType(.decimalPad)
            .onChange(of: incomeText) { newValue in
                // Same input rules as the daily and monthly limit fields: digits and
                // a single decimal separator.
                let filtered = newValue.filter { "0123456789.,".contains($0) }
                let components = filtered.components(separatedBy: CharacterSet(charactersIn: ".,"))

                if components.count > 2 {
                    incomeText = components[0] + "," + components[1]
                } else if filtered != newValue {
                    incomeText = filtered
                }
            }
    }

    var buttons: some View {
        HStack(spacing: 12) {
            Button(action: onDismiss) {
                Text("cancel".localized)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(ThemeColors.getButtonDisabledColor(isDarkTheme: isDarkTheme))
                    .cornerRadius(16)
            }

            Button(action: save) {
                Text("save".localized)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.textWhite)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(AppColors.primaryOrange)
                    .cornerRadius(16)
            }
        }
    }

    func save() {
        preferencesManager.setMonthlyNetIncome(incomeText)
        onDismiss()
    }
}
