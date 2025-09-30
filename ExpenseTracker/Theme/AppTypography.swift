//
//  AppTypography.swift
//  ExpenseTracker
//
//  Created by migration from Android Type.kt with enhanced typography system
//

import SwiftUI

/// AppTypography provides a comprehensive typography system for the app
struct AppTypography {

    // MARK: - Font Families

    /// Default system font family
    static let systemFont: Font = .system(size: 16, weight: .regular, design: .default)

    /// Rounded system font family for friendly UI elements
    static let roundedFont: Font = .system(size: 16, weight: .regular, design: .rounded)

    /// Monospaced font for numbers and amounts
    static let monospaceFont: Font = .system(size: 16, weight: .regular, design: .monospaced)

    // MARK: - Display Text Styles

    /// Large display text - for main headings
    static let displayLarge: Font = .system(size: 57, weight: .regular, design: .default)

    /// Medium display text - for section headings
    static let displayMedium: Font = .system(size: 45, weight: .regular, design: .default)

    /// Small display text - for subsection headings
    static let displaySmall: Font = .system(size: 36, weight: .regular, design: .default)

    // MARK: - Headline Text Styles

    /// Large headline - for screen titles
    static let headlineLarge: Font = .system(size: 32, weight: .regular, design: .default)

    /// Medium headline - for card titles
    static let headlineMedium: Font = .system(size: 28, weight: .regular, design: .default)

    /// Small headline - for list section headers
    static let headlineSmall: Font = .system(size: 24, weight: .regular, design: .default)

    // MARK: - Title Text Styles

    /// Large title - for dialog titles
    static let titleLarge: Font = .system(size: 22, weight: .regular, design: .default)

    /// Medium title - for card headers
    static let titleMedium: Font = .system(size: 16, weight: .medium, design: .default)

    /// Small title - for list item titles
    static let titleSmall: Font = .system(size: 14, weight: .medium, design: .default)

    // MARK: - Body Text Styles

    /// Large body text - for main content
    static let bodyLarge: Font = .system(size: 16, weight: .regular, design: .default)

    /// Medium body text - for secondary content
    static let bodyMedium: Font = .system(size: 14, weight: .regular, design: .default)

    /// Small body text - for captions and hints
    static let bodySmall: Font = .system(size: 12, weight: .regular, design: .default)

    // MARK: - Label Text Styles

    /// Large label - for button text
    static let labelLarge: Font = .system(size: 14, weight: .medium, design: .default)

    /// Medium label - for input labels
    static let labelMedium: Font = .system(size: 12, weight: .medium, design: .default)

    /// Small label - for tags and badges
    static let labelSmall: Font = .system(size: 11, weight: .medium, design: .default)

    // MARK: - Specialized Fonts for App

    /// Amount display font - optimized for currency amounts
    static let amountLarge: Font = .system(size: 24, weight: .bold, design: .rounded)

    /// Amount display font - for list items
    static let amountMedium: Font = .system(size: 18, weight: .semibold, design: .rounded)

    /// Amount display font - for small amounts
    static let amountSmall: Font = .system(size: 14, weight: .medium, design: .rounded)

    /// Currency symbol font
    static let currency: Font = .system(size: 16, weight: .medium, design: .rounded)

    /// Date display font
    static let date: Font = .system(size: 14, weight: .regular, design: .monospaced)

    /// Category label font
    static let category: Font = .system(size: 12, weight: .medium, design: .rounded)

    /// Button text font
    static let button: Font = .system(size: 16, weight: .semibold, design: .default)

    /// Input field font
    static let input: Font = .system(size: 16, weight: .regular, design: .default)

    /// Tab bar font
    static let tabBar: Font = .system(size: 12, weight: .medium, design: .default)

    /// Navigation title font
    static let navigationTitle: Font = .system(size: 20, weight: .semibold, design: .default)
}

// MARK: - Text Style Extensions

extension Text {

    // MARK: - Display Styles

    /// Apply display large typography
    func displayLarge() -> Text {
        self.font(AppTypography.displayLarge)
    }

    /// Apply display medium typography
    func displayMedium() -> Text {
        self.font(AppTypography.displayMedium)
    }

    /// Apply display small typography
    func displaySmall() -> Text {
        self.font(AppTypography.displaySmall)
    }

    // MARK: - Headline Styles

    /// Apply headline large typography
    func headlineLarge() -> Text {
        self.font(AppTypography.headlineLarge)
    }

    /// Apply headline medium typography
    func headlineMedium() -> Text {
        self.font(AppTypography.headlineMedium)
    }

    /// Apply headline small typography
    func headlineSmall() -> Text {
        self.font(AppTypography.headlineSmall)
    }

    // MARK: - Title Styles

    /// Apply title large typography
    func titleLarge() -> Text {
        self.font(AppTypography.titleLarge)
    }

    /// Apply title medium typography
    func titleMedium() -> Text {
        self.font(AppTypography.titleMedium)
    }

    /// Apply title small typography
    func titleSmall() -> Text {
        self.font(AppTypography.titleSmall)
    }

    // MARK: - Body Styles

    /// Apply body large typography
    func bodyLarge() -> Text {
        self.font(AppTypography.bodyLarge)
    }

    /// Apply body medium typography
    func bodyMedium() -> Text {
        self.font(AppTypography.bodyMedium)
    }

    /// Apply body small typography
    func bodySmall() -> Text {
        self.font(AppTypography.bodySmall)
    }

    // MARK: - Label Styles

    /// Apply label large typography
    func labelLarge() -> Text {
        self.font(AppTypography.labelLarge)
    }

    /// Apply label medium typography
    func labelMedium() -> Text {
        self.font(AppTypography.labelMedium)
    }

    /// Apply label small typography
    func labelSmall() -> Text {
        self.font(AppTypography.labelSmall)
    }

    // MARK: - Specialized App Styles

    /// Apply amount large typography
    func amountLarge() -> Text {
        self.font(AppTypography.amountLarge)
    }

    /// Apply amount medium typography
    func amountMedium() -> Text {
        self.font(AppTypography.amountMedium)
    }

    /// Apply amount small typography
    func amountSmall() -> Text {
        self.font(AppTypography.amountSmall)
    }

    /// Apply currency typography
    func currency() -> Text {
        self.font(AppTypography.currency)
    }

    /// Apply date typography
    func date() -> Text {
        self.font(AppTypography.date)
    }

    /// Apply category typography
    func category() -> Text {
        self.font(AppTypography.category)
    }

    /// Apply button typography
    func button() -> Text {
        self.font(AppTypography.button)
    }

    /// Apply input typography
    func input() -> Text {
        self.font(AppTypography.input)
    }

    /// Apply tab bar typography
    func tabBar() -> Text {
        self.font(AppTypography.tabBar)
    }

    /// Apply navigation title typography
    func navigationTitle() -> Text {
        self.font(AppTypography.navigationTitle)
    }
}

// MARK: - Font Weight Extensions

extension AppTypography {

    /// Font weights used throughout the app
    struct Weight {
        static let thin: Font.Weight = .thin
        static let ultraLight: Font.Weight = .ultraLight
        static let light: Font.Weight = .light
        static let regular: Font.Weight = .regular
        static let medium: Font.Weight = .medium
        static let semibold: Font.Weight = .semibold
        static let bold: Font.Weight = .bold
        static let heavy: Font.Weight = .heavy
        static let black: Font.Weight = .black
    }

    /// Font designs used throughout the app
    struct Design {
        static let `default`: Font.Design = .default
        static let rounded: Font.Design = .rounded
        static let monospaced: Font.Design = .monospaced
        static let serif: Font.Design = .serif
    }
}

// MARK: - Dynamic Type Support

extension AppTypography {

    /// Create font with dynamic type support
    /// - Parameters:
    ///   - size: Base font size
    ///   - weight: Font weight
    ///   - design: Font design
    /// - Returns: Font with dynamic type scaling
    static func dynamicFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        return .system(size: size, weight: weight, design: design)
    }

    /// Create custom font with fallback to system font
    /// - Parameters:
    ///   - name: Custom font name
    ///   - size: Font size
    ///   - weight: Fallback font weight
    /// - Returns: Custom font or system font fallback
    static func customFont(name: String, size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return .custom(name, size: size, relativeTo: .body)
    }
}

// MARK: - Line Height and Letter Spacing Support

extension Text {

    

    /// Apply custom letter spacing (tracking)
    /// - Parameter spacing: Letter spacing value
    /// - Returns: Text with custom letter spacing
    func letterSpacing(_ spacing: CGFloat) -> some View {
        self.tracking(spacing)
    }
}
