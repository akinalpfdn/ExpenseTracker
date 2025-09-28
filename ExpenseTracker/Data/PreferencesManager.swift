//
//  PreferencesManager.swift
//  ExpenseTracker
//
//  Created by migration from Android PreferencesManager.kt
//

import Foundation
import Combine

class PreferencesManager: ObservableObject {
    private let userDefaults = UserDefaults.standard

    // MARK: - Published Properties

    @Published var defaultCurrency: String {
        didSet {
            userDefaults.set(defaultCurrency, forKey: Keys.defaultCurrency)
        }
    }

    @Published var dailyLimit: String {
        didSet {
            userDefaults.set(dailyLimit, forKey: Keys.dailyLimit)
        }
    }

    @Published var monthlyLimit: String {
        didSet {
            userDefaults.set(monthlyLimit, forKey: Keys.monthlyLimit)
        }
    }

    @Published var theme: String {
        didSet {
            userDefaults.set(theme, forKey: Keys.theme)
        }
    }

    // MARK: - Keys

    private enum Keys {
        static let defaultCurrency = "default_currency"
        static let dailyLimit = "daily_limit"
        static let monthlyLimit = "monthly_limit"
        static let theme = "theme"
    }

    // MARK: - Initialization

    init() {
        self.defaultCurrency = userDefaults.string(forKey: Keys.defaultCurrency) ?? "₺"
        self.dailyLimit = userDefaults.string(forKey: Keys.dailyLimit) ?? ""
        self.monthlyLimit = userDefaults.string(forKey: Keys.monthlyLimit) ?? ""
        self.theme = userDefaults.string(forKey: Keys.theme) ?? "dark"
    }

    // MARK: - Methods

    func setDefaultCurrency(_ currency: String) {
        defaultCurrency = currency
    }

    func setDailyLimit(_ limit: String) {
        dailyLimit = limit
    }

    func setMonthlyLimit(_ limit: String) {
        monthlyLimit = limit
    }

    func setTheme(_ newTheme: String) {
        theme = newTheme
    }

    // MARK: - Computed Properties

    var dailyLimitDouble: Double {
        return Double(dailyLimit) ?? 0.0
    }

    var monthlyLimitDouble: Double {
        return Double(monthlyLimit) ?? 0.0
    }

    var isDarkTheme: Bool {
        return theme == "dark"
    }
}