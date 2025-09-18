//
//  SettingsManager.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import Foundation
import SwiftUI
import Combine

/// Comprehensive settings manager for the expense tracker app
/// Replaces Kotlin PreferencesManager with UserDefaults and @Published properties
/// Provides reactive settings management with SwiftUI integration
@MainActor
class SettingsManager: ObservableObject {

    // MARK: - Singleton

    static let shared = SettingsManager()

    // MARK: - Published Properties for SwiftUI Reactivity

    /// Current currency setting
    @Published var currency: String = "TRY" {
        didSet {
            UserDefaults.standard.set(currency, forKey: SettingsKeys.currency)
            NotificationCenter.default.post(name: .currencyChanged, object: currency)
        }
    }

    /// Daily spending limit
    @Published var dailyLimit: Double = 0.0 {
        didSet {
            UserDefaults.standard.set(dailyLimit, forKey: SettingsKeys.dailyLimit)
            NotificationCenter.default.post(name: .limitsChanged, object: nil)
        }
    }

    /// Monthly spending limit
    @Published var monthlyLimit: Double = 0.0 {
        didSet {
            UserDefaults.standard.set(monthlyLimit, forKey: SettingsKeys.monthlyLimit)
            NotificationCenter.default.post(name: .limitsChanged, object: nil)
        }
    }

    /// Yearly spending limit
    @Published var yearlyLimit: Double = 0.0 {
        didSet {
            UserDefaults.standard.set(yearlyLimit, forKey: SettingsKeys.yearlyLimit)
            NotificationCenter.default.post(name: .limitsChanged, object: nil)
        }
    }

    /// Current theme setting
    @Published var theme: AppThemeType = .system {
        didSet {
            UserDefaults.standard.set(theme.rawValue, forKey: SettingsKeys.theme)
            NotificationCenter.default.post(name: .themeChanged, object: theme)
        }
    }

    /// Preferred language/locale
    @Published var preferredLanguage: String = "en" {
        didSet {
            UserDefaults.standard.set(preferredLanguage, forKey: SettingsKeys.language)
            NotificationCenter.default.post(name: .languageChanged, object: preferredLanguage)
        }
    }

    /// Enable/disable notifications
    @Published var notificationsEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: SettingsKeys.notificationsEnabled)
        }
    }

    /// Enable/disable limit notifications
    @Published var limitNotificationsEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(limitNotificationsEnabled, forKey: SettingsKeys.limitNotificationsEnabled)
        }
    }

    /// Enable/disable recurring expense notifications
    @Published var recurringExpenseNotificationsEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(recurringExpenseNotificationsEnabled, forKey: SettingsKeys.recurringExpenseNotificationsEnabled)
        }
    }

    /// Enable/disable biometric authentication
    @Published var biometricAuthEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(biometricAuthEnabled, forKey: SettingsKeys.biometricAuthEnabled)
        }
    }

    /// Default category for quick expense entry
    @Published var defaultCategoryId: String = "" {
        didSet {
            UserDefaults.standard.set(defaultCategoryId, forKey: SettingsKeys.defaultCategoryId)
        }
    }

    /// Auto-backup to iCloud
    @Published var autoBackupEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(autoBackupEnabled, forKey: SettingsKeys.autoBackupEnabled)
        }
    }

    /// Sync frequency for data updates
    @Published var syncFrequency: SyncFrequency = .daily {
        didSet {
            UserDefaults.standard.set(syncFrequency.rawValue, forKey: SettingsKeys.syncFrequency)
        }
    }

    /// Enable/disable analytics tracking
    @Published var analyticsEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(analyticsEnabled, forKey: SettingsKeys.analyticsEnabled)
        }
    }

    /// Export format preference
    @Published var exportFormat: ExportFormat = .csv {
        didSet {
            UserDefaults.standard.set(exportFormat.rawValue, forKey: SettingsKeys.exportFormat)
        }
    }

    /// Date format preference
    @Published var dateFormat: DateFormatType = .system {
        didSet {
            UserDefaults.standard.set(dateFormat.rawValue, forKey: SettingsKeys.dateFormat)
        }
    }

    /// Number format preference
    @Published var numberFormat: NumberFormatType = .system {
        didSet {
            UserDefaults.standard.set(numberFormat.rawValue, forKey: SettingsKeys.numberFormat)
        }
    }

    /// First day of week (0 = Sunday, 1 = Monday)
    @Published var firstDayOfWeek: Int = 1 {
        didSet {
            UserDefaults.standard.set(firstDayOfWeek, forKey: SettingsKeys.firstDayOfWeek)
        }
    }

    /// Budget period setting
    @Published var budgetPeriod: BudgetPeriod = .monthly {
        didSet {
            UserDefaults.standard.set(budgetPeriod.rawValue, forKey: SettingsKeys.budgetPeriod)
        }
    }

    /// Auto-categorization enabled
    @Published var autoCategorizeEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(autoCategorizeEnabled, forKey: SettingsKeys.autoCategorizeEnabled)
        }
    }

    /// Default expense status for new expenses
    @Published var defaultExpenseStatus: ExpenseStatus = .confirmed {
        didSet {
            UserDefaults.standard.set(defaultExpenseStatus.rawValue, forKey: SettingsKeys.defaultExpenseStatus)
        }
    }

    /// Show decimal places in amounts
    @Published var showDecimalPlaces: Bool = true {
        didSet {
            UserDefaults.standard.set(showDecimalPlaces, forKey: SettingsKeys.showDecimalPlaces)
        }
    }

    /// Enable haptic feedback
    @Published var hapticFeedbackEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(hapticFeedbackEnabled, forKey: SettingsKeys.hapticFeedbackEnabled)
        }
    }

    // MARK: - Private Properties

    private let userDefaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        loadSettings()
        setupDefaultsIfNeeded()
    }

    // MARK: - Public Methods

    /// Loads all settings from UserDefaults
    func loadSettings() {
        currency = userDefaults.string(forKey: SettingsKeys.currency) ?? "TRY"
        dailyLimit = userDefaults.double(forKey: SettingsKeys.dailyLimit)
        monthlyLimit = userDefaults.double(forKey: SettingsKeys.monthlyLimit)
        yearlyLimit = userDefaults.double(forKey: SettingsKeys.yearlyLimit)

        if let themeRawValue = userDefaults.string(forKey: SettingsKeys.theme),
           let themeType = AppThemeType(rawValue: themeRawValue) {
            theme = themeType
        }

        preferredLanguage = userDefaults.string(forKey: SettingsKeys.language) ?? "en"
        notificationsEnabled = userDefaults.bool(forKey: SettingsKeys.notificationsEnabled)
        limitNotificationsEnabled = userDefaults.bool(forKey: SettingsKeys.limitNotificationsEnabled)
        recurringExpenseNotificationsEnabled = userDefaults.bool(forKey: SettingsKeys.recurringExpenseNotificationsEnabled)
        biometricAuthEnabled = userDefaults.bool(forKey: SettingsKeys.biometricAuthEnabled)
        defaultCategoryId = userDefaults.string(forKey: SettingsKeys.defaultCategoryId) ?? ""
        autoBackupEnabled = userDefaults.bool(forKey: SettingsKeys.autoBackupEnabled)

        if let syncFreqRawValue = userDefaults.string(forKey: SettingsKeys.syncFrequency),
           let syncFreq = SyncFrequency(rawValue: syncFreqRawValue) {
            syncFrequency = syncFreq
        }

        analyticsEnabled = userDefaults.bool(forKey: SettingsKeys.analyticsEnabled)

        if let exportFormatRawValue = userDefaults.string(forKey: SettingsKeys.exportFormat),
           let exportFormatType = ExportFormat(rawValue: exportFormatRawValue) {
            exportFormat = exportFormatType
        }

        if let dateFormatRawValue = userDefaults.string(forKey: SettingsKeys.dateFormat),
           let dateFormatType = DateFormatType(rawValue: dateFormatRawValue) {
            dateFormat = dateFormatType
        }

        if let numberFormatRawValue = userDefaults.string(forKey: SettingsKeys.numberFormat),
           let numberFormatType = NumberFormatType(rawValue: numberFormatRawValue) {
            numberFormat = numberFormatType
        }

        firstDayOfWeek = userDefaults.integer(forKey: SettingsKeys.firstDayOfWeek)

        if let budgetPeriodRawValue = userDefaults.string(forKey: SettingsKeys.budgetPeriod),
           let budgetPeriodType = BudgetPeriod(rawValue: budgetPeriodRawValue) {
            budgetPeriod = budgetPeriodType
        }

        autoCategorizeEnabled = userDefaults.bool(forKey: SettingsKeys.autoCategorizeEnabled)

        if let defaultStatusRawValue = userDefaults.string(forKey: SettingsKeys.defaultExpenseStatus),
           let defaultStatus = ExpenseStatus(rawValue: defaultStatusRawValue) {
            defaultExpenseStatus = defaultStatus
        }

        showDecimalPlaces = userDefaults.bool(forKey: SettingsKeys.showDecimalPlaces)
        hapticFeedbackEnabled = userDefaults.bool(forKey: SettingsKeys.hapticFeedbackEnabled)
    }

    /// Sets up default values if they haven't been set before
    private func setupDefaultsIfNeeded() {
        let hasBeenSetupBefore = userDefaults.bool(forKey: SettingsKeys.hasBeenSetupBefore)

        if !hasBeenSetupBefore {
            // Set default values
            notificationsEnabled = true
            limitNotificationsEnabled = true
            recurringExpenseNotificationsEnabled = true
            autoBackupEnabled = true
            analyticsEnabled = true
            autoCategorizeEnabled = true
            showDecimalPlaces = true
            hapticFeedbackEnabled = true
            firstDayOfWeek = 1 // Monday

            // Mark as setup
            userDefaults.set(true, forKey: SettingsKeys.hasBeenSetupBefore)
        }
    }

    /// Resets all settings to default values
    func resetToDefaults() async {
        currency = "TRY"
        dailyLimit = 0.0
        monthlyLimit = 0.0
        yearlyLimit = 0.0
        theme = .system
        preferredLanguage = "en"
        notificationsEnabled = true
        limitNotificationsEnabled = true
        recurringExpenseNotificationsEnabled = true
        biometricAuthEnabled = false
        defaultCategoryId = ""
        autoBackupEnabled = true
        syncFrequency = .daily
        analyticsEnabled = true
        exportFormat = .csv
        dateFormat = .system
        numberFormat = .system
        firstDayOfWeek = 1
        budgetPeriod = .monthly
        autoCategorizeEnabled = true
        defaultExpenseStatus = .confirmed
        showDecimalPlaces = true
        hapticFeedbackEnabled = true

        // Clear setup flag to reset defaults
        userDefaults.removeObject(forKey: SettingsKeys.hasBeenSetupBefore)
        setupDefaultsIfNeeded()

        NotificationCenter.default.post(name: .settingsReset, object: nil)
    }

    /// Updates multiple settings at once
    /// - Parameter updates: Dictionary of setting key-value pairs
    func updateSettings(_ updates: [String: Any]) async {
        for (key, value) in updates {
            switch key {
            case SettingsKeys.currency:
                if let currencyValue = value as? String {
                    currency = currencyValue
                }
            case SettingsKeys.dailyLimit:
                if let limitValue = value as? Double {
                    dailyLimit = limitValue
                }
            case SettingsKeys.monthlyLimit:
                if let limitValue = value as? Double {
                    monthlyLimit = limitValue
                }
            case SettingsKeys.yearlyLimit:
                if let limitValue = value as? Double {
                    yearlyLimit = limitValue
                }
            case SettingsKeys.theme:
                if let themeValue = value as? String,
                   let themeType = AppThemeType(rawValue: themeValue) {
                    theme = themeType
                }
            case SettingsKeys.language:
                if let languageValue = value as? String {
                    preferredLanguage = languageValue
                }
            default:
                break
            }
        }
    }

    /// Exports current settings to a dictionary
    /// - Returns: Dictionary containing all current settings
    func exportSettings() -> [String: Any] {
        return [
            SettingsKeys.currency: currency,
            SettingsKeys.dailyLimit: dailyLimit,
            SettingsKeys.monthlyLimit: monthlyLimit,
            SettingsKeys.yearlyLimit: yearlyLimit,
            SettingsKeys.theme: theme.rawValue,
            SettingsKeys.language: preferredLanguage,
            SettingsKeys.notificationsEnabled: notificationsEnabled,
            SettingsKeys.limitNotificationsEnabled: limitNotificationsEnabled,
            SettingsKeys.recurringExpenseNotificationsEnabled: recurringExpenseNotificationsEnabled,
            SettingsKeys.biometricAuthEnabled: biometricAuthEnabled,
            SettingsKeys.defaultCategoryId: defaultCategoryId,
            SettingsKeys.autoBackupEnabled: autoBackupEnabled,
            SettingsKeys.syncFrequency: syncFrequency.rawValue,
            SettingsKeys.analyticsEnabled: analyticsEnabled,
            SettingsKeys.exportFormat: exportFormat.rawValue,
            SettingsKeys.dateFormat: dateFormat.rawValue,
            SettingsKeys.numberFormat: numberFormat.rawValue,
            SettingsKeys.firstDayOfWeek: firstDayOfWeek,
            SettingsKeys.budgetPeriod: budgetPeriod.rawValue,
            SettingsKeys.autoCategorizeEnabled: autoCategorizeEnabled,
            SettingsKeys.defaultExpenseStatus: defaultExpenseStatus.rawValue,
            SettingsKeys.showDecimalPlaces: showDecimalPlaces,
            SettingsKeys.hapticFeedbackEnabled: hapticFeedbackEnabled
        ]
    }

    /// Imports settings from a dictionary
    /// - Parameter settings: Dictionary containing settings to import
    func importSettings(_ settings: [String: Any]) async {
        await updateSettings(settings)
    }

    /// Validates that spending limits are properly configured
    /// - Returns: Validation result with any issues found
    func validateLimits() -> LimitValidationResult {
        var issues: [String] = []

        if dailyLimit > 0 && monthlyLimit > 0 {
            let maxDailyFromMonthly = monthlyLimit / 30.0
            if dailyLimit > maxDailyFromMonthly {
                issues.append(L("daily_limit_exceeds_monthly_average"))
            }
        }

        if monthlyLimit > 0 && yearlyLimit > 0 {
            let maxMonthlyFromYearly = yearlyLimit / 12.0
            if monthlyLimit > maxMonthlyFromYearly {
                issues.append(L("monthly_limit_exceeds_yearly_average"))
            }
        }

        if dailyLimit > 0 && yearlyLimit > 0 {
            let maxDailyFromYearly = yearlyLimit / 365.0
            if dailyLimit > maxDailyFromYearly {
                issues.append(L("daily_limit_exceeds_yearly_average"))
            }
        }

        return LimitValidationResult(
            isValid: issues.isEmpty,
            issues: issues
        )
    }

    /// Gets formatted currency string for an amount
    /// - Parameter amount: Amount to format
    /// - Returns: Formatted currency string
    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = Locale.current

        if !showDecimalPlaces {
            formatter.maximumFractionDigits = 0
        }

        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) \(currency)"
    }

    /// Gets formatted date string based on user preference
    /// - Parameter date: Date to format
    /// - Returns: Formatted date string
    func formatDate(_ date: Date) -> String {
        return dateFormat.formatter.string(from: date)
    }

    /// Gets available currencies
    /// - Returns: Array of currency codes
    func getAvailableCurrencies() -> [String] {
        return [
            "USD", "EUR", "GBP", "JPY", "TRY", "CAD", "AUD", "CHF", "CNY", "SEK",
            "NOK", "DKK", "PLN", "CZK", "HUF", "RUB", "BRL", "MXN", "INR", "KRW",
            "SGD", "HKD", "NZD", "ZAR", "THB", "MYR", "IDR", "PHP", "VND", "EGP",
            "AED", "SAR", "QAR", "KWD", "BHD", "OMR", "JOD", "LBP", "ILS", "RON",
            "BGN", "HRK", "RSD", "BAM", "MKD", "ALL", "AMD", "AZN", "GEL", "KZT",
            "UZS", "KGS", "TJS", "TMT", "AFN", "PKR", "LKR", "BDT", "NPR", "BTN",
            "MMK", "LAK", "KHR", "MNT", "TWD", "HKD", "MOP", "BND", "FJD", "PGK",
            "SBD", "VUV", "WST", "TOP", "CDF", "ANG", "AWG", "BBD", "BZD", "BMD",
            "KYD", "XCD", "BSD", "JMD", "TTD", "HTG", "DOP", "CUP", "GTQ", "HNL",
            "NIO", "CRC", "PAB", "SVC", "PEN", "BOB", "CLP", "ARS", "UYU", "PYG",
            "COP", "VES", "GYD", "SRD", "FKP", "GGP", "JEP", "IMP", "SHP", "GIP"
        ]
    }

    /// Checks if user has limit notifications enabled and limits configured
    /// - Returns: True if user should receive limit notifications
    func shouldShowLimitNotifications() -> Bool {
        return notificationsEnabled && limitNotificationsEnabled && hasAnyLimitConfigured()
    }

    /// Checks if any spending limits are configured
    /// - Returns: True if any limit is greater than 0
    func hasAnyLimitConfigured() -> Bool {
        return dailyLimit > 0 || monthlyLimit > 0 || yearlyLimit > 0
    }

    /// Triggers haptic feedback if enabled
    /// - Parameter type: Type of haptic feedback
    func triggerHapticFeedback(_ type: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard hapticFeedbackEnabled else { return }

        let impactGenerator = UIImpactFeedbackGenerator(style: type)
        impactGenerator.impactOccurred()
    }
}

// MARK: - Supporting Types

/// Settings keys for UserDefaults storage
private struct SettingsKeys {
    static let currency = "settings_currency"
    static let dailyLimit = "settings_daily_limit"
    static let monthlyLimit = "settings_monthly_limit"
    static let yearlyLimit = "settings_yearly_limit"
    static let theme = "settings_theme"
    static let language = "settings_language"
    static let notificationsEnabled = "settings_notifications_enabled"
    static let limitNotificationsEnabled = "settings_limit_notifications_enabled"
    static let recurringExpenseNotificationsEnabled = "settings_recurring_expense_notifications_enabled"
    static let biometricAuthEnabled = "settings_biometric_auth_enabled"
    static let defaultCategoryId = "settings_default_category_id"
    static let autoBackupEnabled = "settings_auto_backup_enabled"
    static let syncFrequency = "settings_sync_frequency"
    static let analyticsEnabled = "settings_analytics_enabled"
    static let exportFormat = "settings_export_format"
    static let dateFormat = "settings_date_format"
    static let numberFormat = "settings_number_format"
    static let firstDayOfWeek = "settings_first_day_of_week"
    static let budgetPeriod = "settings_budget_period"
    static let autoCategorizeEnabled = "settings_auto_categorize_enabled"
    static let defaultExpenseStatus = "settings_default_expense_status"
    static let showDecimalPlaces = "settings_show_decimal_places"
    static let hapticFeedbackEnabled = "settings_haptic_feedback_enabled"
    static let hasBeenSetupBefore = "settings_has_been_setup_before"
}

/// Theme type enumeration
enum AppThemeType: String, CaseIterable, Identifiable {
    case light = "light"
    case dark = "dark"
    case system = "system"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light:
            return L("theme_light")
        case .dark:
            return L("theme_dark")
        case .system:
            return L("theme_system")
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
}

/// Sync frequency options
enum SyncFrequency: String, CaseIterable, Identifiable {
    case never = "never"
    case hourly = "hourly"
    case daily = "daily"
    case weekly = "weekly"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .never:
            return L("sync_never")
        case .hourly:
            return L("sync_hourly")
        case .daily:
            return L("sync_daily")
        case .weekly:
            return L("sync_weekly")
        }
    }
}

/// Export format options
enum ExportFormat: String, CaseIterable, Identifiable {
    case csv = "csv"
    case excel = "excel"
    case pdf = "pdf"
    case json = "json"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .csv:
            return L("export_csv")
        case .excel:
            return L("export_excel")
        case .pdf:
            return L("export_pdf")
        case .json:
            return L("export_json")
        }
    }

    var fileExtension: String {
        switch self {
        case .csv:
            return "csv"
        case .excel:
            return "xlsx"
        case .pdf:
            return "pdf"
        case .json:
            return "json"
        }
    }
}

/// Date format type options
enum DateFormatType: String, CaseIterable, Identifiable {
    case system = "system"
    case iso = "iso"
    case us = "us"
    case european = "european"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system:
            return L("date_format_system")
        case .iso:
            return L("date_format_iso")
        case .us:
            return L("date_format_us")
        case .european:
            return L("date_format_european")
        }
    }

    var formatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current

        switch self {
        case .system:
            formatter.dateStyle = .medium
        case .iso:
            formatter.dateFormat = "yyyy-MM-dd"
        case .us:
            formatter.dateFormat = "MM/dd/yyyy"
        case .european:
            formatter.dateFormat = "dd/MM/yyyy"
        }

        return formatter
    }
}

/// Number format type options
enum NumberFormatType: String, CaseIterable, Identifiable {
    case system = "system"
    case comma = "comma"
    case period = "period"
    case space = "space"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system:
            return L("number_format_system")
        case .comma:
            return L("number_format_comma")
        case .period:
            return L("number_format_period")
        case .space:
            return L("number_format_space")
        }
    }
}

/// Budget period options
enum BudgetPeriod: String, CaseIterable, Identifiable {
    case weekly = "weekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case yearly = "yearly"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weekly:
            return L("budget_period_weekly")
        case .monthly:
            return L("budget_period_monthly")
        case .quarterly:
            return L("budget_period_quarterly")
        case .yearly:
            return L("budget_period_yearly")
        }
    }
}

/// Limit validation result
struct LimitValidationResult {
    let isValid: Bool
    let issues: [String]
}

// MARK: - Notification Names

extension Notification.Name {
    static let currencyChanged = Notification.Name("currencyChanged")
    static let limitsChanged = Notification.Name("limitsChanged")
    static let themeChanged = Notification.Name("themeChanged")
    static let languageChanged = Notification.Name("languageChanged")
    static let settingsReset = Notification.Name("settingsReset")
}

// MARK: - Preview Helper

#if DEBUG
extension SettingsManager {
    static let preview: SettingsManager = {
        let manager = SettingsManager()
        manager.currency = "USD"
        manager.dailyLimit = 100.0
        manager.monthlyLimit = 3000.0
        manager.theme = .system
        return manager
    }()
}
#endif