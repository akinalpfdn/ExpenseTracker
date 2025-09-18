//
//  AppTheme.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import SwiftUI

// MARK: - Theme Manager
class AppTheme: ObservableObject {
    @Published var isDarkMode: Bool = false

    static let shared = AppTheme()

    private init() {
        // Initialize with system preference
        isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
    }

    /// Toggle between light and dark themes
    func toggleTheme() {
        isDarkMode.toggle()
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
    }

    /// Set theme explicitly
    func setTheme(_ isDark: Bool) {
        isDarkMode = isDark
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
    }

    /// Load theme preference from UserDefaults
    func loadThemePreference() {
        if UserDefaults.standard.object(forKey: "isDarkMode") != nil {
            isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        }
    }

    /// Get current color scheme
    var colorScheme: ColorScheme {
        isDarkMode ? .dark : .light
    }
}

// MARK: - Theme Environment Key
struct AppThemeKey: EnvironmentKey {
    static let defaultValue = AppTheme.shared
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

// MARK: - Theme Provider View Modifier
struct ThemeProviderModifier: ViewModifier {
    @StateObject private var theme = AppTheme.shared

    func body(content: Content) -> some View {
        content
            .environment(\.appTheme, theme)
            .preferredColorScheme(theme.isDarkMode ? .dark : .light)
            .onAppear {
                theme.loadThemePreference()
            }
    }
}

extension View {
    /// Apply app theme to the view hierarchy
    func withAppTheme() -> some View {
        modifier(ThemeProviderModifier())
    }
}

// MARK: - Themed Color Extensions
extension Color {
    /// Get themed background color
    static func themedBackground(_ colorScheme: ColorScheme) -> Color {
        ThemeColors.backgroundColor(for: colorScheme)
    }

    /// Get themed text color
    static func themedText(_ colorScheme: ColorScheme) -> Color {
        ThemeColors.textColor(for: colorScheme)
    }

    /// Get themed secondary text color
    static func themedSecondaryText(_ colorScheme: ColorScheme) -> Color {
        ThemeColors.textGrayColor(for: colorScheme)
    }

    /// Get themed card background color
    static func themedCardBackground(_ colorScheme: ColorScheme) -> Color {
        ThemeColors.cardBackgroundColor(for: colorScheme)
    }

    /// Get themed input background color
    static func themedInputBackground(_ colorScheme: ColorScheme) -> Color {
        ThemeColors.inputBackgroundColor(for: colorScheme)
    }

    /// Get themed focused input background color
    static func themedInputBackgroundFocused(_ colorScheme: ColorScheme) -> Color {
        ThemeColors.inputBackgroundFocusedColor(for: colorScheme)
    }

    /// Get themed disabled button color
    static func themedButtonDisabled(_ colorScheme: ColorScheme) -> Color {
        ThemeColors.buttonDisabledColor(for: colorScheme)
    }

    /// Get themed delete color
    static func themedDeleteRed(_ colorScheme: ColorScheme) -> Color {
        ThemeColors.deleteRedColor(for: colorScheme)
    }

    /// Get themed success color
    static func themedSuccessGreen(_ colorScheme: ColorScheme) -> Color {
        ThemeColors.successGreenColor(for: colorScheme)
    }

    /// Get themed dialog background color
    static func themedDialogBackground(_ colorScheme: ColorScheme) -> Color {
        ThemeColors.dialogBackgroundColor(for: colorScheme)
    }
}

// MARK: - Convenience View Extensions
extension View {
    /// Apply themed background to view
    func themedBackground() -> some View {
        self.modifier(ThemedBackgroundModifier())
    }

    /// Apply themed card background to view
    func themedCardBackground() -> some View {
        self.modifier(ThemedCardBackgroundModifier())
    }

    /// Apply themed text color to view
    func themedTextColor() -> some View {
        self.modifier(ThemedTextColorModifier())
    }

    /// Apply themed secondary text color to view
    func themedSecondaryTextColor() -> some View {
        self.modifier(ThemedSecondaryTextColorModifier())
    }
}

// MARK: - Theme View Modifiers
struct ThemedBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .background(Color.themedBackground(colorScheme))
    }
}

struct ThemedCardBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .background(Color.themedCardBackground(colorScheme))
    }
}

struct ThemedTextColorModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .foregroundColor(Color.themedText(colorScheme))
    }
}

struct ThemedSecondaryTextColorModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .foregroundColor(Color.themedSecondaryText(colorScheme))
    }
}