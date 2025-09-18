//
//  ThemeColors.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import SwiftUI

struct ThemeColors {

    // MARK: - Background Colors
    static func backgroundColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? AppColors.backgroundBlack : AppColors.backgroundWhite
    }

    // MARK: - Text Colors
    static func textColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? AppColors.textWhite : AppColors.textBlack
    }

    static func textGrayColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? AppColors.textGray : AppColors.textGrayLight
    }

    // MARK: - Card Colors
    static func cardBackgroundColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? AppColors.cardBackground : AppColors.cardBackgroundLight
    }

    // MARK: - Input Colors
    static func inputBackgroundColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? AppColors.inputBackground : AppColors.inputBackgroundLight
    }

    static func inputBackgroundFocusedColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? AppColors.inputBackgroundFocused : AppColors.inputBackgroundFocusedLight
    }

    // MARK: - Button Colors
    static func buttonDisabledColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? AppColors.buttonDisabled : AppColors.buttonDisabledLight
    }

    // MARK: - Status Colors
    static func deleteRedColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? AppColors.deleteRed : AppColors.deleteRedLight
    }

    static func successGreenColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? AppColors.successGreen : AppColors.successGreenLight
    }

    // MARK: - Dialog Colors
    static func dialogBackgroundColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? AppColors.dialogBackgroundDark : AppColors.dialogBackgroundLight
    }
}

// MARK: - Environment-based Extensions
extension View {
    func themedBackgroundColor() -> some View {
        self.background(Color.primary.colorInvert())
    }

    func themedTextColor() -> some View {
        self.foregroundColor(.primary)
    }

    func themedCardBackground(_ colorScheme: ColorScheme) -> some View {
        self.background(ThemeColors.cardBackgroundColor(for: colorScheme))
    }
}