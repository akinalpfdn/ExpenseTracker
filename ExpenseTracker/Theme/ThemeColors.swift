//
//  ThemeColors.swift
//  ExpenseTracker
//
//  Created by migration from Android ThemeColors.kt
//

import SwiftUI

/// ThemeColors provides theme-aware color selection based on dark/light mode
struct ThemeColors {

    // MARK: - Background Colors

    /// Returns background color based on current theme
    /// - Parameter isDarkTheme: Whether dark theme is active
    /// - Returns: Appropriate background color
    static func getBackgroundColor(isDarkTheme: Bool) -> Color {
        return isDarkTheme ? AppColors.backgroundBlack : AppColors.backgroundWhite
    }

    // MARK: - Text Colors

    /// Returns primary text color based on current theme
    /// - Parameter isDarkTheme: Whether dark theme is active
    /// - Returns: Appropriate text color
    static func getTextColor(isDarkTheme: Bool) -> Color {
        return isDarkTheme ? AppColors.textWhite : AppColors.textBlack
    }

    /// Returns secondary/gray text color based on current theme
    /// - Parameter isDarkTheme: Whether dark theme is active
    /// - Returns: Appropriate gray text color
    static func getTextGrayColor(isDarkTheme: Bool) -> Color {
        return isDarkTheme ? AppColors.textGray : AppColors.textGrayLight
    }

    // MARK: - Card/Surface Colors

    /// Returns card background color based on current theme
    /// - Parameter isDarkTheme: Whether dark theme is active
    /// - Returns: Appropriate card background color
    static func getCardBackgroundColor(isDarkTheme: Bool) -> Color {
        return isDarkTheme ? AppColors.cardBackground : AppColors.cardBackgroundLight
    }

    // MARK: - Input Colors

    /// Returns input field background color based on current theme
    /// - Parameter isDarkTheme: Whether dark theme is active
    /// - Returns: Appropriate input background color
    static func getInputBackgroundColor(isDarkTheme: Bool) -> Color {
        return isDarkTheme ? AppColors.inputBackground : AppColors.inputBackgroundLight
    }

    /// Returns focused input field background color based on current theme
    /// - Parameter isDarkTheme: Whether dark theme is active
    /// - Returns: Appropriate focused input background color
    static func getInputBackgroundFocusedColor(isDarkTheme: Bool) -> Color {
        return isDarkTheme ? AppColors.inputBackgroundFocused : AppColors.inputBackgroundFocusedLight
    }

    // MARK: - Button Colors

    /// Returns disabled button color based on current theme
    /// - Parameter isDarkTheme: Whether dark theme is active
    /// - Returns: Appropriate disabled button color
    static func getButtonDisabledColor(isDarkTheme: Bool) -> Color {
        return isDarkTheme ? AppColors.buttonDisabled : AppColors.buttonDisabledLight
    }

    // MARK: - Status Colors

    /// Returns delete/danger color based on current theme
    /// - Parameter isDarkTheme: Whether dark theme is active
    /// - Returns: Appropriate delete red color
    static func getDeleteRedColor(isDarkTheme: Bool) -> Color {
        return isDarkTheme ? AppColors.deleteRed : AppColors.deleteRedLight
    }

    /// Returns success color based on current theme
    /// - Parameter isDarkTheme: Whether dark theme is active
    /// - Returns: Appropriate success green color
    static func getSuccessGreenColor(isDarkTheme: Bool) -> Color {
        return isDarkTheme ? AppColors.successGreen : AppColors.successGreenLight
    }

    // MARK: - Dialog Colors

    /// Returns dialog background color based on current theme
    /// - Parameter isDarkTheme: Whether dark theme is active
    /// - Returns: Appropriate dialog background color
    static func getDialogBackgroundColor(isDarkTheme: Bool) -> Color {
        return isDarkTheme ? AppColors.dialogBackgroundDark : AppColors.dialogBackgroundLight
    }

    /// Returns bottom sheet background color based on current theme
    /// - Parameter isDarkTheme: Whether dark theme is active
    /// - Returns: Appropriate bottom sheet background color
    static func getBottomSheetBackgroundColor(isDarkTheme: Bool) -> Color {
        return isDarkTheme ? AppColors.backgroundBlack : AppColors.backgroundWhite
    }
}

// MARK: - SwiftUI Environment Integration

/// Environment key for theme mode
struct ThemeModeKey: EnvironmentKey {
    static let defaultValue: Bool = false // false = light, true = dark
}

extension EnvironmentValues {
    /// Current theme mode (false = light, true = dark)
    var isDarkTheme: Bool {
        get { self[ThemeModeKey.self] }
        set { self[ThemeModeKey.self] = newValue }
    }
}

// MARK: - View Extensions for Theme Support

extension View {
    /// Apply theme mode to view hierarchy
    /// - Parameter isDarkTheme: Whether dark theme should be active
    /// - Returns: View with theme mode applied
    func themeMode(_ isDarkTheme: Bool) -> some View {
        environment(\.isDarkTheme, isDarkTheme)
    }
}

// MARK: - Theme-Aware Color Extensions

extension Color {

    /// Background color that adapts to current theme
    static var themeBackground: Color {
        Color.primary // This will be properly implemented with theme manager
    }

    /// Text color that adapts to current theme
    static var themeText: Color {
        Color.primary // This will be properly implemented with theme manager
    }

    /// Card background color that adapts to current theme
    static var themeCardBackground: Color {
        Color.secondary.opacity(0.1) // This will be properly implemented with theme manager
    }
}

// MARK: - Theme Constants

extension ThemeColors {

    /// Theme-independent colors that don't change between light/dark modes
    struct Static {
        static let primaryOrange = AppColors.primaryOrange
        static let primaryRed = AppColors.primaryRed
        static let primaryButtonGradient = AppColors.primaryButtonGradient
        static let recurringButtonGradient = AppColors.recurringButtonGradient
        static let buttonGradient = AppColors.buttonGradient
    }
}
