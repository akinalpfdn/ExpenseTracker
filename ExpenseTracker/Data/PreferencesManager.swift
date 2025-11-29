//
//  PreferencesManager.swift
//  ExpenseTracker
//
//  Created by migration from Android PreferencesManager.kt
//

import Foundation
import Combine

class PreferencesManager: ObservableObject {
    static let shared = PreferencesManager()

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

    @Published var isFirstLaunch: Bool? {
        didSet {
            if let value = isFirstLaunch {
                userDefaults.set(value, forKey: Keys.isFirstLaunch)
            }
        }
    }

    @Published var launchCount: Int {
        didSet {
            userDefaults.set(launchCount, forKey: Keys.launchCount)
        }
    }

    @Published var hasRatedApp: Bool {
        didSet {
            userDefaults.set(hasRatedApp, forKey: Keys.hasRatedApp)
        }
    }

    // MARK: - Keys

    private enum Keys {
        static let defaultCurrency = "default_currency"
        static let dailyLimit = "daily_limit"
        static let monthlyLimit = "monthly_limit"
        static let theme = "theme"
        static let isFirstLaunch = "is_first_launch"
        static let tutorialCompleted = "tutorial_completed"
        static let launchCount = "launch_count"
        static let hasRatedApp = "has_rated_app"
    }

    // MARK: - Initialization

    init() {
        self.defaultCurrency = userDefaults.string(forKey: Keys.defaultCurrency) ?? "₺"
        self.dailyLimit = userDefaults.string(forKey: Keys.dailyLimit) ?? ""
        self.monthlyLimit = userDefaults.string(forKey: Keys.monthlyLimit) ?? ""
        self.theme = userDefaults.string(forKey: Keys.theme) ?? "dark"

        self.launchCount = userDefaults.integer(forKey: Keys.launchCount)
        self.hasRatedApp = userDefaults.bool(forKey: Keys.hasRatedApp)

        // Check if first launch key exists
        if userDefaults.object(forKey: Keys.isFirstLaunch) == nil {
            self.isFirstLaunch = true
        } else {
            self.isFirstLaunch = userDefaults.bool(forKey: Keys.isFirstLaunch)
        }
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

    func completeFirstLaunch() {
        isFirstLaunch = false
    }

    // MARK: - Tutorial Methods

    func isTutorialCompleted() -> Bool {
        return userDefaults.bool(forKey: Keys.tutorialCompleted)
    }

    func setTutorialCompleted() {
        userDefaults.set(true, forKey: Keys.tutorialCompleted)
    }

    func resetTutorial() {
        userDefaults.set(false, forKey: Keys.tutorialCompleted)
    }

    // MARK: - Launch Counter Methods

    func incrementLaunchCount() {
        launchCount += 1
    }

    func shouldShowRateMeReminder() -> Bool {
        // For now, show on every launch for debugging
         return launchCount >= 10 && !hasRatedApp
        //return !hasRatedApp
    }

    func setAppRated() {
        hasRatedApp = true
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