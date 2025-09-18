//
//  AppColors.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import SwiftUI

struct AppColors {

    // MARK: - Primary Colors
    static let primaryOrange = Color(red: 1.0, green: 0.39, blue: 0.0) // #FF6400
    static let primaryRed = Color(red: 1.0, green: 0.23, blue: 0.19)  // #FF3B30

    // MARK: - Dark Theme Colors
    static let backgroundBlack = Color.black                          // #000000
    static let textWhite = Color.white                               // #FFFFFF
    static let textGray = Color(red: 0.5, green: 0.5, blue: 0.5)    // #808080
    static let cardBackground = Color.white.opacity(0.05)           // #0DFFFFFF
    static let inputBackground = Color.white.opacity(0.10)          // #1AFFFFFF
    static let inputBackgroundFocused = Color.white.opacity(0.15)   // #26FFFFFF
    static let buttonDisabled = Color(red: 0.5, green: 0.5, blue: 0.5).opacity(0.30) // #4D808080
    static let deleteRed = Color(red: 1.0, green: 0.0, blue: 0.0).opacity(0.80)      // #CCFF0000
    static let successGreen = Color(red: 0.20, green: 0.78, blue: 0.35)              // #34C759

    // MARK: - Light Theme Colors
    static let backgroundWhite = Color.white                         // #FFFFFF
    static let textBlack = Color.black                              // #000000
    static let textGrayLight = Color(red: 0.2, green: 0.2, blue: 0.2) // #333333
    static let cardBackgroundLight = Color(red: 0.97, green: 0.97, blue: 0.97) // #F8F8F8
    static let inputBackgroundLight = Color(red: 0.94, green: 0.94, blue: 0.94) // #F0F0F0
    static let inputBackgroundFocusedLight = Color(red: 0.91, green: 0.91, blue: 0.91) // #E8E8E8
    static let buttonDisabledLight = Color(red: 0.87, green: 0.87, blue: 0.87) // #DDDDDD
    static let deleteRedLight = Color(red: 1.0, green: 0.0, blue: 0.0).opacity(0.80) // #CCFF0000
    static let successGreenLight = Color(red: 0.16, green: 0.65, blue: 0.27) // #28A745

    // MARK: - Button Gradients
    static let primaryButtonStart = Color(red: 1.0, green: 0.58, blue: 0.0) // #FF9500
    static let primaryButtonEnd = Color(red: 1.0, green: 0.23, blue: 0.19)  // #FF3B30

    // MARK: - Gradient colors for buttons
    static let buttonGradientStart = primaryOrange
    static let buttonGradientEnd = primaryRed

    // MARK: - Recurring expenses button colors
    static let recurringButtonStart = Color(red: 0.12, green: 0.76, blue: 0.99) // #1EC3FC
    static let recurringButtonEnd = Color(red: 0.01, green: 0.67, blue: 0.89)   // #03AAE4

    // MARK: - Dialog background colors
    static let dialogBackgroundDark = Color(red: 0.12, green: 0.12, blue: 0.12) // #1E1E1E
    static let dialogBackgroundLight = Color.white                              // #FFFFFF
}

// MARK: - Convenience Extensions
extension AppColors {
    /// Primary gradient for buttons
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [buttonGradientStart, buttonGradientEnd],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// Recurring expenses gradient for buttons
    static var recurringGradient: LinearGradient {
        LinearGradient(
            colors: [recurringButtonStart, recurringButtonEnd],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}