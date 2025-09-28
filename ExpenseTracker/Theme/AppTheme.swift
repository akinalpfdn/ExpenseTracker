//
//  AppTheme.swift
//  ExpenseTracker
//
//  Created by migration from Android Theme.kt with enhanced theme management
//

import SwiftUI
import Foundation

/// AppTheme provides centralized theme management for the entire app
class AppTheme: ObservableObject {

    /// Shared theme manager instance
    static let shared = AppTheme()

    /// Current theme mode (true = dark, false = light)
    @Published var isDarkMode: Bool = true {
        didSet {
            saveThemePreference()
        }
    }

    /// Whether to use system theme (auto dark/light based on system)
    @Published var useSystemTheme: Bool = false {
        didSet {
            saveThemePreference()
            if useSystemTheme {
                updateThemeFromSystem()
            }
        }
    }

    /// Whether to use dynamic colors (iOS 14+ adaptable colors)
    @Published var useDynamicColors: Bool = false {
        didSet {
            saveThemePreference()
        }
    }

    private init() {
        loadThemePreference()
        if useSystemTheme {
            updateThemeFromSystem()
        }
    }

    // MARK: - Theme Persistence

    private func saveThemePreference() {
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        UserDefaults.standard.set(useSystemTheme, forKey: "useSystemTheme")
        UserDefaults.standard.set(useDynamicColors, forKey: "useDynamicColors")
    }

    private func loadThemePreference() {
        isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        useSystemTheme = UserDefaults.standard.bool(forKey: "useSystemTheme")
        useDynamicColors = UserDefaults.standard.bool(forKey: "useDynamicColors")

        // Default to dark mode if no preference exists
        if UserDefaults.standard.object(forKey: "isDarkMode") == nil {
            isDarkMode = true
        }
    }

    // MARK: - System Theme Detection

    private func updateThemeFromSystem() {
        if useSystemTheme {
            // This will be properly implemented when we integrate with SwiftUI environment
            isDarkMode = true // Default to dark for now
        }
    }

    /// Update theme based on system appearance
    /// - Parameter colorScheme: Current system color scheme
    func updateFromSystemColorScheme(_ colorScheme: ColorScheme) {
        if useSystemTheme {
            isDarkMode = (colorScheme == .dark)
        }
    }

    // MARK: - Theme Switching

    /// Toggle between dark and light mode
    func toggleTheme() {
        isDarkMode.toggle()
        useSystemTheme = false
    }

    /// Set specific theme mode
    /// - Parameter dark: Whether to use dark mode
    func setTheme(dark: Bool) {
        isDarkMode = dark
        useSystemTheme = false
    }

    /// Enable system theme following
    func enableSystemTheme() {
        useSystemTheme = true
    }

    /// Disable system theme following
    func disableSystemTheme() {
        useSystemTheme = false
    }
}

// MARK: - Theme Color Getters

extension AppTheme {

    // MARK: - Background Colors

    var backgroundColor: Color {
        ThemeColors.backgroundColor(isDarkTheme: isDarkMode)
    }

    var cardBackgroundColor: Color {
        ThemeColors.cardBackgroundColor(isDarkTheme: isDarkMode)
    }

    var dialogBackgroundColor: Color {
        ThemeColors.dialogBackgroundColor(isDarkTheme: isDarkMode)
    }

    // MARK: - Text Colors

    var textColor: Color {
        ThemeColors.textColor(isDarkTheme: isDarkMode)
    }

    var textGrayColor: Color {
        ThemeColors.textGrayColor(isDarkTheme: isDarkMode)
    }

    // MARK: - Input Colors

    var inputBackgroundColor: Color {
        ThemeColors.inputBackgroundColor(isDarkTheme: isDarkMode)
    }

    var inputBackgroundFocusedColor: Color {
        ThemeColors.inputBackgroundFocusedColor(isDarkTheme: isDarkMode)
    }

    // MARK: - Button Colors

    var buttonDisabledColor: Color {
        ThemeColors.buttonDisabledColor(isDarkTheme: isDarkMode)
    }

    // MARK: - Status Colors

    var deleteRedColor: Color {
        ThemeColors.deleteRedColor(isDarkTheme: isDarkMode)
    }

    var successGreenColor: Color {
        ThemeColors.successGreenColor(isDarkTheme: isDarkMode)
    }

    // MARK: - Static Colors (theme-independent)

    var primaryOrange: Color {
        ThemeColors.Static.primaryOrange
    }

    var primaryRed: Color {
        ThemeColors.Static.primaryRed
    }

    var primaryButtonGradient: LinearGradient {
        ThemeColors.Static.primaryButtonGradient
    }

    var recurringButtonGradient: LinearGradient {
        ThemeColors.Static.recurringButtonGradient
    }

    var buttonGradient: LinearGradient {
        ThemeColors.Static.buttonGradient
    }
}

// MARK: - Theme Typography Getters

extension AppTheme {

    // MARK: - Display Typography

    var displayLarge: Font { AppTypography.displayLarge }
    var displayMedium: Font { AppTypography.displayMedium }
    var displaySmall: Font { AppTypography.displaySmall }

    // MARK: - Headline Typography

    var headlineLarge: Font { AppTypography.headlineLarge }
    var headlineMedium: Font { AppTypography.headlineMedium }
    var headlineSmall: Font { AppTypography.headlineSmall }

    // MARK: - Title Typography

    var titleLarge: Font { AppTypography.titleLarge }
    var titleMedium: Font { AppTypography.titleMedium }
    var titleSmall: Font { AppTypography.titleSmall }

    // MARK: - Body Typography

    var bodyLarge: Font { AppTypography.bodyLarge }
    var bodyMedium: Font { AppTypography.bodyMedium }
    var bodySmall: Font { AppTypography.bodySmall }

    // MARK: - Label Typography

    var labelLarge: Font { AppTypography.labelLarge }
    var labelMedium: Font { AppTypography.labelMedium }
    var labelSmall: Font { AppTypography.labelSmall }

    // MARK: - Specialized Typography

    var amountLarge: Font { AppTypography.amountLarge }
    var amountMedium: Font { AppTypography.amountMedium }
    var amountSmall: Font { AppTypography.amountSmall }
    var currency: Font { AppTypography.currency }
    var date: Font { AppTypography.date }
    var category: Font { AppTypography.category }
    var button: Font { AppTypography.button }
    var input: Font { AppTypography.input }
    var tabBar: Font { AppTypography.tabBar }
    var navigationTitle: Font { AppTypography.navigationTitle }
}

// MARK: - SwiftUI Environment Integration

/// Environment key for theme manager
struct AppThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = AppTheme.shared
}

extension EnvironmentValues {
    /// Current app theme manager
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

// MARK: - View Extensions for Theme Support

extension View {

    /// Apply theme manager to view hierarchy
    /// - Parameter theme: Theme manager instance
    /// - Returns: View with theme manager applied
    func appTheme(_ theme: AppTheme = AppTheme.shared) -> some View {
        environment(\.appTheme, theme)
            .environment(\.isDarkTheme, theme.isDarkMode)
            .environmentObject(theme)
    }

    /// Apply theme-aware color scheme
    /// - Parameter theme: Theme manager instance
    /// - Returns: View with proper color scheme applied
    func themeColorScheme(_ theme: AppTheme = AppTheme.shared) -> some View {
        preferredColorScheme(theme.isDarkMode ? .dark : .light)
    }

    /// Apply complete theme configuration
    /// - Parameter theme: Theme manager instance
    /// - Returns: View with complete theme applied
    func themed(_ theme: AppTheme = AppTheme.shared) -> some View {
        self
            .appTheme(theme)
            .themeColorScheme(theme)
            .background(theme.backgroundColor.ignoresSafeArea())
    }
}

// MARK: - Theme Helper Functions

extension AppTheme {

    /// Get theme-appropriate color for any UI element
    /// - Parameters:
    ///   - lightColor: Color to use in light mode
    ///   - darkColor: Color to use in dark mode
    /// - Returns: Appropriate color for current theme
    func color(light lightColor: Color, dark darkColor: Color) -> Color {
        return isDarkMode ? darkColor : lightColor
    }

    /// Get theme-appropriate font for any UI element
    /// - Parameters:
    ///   - lightFont: Font to use in light mode
    ///   - darkFont: Font to use in dark mode
    /// - Returns: Appropriate font for current theme
    func font(light lightFont: Font, dark darkFont: Font) -> Font {
        return isDarkMode ? darkFont : lightFont
    }

    /// Get opacity value based on theme
    /// - Parameters:
    ///   - lightOpacity: Opacity for light mode
    ///   - darkOpacity: Opacity for dark mode
    /// - Returns: Appropriate opacity for current theme
    func opacity(light lightOpacity: Double, dark darkOpacity: Double) -> Double {
        return isDarkMode ? darkOpacity : lightOpacity
    }
}

// MARK: - Theme Presets

extension AppTheme {

    /// Available theme presets
    enum Preset {
        case darkMode
        case lightMode
        case systemAutomatic
        case highContrast
        case accessibilityLarge
    }

    /// Apply theme preset
    /// - Parameter preset: Theme preset to apply
    func applyPreset(_ preset: Preset) {
        switch preset {
        case .darkMode:
            isDarkMode = true
            useSystemTheme = false
            useDynamicColors = false

        case .lightMode:
            isDarkMode = false
            useSystemTheme = false
            useDynamicColors = false

        case .systemAutomatic:
            useSystemTheme = true
            useDynamicColors = false
            updateThemeFromSystem()

        case .highContrast:
            isDarkMode = true
            useSystemTheme = false
            useDynamicColors = false
            // Additional high contrast settings can be added here

        case .accessibilityLarge:
            isDarkMode = true
            useSystemTheme = false
            useDynamicColors = false
            // Additional accessibility settings can be added here
        }
    }
}

// MARK: - Theme Animation Support

extension AppTheme {

    /// Animate theme changes
    /// - Parameters:
    ///   - duration: Animation duration
    ///   - curve: Animation curve
    ///   - action: Theme change action
    func animateThemeChange(
        duration: Double = 0.3,
        curve: Animation = .easeInOut,
        action: @escaping () -> Void
    ) {
        withAnimation(.easeInOut(duration: duration)) {
            action()
        }
    }
}