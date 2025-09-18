//
//  LocalizationManager.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import SwiftUI

class LocalizationManager: ObservableObject {
    @Published var currentLocale = Locale.current

    static let shared = LocalizationManager()

    private init() {}

    /// Get localized string with key
    func localizedString(_ key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }

    /// Get localized string with parameters
    func localizedString(_ key: String, _ arguments: CVarArg...) -> String {
        let localizedFormat = NSLocalizedString(key, comment: "")
        return String(format: localizedFormat, arguments)
    }

    /// Update locale programmatically (if needed for manual language switching)
    func setLocale(_ locale: Locale) {
        currentLocale = locale
    }

    /// Get available languages
    var availableLanguages: [String] {
        return Bundle.main.localizations.filter { $0 != "Base" }
    }
}

// MARK: - Convenience extension for Views
extension LocalizationManager {
    /// Helper method for simple localization in SwiftUI
    func text(_ key: String) -> Text {
        return Text(localizedString(key))
    }

    /// Helper method for parameterized localization in SwiftUI
    func text(_ key: String, _ arguments: CVarArg...) -> Text {
        return Text(localizedString(key, arguments))
    }
}

// MARK: - Global convenience function
func L(_ key: String) -> String {
    return LocalizationManager.shared.localizedString(key)
}

func L(_ key: String, _ arguments: CVarArg...) -> String {
    return LocalizationManager.shared.localizedString(key, arguments)
}