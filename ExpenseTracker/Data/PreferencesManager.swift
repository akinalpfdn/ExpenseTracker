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

    /// Take-home pay per month, used by the overview screen to work out what is left
    /// and to project a running balance. Stored as text for the same reason the limits
    /// are: it round-trips through a text field and an empty string means "not set",
    /// which 0 cannot express.
    @Published var monthlyNetIncome: String {
        didSet {
            userDefaults.set(monthlyNetIncome, forKey: Keys.monthlyNetIncome)
        }
    }

    /// Whether the daily "did you log today" reminder is on. Only ever true when the
    /// system has actually granted permission — a toggle that looks on while
    /// notifications are denied would be a lie.
    @Published var reminderEnabled: Bool {
        didSet {
            userDefaults.set(reminderEnabled, forKey: Keys.reminderEnabled)
        }
    }

    /// Time of day for the reminder, stored as minutes since midnight so it stays a
    /// wall-clock time rather than an instant that shifts with the time zone.
    @Published var reminderMinutesSinceMidnight: Int {
        didSet {
            userDefaults.set(reminderMinutesSinceMidnight, forKey: Keys.reminderMinutes)
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
        static let monthlyNetIncome = "monthly_net_income"
        static let reminderEnabled = "reminder_enabled"
        static let reminderMinutes = "reminder_minutes_since_midnight"
        static let lastExchangeRates = "last_exchange_rates"
    }

    // MARK: - Initialization

    init() {
        self.defaultCurrency = userDefaults.string(forKey: Keys.defaultCurrency) ?? "₺"
        self.dailyLimit = userDefaults.string(forKey: Keys.dailyLimit) ?? ""
        self.monthlyLimit = userDefaults.string(forKey: Keys.monthlyLimit) ?? ""
        self.theme = userDefaults.string(forKey: Keys.theme) ?? "dark"

        self.launchCount = userDefaults.integer(forKey: Keys.launchCount)
        self.hasRatedApp = userDefaults.bool(forKey: Keys.hasRatedApp)
        self.monthlyNetIncome = userDefaults.string(forKey: Keys.monthlyNetIncome) ?? ""

        self.reminderEnabled = userDefaults.bool(forKey: Keys.reminderEnabled)

        // 21:00 by default — late enough that the day is done, early enough to still
        // act on. Only used until the user picks a time.
        let storedMinutes = userDefaults.object(forKey: Keys.reminderMinutes) as? Int
        self.reminderMinutesSinceMidnight = storedMinutes ?? (21 * 60)

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

    func setMonthlyNetIncome(_ income: String) {
        monthlyNetIncome = income
    }

    // MARK: - Exchange Rate Memory

    /// The rate last used for a currency pair, keyed "from→to".
    ///
    /// Someone who spends in dollars types the same 41.5 every time; the form prefills
    /// it. Per pair, not per currency, because the default currency can change and a
    /// USD→TRY rate says nothing about USD→EUR.
    func lastExchangeRate(from: String, to: String) -> Double? {
        let rates = userDefaults.dictionary(forKey: Keys.lastExchangeRates) as? [String: Double]
        return rates?[Self.pairKey(from: from, to: to)]
    }

    func rememberExchangeRate(_ rate: Double, from: String, to: String) {
        guard rate > 0, from != to else { return }
        var rates = userDefaults.dictionary(forKey: Keys.lastExchangeRates) as? [String: Double] ?? [:]
        rates[Self.pairKey(from: from, to: to)] = rate
        userDefaults.set(rates, forKey: Keys.lastExchangeRates)
    }

    private static func pairKey(from: String, to: String) -> String { "\(from)→\(to)" }

    var reminderHour: Int { reminderMinutesSinceMidnight / 60 }
    var reminderMinute: Int { reminderMinutesSinceMidnight % 60 }

    /// The reminder time as a `Date` today, for binding to a time picker.
    var reminderTime: Date {
        get {
            Calendar.current.date(
                bySettingHour: reminderHour, minute: reminderMinute, second: 0, of: Date()
            ) ?? Date()
        }
        set {
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            reminderMinutesSinceMidnight = (components.hour ?? 21) * 60 + (components.minute ?? 0)
        }
    }

    /// Parsed value for calculations. 0 when unset, which the overview screen treats
    /// as "no income configured" rather than "earns nothing".
    var monthlyNetIncomeValue: Double {
        return CurrencyInputFormatter.parseDouble(monthlyNetIncome)
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