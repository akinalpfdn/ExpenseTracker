//
//  LocalizationManager.swift
//  ExpenseTracker
//
//  Created by migration from Android localization system
//

import Foundation
import SwiftUI

/// LocalizationManager provides convenient access to localized strings and language management
class LocalizationManager: ObservableObject {

    /// Shared instance for app-wide access
    static let shared = LocalizationManager()

    /// Current language code (e.g., "en", "tr")
    @Published var currentLanguage: String {
        didSet {
            setLanguage(currentLanguage)
        }
    }

    /// Available languages in the app
    static let availableLanguages = ["en", "tr"]

    /// Language display names
    static let languageNames: [String: String] = [
        "en": "English",
        "tr": "Türkçe"
    ]

    private init() {
        // Get system language or default to English
        let systemLanguage = Locale.current.language.languageCode?.identifier ?? "en"
        self.currentLanguage = LocalizationManager.availableLanguages.contains(systemLanguage) ? systemLanguage : "en"
    }

    /// Set the app language
    func setLanguage(_ languageCode: String) {
        guard LocalizationManager.availableLanguages.contains(languageCode) else { return }

        UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()

        // Notify observers that language changed
        objectWillChange.send()
    }

    /// Get localized string for the given key
    func localizedString(for key: String, comment: String = "") -> String {
        return NSLocalizedString(key, comment: comment)
    }

    /// Get localized string with format arguments
    func localizedString(for key: String, arguments: CVarArg..., comment: String = "") -> String {
        let format = NSLocalizedString(key, comment: comment)
        return String(format: format, arguments: arguments)
    }
}

// MARK: - Convenience Extensions

extension String {
    /// Get localized version of this string key
    var localized: String {
        return LocalizationManager.shared.localizedString(for: self)
    }

    /// Get localized version with format arguments
    func localized(with arguments: CVarArg...) -> String {
        return LocalizationManager.shared.localizedString(for: self, arguments: arguments)
    }
}

// MARK: - SwiftUI View Extension

extension View {
    /// Get localized string within SwiftUI context
    func localizedText(_ key: String) -> Text {
        return Text(LocalizationManager.shared.localizedString(for: key))
    }
}

// MARK: - Commonly Used Localized Strings

extension LocalizationManager {

    // MARK: - General
    var appName: String { localizedString(for: "app_name") }
    var generalSettings: String { localizedString(for: "general_settings") }
    var categories: String { localizedString(for: "categories") }
    var cancel: String { localizedString(for: "cancel") }
    var save: String { localizedString(for: "save") }
    var delete: String { localizedString(for: "delete") }
    var edit: String { localizedString(for: "edit") }
    var ok: String { localizedString(for: "ok") }
    var amount: String { localizedString(for: "amount") }
    var description: String { localizedString(for: "description") }

    // MARK: - Expenses
    var addExpense: String { localizedString(for: "add_expense") }
    var updateExpense: String { localizedString(for: "update_expense") }
    var editExpense: String { localizedString(for: "edit_expense") }
    var newExpense: String { localizedString(for: "new_expense") }
    var deleteExpense: String { localizedString(for: "delete_expense") }
    var noExpensesToday: String { localizedString(for: "no_expenses_today") }
    var noExpensesYet: String { localizedString(for: "no_expenses_yet") }
    var firstExpenseHint: String { localizedString(for: "first_expense_hint") }
    var addExpenseForDayHint: String { localizedString(for: "add_expense_for_day_hint") }

    // MARK: - Search and Sort
    var search: String { localizedString(for: "search") }
    var sort: String { localizedString(for: "sort") }
    var searchPlaceholder: String { localizedString(for: "search_placeholder") }
    var noSearchResults: String { localizedString(for: "no_search_results") }

    // MARK: - Planning
    var financialPlanning: String { localizedString(for: "financial_planning") }
    var addPlan: String { localizedString(for: "add_plan") }
    var deletePlan: String { localizedString(for: "delete_plan") }
    var noPlanYet: String { localizedString(for: "no_plans_yet") }
    var createFirstPlan: String { localizedString(for: "create_first_plan") }

    // MARK: - Categories
    var categoryFood: String { localizedString(for: "category_food") }
    var categoryHousing: String { localizedString(for: "category_housing") }
    var categoryTransportation: String { localizedString(for: "category_transportation") }
    var categoryHealth: String { localizedString(for: "category_health") }
    var categoryEntertainment: String { localizedString(for: "category_entertainment") }
    var categoryEducation: String { localizedString(for: "category_education") }
    var categoryShopping: String { localizedString(for: "category_shopping") }
    var categoryPets: String { localizedString(for: "category_pets") }
    var categoryWork: String { localizedString(for: "category_work") }
    var categoryTax: String { localizedString(for: "category_tax") }
    var categoryDonations: String { localizedString(for: "category_donations") }
    var categoryOthers: String { localizedString(for: "category_others") }

    // MARK: - Recurrence Types
    var daily: String { localizedString(for: "daily") }
    var weekly: String { localizedString(for: "weekly") }
    var monthly: String { localizedString(for: "monthly") }
    var oneTime: String { localizedString(for: "one_time") }
    var none: String { localizedString(for: "none") }

    // MARK: - Time and Date
    var mondayShort: String { localizedString(for: "monday_short") }
    var tuesdayShort: String { localizedString(for: "tuesday_short") }
    var wednesdayShort: String { localizedString(for: "wednesday_short") }
    var thursdayShort: String { localizedString(for: "thursday_short") }
    var fridayShort: String { localizedString(for: "friday_short") }
    var saturdayShort: String { localizedString(for: "saturday_short") }
    var sundayShort: String { localizedString(for: "sunday_short") }

    // MARK: - Messages with Parameters
    func searchNoResultsDescription(searchTerm: String) -> String {
        return localizedString(for: "search_no_results_description", arguments: searchTerm)
    }

    func resultsFound(count: Int) -> String {
        return localizedString(for: "results_found", arguments: count)
    }

    func resultsCount(count: Int) -> String {
        return localizedString(for: "results_count", arguments: count)
    }

    func deletePlanConfirmation(planName: String) -> String {
        return localizedString(for: "delete_plan_confirmation", arguments: planName)
    }

    func deleteItemConfirmation(itemName: String) -> String {
        return localizedString(for: "delete_item_confirmation", arguments: itemName)
    }

    func exchangeRate(rate: String) -> String {
        return localizedString(for: "exchange_rate", arguments: rate)
    }

    func endDateRecurring(date: String) -> String {
        return localizedString(for: "end_date_recurring", arguments: date)
    }
}