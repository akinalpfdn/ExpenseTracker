//
//  AppTypography.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import SwiftUI

struct AppTypography {

    // MARK: - Font Definitions

    /// Large title text style (equivalent to Material 3 headlineLarge)
    static let titleLarge = Font.system(size: 32, weight: .bold, design: .default)

    /// Medium title text style (equivalent to Material 3 headlineMedium)
    static let titleMedium = Font.system(size: 28, weight: .semibold, design: .default)

    /// Small title text style (equivalent to Material 3 headlineSmall)
    static let titleSmall = Font.system(size: 24, weight: .medium, design: .default)

    /// Large body text style (equivalent to Material 3 bodyLarge)
    static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)

    /// Medium body text style (equivalent to Material 3 bodyMedium)
    static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)

    /// Small body text style (equivalent to Material 3 bodySmall)
    static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)

    /// Large label text style (equivalent to Material 3 labelLarge)
    static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)

    /// Medium label text style (equivalent to Material 3 labelMedium)
    static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)

    /// Small label text style (equivalent to Material 3 labelSmall)
    static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)

    /// Display styles for large text
    static let displayLarge = Font.system(size: 57, weight: .black, design: .default)
    static let displayMedium = Font.system(size: 45, weight: .black, design: .default)
    static let displaySmall = Font.system(size: 36, weight: .bold, design: .default)

    // MARK: - Custom App-Specific Fonts

    /// For expense amounts
    static let expenseAmount = Font.system(size: 18, weight: .semibold, design: .monospaced)

    /// For large expense amounts in cards
    static let expenseAmountLarge = Font.system(size: 24, weight: .bold, design: .monospaced)

    /// For currency symbols
    static let currency = Font.system(size: 16, weight: .medium, design: .default)

    /// For dates
    static let dateText = Font.system(size: 14, weight: .medium, design: .default)

    /// For category names
    static let categoryName = Font.system(size: 16, weight: .medium, design: .default)

    /// For subcategory names
    static let subcategoryName = Font.system(size: 14, weight: .regular, design: .default)

    /// For button text
    static let buttonText = Font.system(size: 16, weight: .semibold, design: .default)

    /// For small button text
    static let buttonTextSmall = Font.system(size: 14, weight: .medium, design: .default)

    /// For navigation titles
    static let navigationTitle = Font.system(size: 20, weight: .semibold, design: .default)

    /// For card titles
    static let cardTitle = Font.system(size: 18, weight: .semibold, design: .default)

    /// For card subtitles
    static let cardSubtitle = Font.system(size: 14, weight: .regular, design: .default)

    /// For form field labels
    static let fieldLabel = Font.system(size: 16, weight: .medium, design: .default)

    /// For placeholder text
    static let placeholder = Font.system(size: 16, weight: .regular, design: .default)

    /// For error messages
    static let errorText = Font.system(size: 12, weight: .medium, design: .default)
}

// MARK: - Text Style Extensions
extension Text {
    // MARK: - Standard Typography
    func titleLarge() -> Text {
        self.font(AppTypography.titleLarge)
    }

    func titleMedium() -> Text {
        self.font(AppTypography.titleMedium)
    }

    func titleSmall() -> Text {
        self.font(AppTypography.titleSmall)
    }

    func bodyLarge() -> Text {
        self.font(AppTypography.bodyLarge)
    }

    func bodyMedium() -> Text {
        self.font(AppTypography.bodyMedium)
    }

    func bodySmall() -> Text {
        self.font(AppTypography.bodySmall)
    }

    func labelLarge() -> Text {
        self.font(AppTypography.labelLarge)
    }

    func labelMedium() -> Text {
        self.font(AppTypography.labelMedium)
    }

    func labelSmall() -> Text {
        self.font(AppTypography.labelSmall)
    }

    // MARK: - App-Specific Typography
    func expenseAmount() -> Text {
        self.font(AppTypography.expenseAmount)
    }

    func expenseAmountLarge() -> Text {
        self.font(AppTypography.expenseAmountLarge)
    }

    func currency() -> Text {
        self.font(AppTypography.currency)
    }

    func dateText() -> Text {
        self.font(AppTypography.dateText)
    }

    func categoryName() -> Text {
        self.font(AppTypography.categoryName)
    }

    func subcategoryName() -> Text {
        self.font(AppTypography.subcategoryName)
    }

    func buttonText() -> Text {
        self.font(AppTypography.buttonText)
    }

    func buttonTextSmall() -> Text {
        self.font(AppTypography.buttonTextSmall)
    }

    func navigationTitle() -> Text {
        self.font(AppTypography.navigationTitle)
    }

    func cardTitle() -> Text {
        self.font(AppTypography.cardTitle)
    }

    func cardSubtitle() -> Text {
        self.font(AppTypography.cardSubtitle)
    }

    func fieldLabel() -> Text {
        self.font(AppTypography.fieldLabel)
    }

    func placeholder() -> Text {
        self.font(AppTypography.placeholder)
    }

    func errorText() -> Text {
        self.font(AppTypography.errorText)
    }
}