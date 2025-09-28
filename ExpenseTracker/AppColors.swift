//
//  AppColors.swift
//  ExpenseTracker
//
//  Created by migration from Android AppColors.kt and Color.kt
//

import SwiftUI

/// AppColors defines the core color palette used throughout the app
struct AppColors {

    // MARK: - Primary Colors
    static let primaryOrange = Color(red: 1.0, green: 0.39, blue: 0.0) // 0xFFFF6400
    static let primaryRed = Color(red: 1.0, green: 0.23, blue: 0.19) // 0xFFFF3B30

    // MARK: - Dark Theme Colors
    static let backgroundBlack = Color.black // 0xFF000000
    static let textWhite = Color.white // 0xFFFFFFFF
    static let textGray = Color(red: 0.5, green: 0.5, blue: 0.5) // 0xFF808080
    static let cardBackground = Color.white.opacity(0.05) // 0x0DFFFFFF
    static let inputBackground = Color.white.opacity(0.1) // 0x1AFFFFFF
    static let inputBackgroundFocused = Color.white.opacity(0.15) // 0x26FFFFFF
    static let buttonDisabled = Color(red: 0.5, green: 0.5, blue: 0.5).opacity(0.3) // 0x4D808080
    static let deleteRed = Color.red.opacity(0.8) // 0xCCFF0000
    static let successGreen = Color(red: 0.2, green: 0.78, blue: 0.35) // 0xFF34C759

    // MARK: - Light Theme Colors
    static let backgroundWhite = Color.white // 0xFFFFFFFF
    static let textBlack = Color.black // 0xFF000000
    static let textGrayLight = Color(red: 0.2, green: 0.2, blue: 0.2) // 0xFF333333
    static let cardBackgroundLight = Color(red: 0.97, green: 0.97, blue: 0.97) // 0xFFF8F8F8
    static let inputBackgroundLight = Color(red: 0.94, green: 0.94, blue: 0.94) // 0xFFF0F0F0
    static let inputBackgroundFocusedLight = Color(red: 0.91, green: 0.91, blue: 0.91) // 0xFFE8E8E8
    static let buttonDisabledLight = Color(red: 0.87, green: 0.87, blue: 0.87) // 0xFFDDDDDD
    static let deleteRedLight = Color.red.opacity(0.8) // 0xCCFF0000
    static let successGreenLight = Color(red: 0.16, green: 0.65, blue: 0.27) // 0xFF28A745

    // MARK: - Button Gradient Colors
    static let buttonGradientStart = primaryOrange
    static let buttonGradientEnd = primaryRed

    // MARK: - Primary Button Colors
    static let primaryButtonStart = Color(red: 1.0, green: 0.58, blue: 0.0) // 0xFFFF9500
    static let primaryButtonEnd = primaryRed

    // MARK: - Recurring Expenses Button Colors
    static let recurringButtonStart = Color(red: 0.12, green: 0.76, blue: 0.99) // 0xFF1EC3FC
    static let recurringButtonEnd = Color(red: 0.01, green: 0.67, blue: 0.89) // 0xFF03AAE4

    // MARK: - Dialog Background Colors
    static let dialogBackgroundDark = Color(red: 0.12, green: 0.12, blue: 0.12) // 0xFF1E1E1E
    static let dialogBackgroundLight = Color.white // 0xFFFFFFFF

    // MARK: - Legacy Material Theme Colors (from Color.kt)
    static let purple80 = Color(red: 0.82, green: 0.74, blue: 1.0) // 0xFFD0BCFF
    static let purpleGrey80 = Color(red: 0.8, green: 0.76, blue: 0.86) // 0xFFCCC2DC
    static let pink80 = Color(red: 0.94, green: 0.72, blue: 0.78) // 0xFFEFB8C8
    static let purple40 = Color(red: 0.4, green: 0.31, blue: 0.64) // 0xFF6650a4
    static let purpleGrey40 = Color(red: 0.38, green: 0.36, blue: 0.44) // 0xFF625b71
    static let pink40 = Color(red: 0.49, green: 0.32, blue: 0.38) // 0xFF7D5260
}

// MARK: - Gradient Definitions

extension AppColors {

    /// Primary button gradient (Orange to Red)
    static var primaryButtonGradient: LinearGradient {
        LinearGradient(
            colors: [primaryButtonStart, primaryButtonEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Recurring expenses button gradient (Light Blue to Blue)
    static var recurringButtonGradient: LinearGradient {
        LinearGradient(
            colors: [recurringButtonStart, recurringButtonEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// General button gradient (Orange to Red)
    static var buttonGradient: LinearGradient {
        LinearGradient(
            colors: [buttonGradientStart, buttonGradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Color Extension for Hex Support

extension Color {

    /// Initialize Color from hex value
    /// - Parameter hex: Hex color value (e.g., 0xFF6400)
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            red: Double((hex & 0xFF0000) >> 16) / 255.0,
            green: Double((hex & 0x00FF00) >> 8) / 255.0,
            blue: Double(hex & 0x0000FF) / 255.0,
            opacity: alpha
        )
    }
}