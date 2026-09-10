//
//  WelcomeScreen.swift
//  ExpenseTracker
//
//  First run. Two pages explaining what the app is, then three that set it up.
//
//  The setup pages are the point. Without a currency, an income and a limit, the
//  overview shows zeros and the progress ring measures against nothing — so the app
//  looks broken until the user goes hunting in Settings for things it could simply
//  have asked. Every one of them is skippable and all are editable later.
//

import SwiftUI

struct WelcomeScreen: View {
    @EnvironmentObject var preferencesManager: PreferencesManager

    let onComplete: () -> Void

    @State private var pageIndex = 0

    // Collected as the user goes; written only when they finish.
    @State private var currency = "₺"
    @State private var monthlyIncome = ""
    @State private var dailyLimit = ""
    @State private var monthlyLimit = ""
    @State private var showingCurrencyPicker = false

    private var isDarkTheme: Bool { preferencesManager.theme == "dark" }
    private let pages = WelcomePage.allCases

    var body: some View {
        VStack(spacing: 0) {
            skipRow
            pager
            indicators
            primaryButton
        }
        .background(ThemeColors.getBackgroundColor(isDarkTheme: isDarkTheme))
        .onAppear { currency = preferencesManager.defaultCurrency }
        .sheet(isPresented: $showingCurrencyPicker) {
            CurrencyPickerSheet(selection: $currency, isDarkTheme: isDarkTheme)
        }
    }
}

// MARK: - Chrome

private extension WelcomeScreen {

    var skipRow: some View {
        HStack {
            Spacer()

            if pageIndex < pages.count - 1 {
                Button("welcome_skip".localized) { complete() }
                    .font(.system(size: 15))
                    .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                    .padding(20)
            }
        }
        .frame(height: 60)
    }

    var pager: some View {
        TabView(selection: $pageIndex) {
            ForEach(Array(pages.enumerated()), id: \.element) { index, page in
                content(for: page)
                    .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
    }

    var indicators: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        pageIndex == index
                            ? AppColors.primaryOrange
                            : ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme).opacity(0.4)
                    )
                    .frame(width: pageIndex == index ? 32 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.25), value: pageIndex)
            }
        }
        .padding(.vertical, 20)
    }

    var primaryButton: some View {
        Button(action: advance) {
            Text(pageIndex == pages.count - 1 ? "welcome_start".localized : "welcome_next".localized)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(AppColors.textWhite)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(AppColors.primaryOrange)
                .cornerRadius(16)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }

    func advance() {
        if pageIndex == pages.count - 1 {
            complete()
        } else {
            withAnimation { pageIndex += 1 }
        }
    }

    /// Writes whatever was filled in. Blank fields are left alone rather than written
    /// as empty, so skipping does not overwrite something already set.
    func complete() {
        preferencesManager.setDefaultCurrency(currency)

        if !monthlyIncome.isEmpty { preferencesManager.setMonthlyNetIncome(monthlyIncome) }
        if !dailyLimit.isEmpty { preferencesManager.setDailyLimit(dailyLimit) }
        if !monthlyLimit.isEmpty { preferencesManager.setMonthlyLimit(monthlyLimit) }

        onComplete()
    }
}

// MARK: - Pages

enum WelcomePage: CaseIterable, Hashable {
    case whatItIs
    case privacy
    case currency
    case income
    case limits
}

private extension WelcomeScreen {

    @ViewBuilder
    func content(for page: WelcomePage) -> some View {
        switch page {
        case .whatItIs:
            informational(
                icon: "creditcard",
                title: "welcome_page1_title".localized,
                description: "welcome_page1_description".localized
            )

        case .privacy:
            informational(
                icon: "lock.shield",
                title: "welcome_page3_title".localized,
                description: "welcome_page3_description".localized
            )

        case .currency:
            setup(
                icon: "turkishlirasign.circle",
                title: "welcome_currency_title".localized,
                description: "welcome_currency_description".localized
            ) {
                currencyPicker
            }

        case .income:
            setup(
                icon: "arrow.down.circle",
                title: "welcome_income_title".localized,
                description: "welcome_income_description".localized
            ) {
                amountField(placeholder: "enter_monthly_net_income".localized, text: $monthlyIncome)
            }

        case .limits:
            setup(
                icon: "gauge.with.needle",
                title: "welcome_limits_title".localized,
                description: "welcome_limits_description".localized
            ) {
                VStack(spacing: 16) {
                    labelledField("daily_spending_limit".localized,
                                  placeholder: "enter_daily_limit".localized,
                                  text: $dailyLimit)

                    labelledField("monthly_spending_limit".localized,
                                  placeholder: "enter_monthly_limit".localized,
                                  text: $monthlyLimit)
                }
            }
        }
    }

    func informational(icon: String, title: String, description: String) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 72, weight: .light))
                .foregroundColor(AppColors.primaryOrange)

            Text(title)
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            Text(description)
                .font(.system(size: 16))
                .lineSpacing(5)
                .multilineTextAlignment(.center)
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    /// Same shape as an informational page so the flow does not feel like it changes
    /// gear when it starts asking for things — with the input, and a reminder that
    /// nothing here is final.
    func setup<Content: View>(
        icon: String,
        title: String,
        description: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 52, weight: .light))
                .foregroundColor(AppColors.primaryOrange)

            Text(title)
                .font(.system(size: 24, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            Text(description)
                .font(.system(size: 15))
                .lineSpacing(4)
                .multilineTextAlignment(.center)
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))

            content()
                .padding(.top, 8)

            Text("welcome_changeable_later".localized)
                .font(.system(size: 12))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme).opacity(0.8))

            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Inputs

private extension WelcomeScreen {

    /// Four buttons in a row fit four currencies; with forty, the row opens a picker.
    var currencyPicker: some View {
        Button(action: { showingCurrencyPicker = true }) {
            HStack(spacing: 14) {
                Text(currency)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(AppColors.primaryOrange)
                    .frame(minWidth: 44, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text(Currency.from(symbol: currency).name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                    Text(Currency.from(symbol: currency).code)
                        .font(.system(size: 12))
                        .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
            }
            .padding(16)
            .background(ThemeColors.getInputBackgroundColor(isDarkTheme: isDarkTheme))
            .cornerRadius(16)
        }
    }

    func amountField(placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .textFieldStyle(CustomTextFieldStyle(isDarkTheme: isDarkTheme))
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.center)
            .onChange(of: text.wrappedValue) { newValue in
                let filtered = newValue.filter { "0123456789.,".contains($0) }
                if filtered != newValue { text.wrappedValue = filtered }
            }
    }

    func labelledField(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))

            amountField(placeholder: placeholder, text: text)
        }
    }
}
