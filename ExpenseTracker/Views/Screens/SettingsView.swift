//
//  SettingsView.swift
//  ExpenseTracker
//
//  Created by migration from Android SettingsScreen.kt
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: ExpenseViewModel
    @EnvironmentObject var preferencesManager: PreferencesManager

    let onDismiss: () -> Void

    @State private var selectedTabIndex = 0
    @State private var newDefaultCurrency: String
    @State private var newDailyLimit: String
    @State private var newMonthlyLimit: String
    @State private var newTheme: String
    @State private var showCurrencyMenu = false

    private let tabs = ["general_settings".localized, "categories".localized]
    private let currencies = ["₺", "$", "€", "£"]

    private var isDarkTheme: Bool {
        newTheme == "dark"
    }

    init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss

        // Initialize state with current preferences
        self._newDefaultCurrency = State(initialValue: "")
        self._newDailyLimit = State(initialValue: "")
        self._newMonthlyLimit = State(initialValue: "")
        self._newTheme = State(initialValue: "dark")
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab Row
            customTabRow

            Spacer().frame(height: 16)

            // Tab Content
            if selectedTabIndex == 0 {
                generalSettingsTab
            } else {
                categoriesTab
            }
        }
        .background(ThemeColors.getBackgroundColor(isDarkTheme: isDarkTheme))
        .onAppear {
            initializeWithCurrentSettings()
        }
    }
}

// MARK: - View Components
extension SettingsView {
    private var customTabRow: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, title in
                Button(action: { selectedTabIndex = index }) {
                    VStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 22, weight: selectedTabIndex == index ? .semibold : .regular))
                            .foregroundColor(
                                selectedTabIndex == index ?
                                AppColors.primaryOrange :
                                ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme)
                            )
                            .padding(.vertical, 8)

                        // Tab indicator
                        Rectangle()
                            .fill(selectedTabIndex == index ? AppColors.primaryOrange : Color.clear)
                            .frame(height: 3)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
    }

    private var generalSettingsTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                currencySection
                dailyLimitSection
                monthlyLimitSection
                themeSection

                Spacer().frame(height: 20)

                buttonsSection
            }
            .padding(.horizontal, 20)
        }
    }

    private var categoriesTab: some View {
        CategoryManagementView(isDarkTheme: isDarkTheme)
            .environmentObject(viewModel)
    }

    private var currencySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("default_currency".localized)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            Menu {
                ForEach(currencies, id: \.self) { currency in
                    Button(currency) {
                        newDefaultCurrency = currency
                    }
                }
            } label: {
                HStack {
                    Text(newDefaultCurrency)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                }
                .padding(12)
                .background(ThemeColors.getInputBackgroundColor(isDarkTheme: isDarkTheme))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme), lineWidth: 1)
                )
            }

            Text("currency_description".localized)
                .font(.system(size: 14))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
        }
    }

    private var dailyLimitSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("daily_spending_limit".localized)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            TextField("enter_daily_limit".localized, text: $newDailyLimit)
                .textFieldStyle(CustomTextFieldStyle(isDarkTheme: isDarkTheme))
                .keyboardType(.decimalPad)
                .onChange(of: newDailyLimit) { newValue in
                    // Only allow digits and decimal points
                    let filtered = newValue.filter { $0.isWholeNumber || $0 == "." }
                    if filtered != newValue {
                        newDailyLimit = filtered
                    }
                }

            Text("daily_limit_description".localized)
                .font(.system(size: 14))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
        }
    }

    private var monthlyLimitSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("monthly_spending_limit".localized)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            TextField("enter_monthly_limit".localized, text: $newMonthlyLimit)
                .textFieldStyle(CustomTextFieldStyle(isDarkTheme: isDarkTheme))
                .keyboardType(.decimalPad)
                .onChange(of: newMonthlyLimit) { newValue in
                    // Only allow digits and decimal points
                    let filtered = newValue.filter { $0.isWholeNumber || $0 == "." }
                    if filtered != newValue {
                        newMonthlyLimit = filtered
                    }
                }

            Text("monthly_limit_description".localized)
                .font(.system(size: 14))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
        }
    }

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("theme".localized)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            HStack {
                Text(newTheme == "dark" ? "dark_theme".localized : "light_theme".localized)
                    .font(.system(size: 16))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

                Spacer()

                Toggle("", isOn: Binding(
                    get: { newTheme == "light" },
                    set: { isLight in
                        newTheme = isLight ? "light" : "dark"
                    }
                ))
                .toggleStyle(CustomToggleStyle(isDarkTheme: isDarkTheme))
            }

            Text("theme_description".localized)
                .font(.system(size: 14))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
        }
    }

    private var buttonsSection: some View {
        HStack(spacing: 12) {
            Button("cancel".localized) {
                onDismiss()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
            .background(ThemeColors.getButtonDisabledColor(isDarkTheme: isDarkTheme))
            .cornerRadius(16)

            Button("save".localized) {
                saveSettings()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
            .background(AppColors.primaryOrange)
            .cornerRadius(16)
        }
    }
}

// MARK: - Helper Methods
extension SettingsView {
    private func initializeWithCurrentSettings() {
        newDefaultCurrency = preferencesManager.defaultCurrency
        newDailyLimit = preferencesManager.dailyLimit
        newMonthlyLimit = preferencesManager.monthlyLimit
        newTheme = preferencesManager.theme
    }

    private func saveSettings() {
        preferencesManager.setDefaultCurrency(newDefaultCurrency)
        preferencesManager.setDailyLimit(newDailyLimit)
        preferencesManager.setMonthlyLimit(newMonthlyLimit)
        preferencesManager.setTheme(newTheme)
        onDismiss()
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let preferencesManager = PreferencesManager()
        let viewModel = ExpenseViewModel()

        SettingsView(onDismiss: { })
            .environmentObject(preferencesManager)
            .environmentObject(viewModel)
    }
}