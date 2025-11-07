//
//  ColorExtensions.swift
//  ExpenseTracker
//
//  Color utility extensions
//

import SwiftUI

extension Color {
    /// Lightens the color by reducing saturation and increasing brightness
    /// - Parameter amount: Amount to lighten (0.0 to 1.0)
    /// - Returns: Lightened color
    func lighten(by amount: CGFloat = 0.3) -> Color {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        #if os(iOS)
        UIColor(self).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        #elseif os(macOS)
        NSColor(self).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        #endif

        return Color(
            hue: hue,
            saturation: max(0, saturation - amount),
            brightness: min(1, brightness + amount)
        )
    }

    /// Darkens the color by increasing saturation and decreasing brightness
    /// - Parameter amount: Amount to darken (0.0 to 1.0)
    /// - Returns: Darkened color
    func darken(by amount: CGFloat = 0.3) -> Color {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        #if os(iOS)
        UIColor(self).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        #elseif os(macOS)
        NSColor(self).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        #endif

        return Color(
            hue: hue,
            saturation: min(1, saturation + amount),
            brightness: max(0, brightness - amount)
        )
    }
}
