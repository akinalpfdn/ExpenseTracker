//
//  ProgressRingView.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import SwiftUI

/// A customizable circular progress ring component that displays progress with gradient colors
/// Replaces Material Design CircularProgressIndicator with native SwiftUI implementation
/// Supports accessibility, animations, and multiple display modes
struct ProgressRingView: View {

    // MARK: - Properties

    /// Progress value (0.0 to 1.0)
    let progress: Double

    /// Ring thickness
    let lineWidth: CGFloat

    /// Ring diameter
    let size: CGFloat

    /// Progress colors (gradient if multiple colors provided)
    let progressColors: [Color]

    /// Background ring color
    let backgroundColor: Color

    /// Whether to show percentage text in center
    let showPercentage: Bool

    /// Custom text to display in center (overrides percentage)
    let centerText: String?

    /// Text color for center content
    let textColor: Color

    /// Whether to animate progress changes
    let animated: Bool

    /// Animation duration
    let animationDuration: Double

    /// Starting angle (0 degrees = top)
    let startAngle: Angle

    /// Whether the ring should be filled clockwise
    let clockwise: Bool

    /// Optional subtitle text below main text
    let subtitle: String?

    /// Text font for center content
    let font: Font

    /// Subtitle font
    let subtitleFont: Font

    // MARK: - Computed Properties

    /// Clamped progress value between 0 and 1
    private var clampedProgress: Double {
        max(0.0, min(1.0, progress))
    }

    /// Formatted percentage string
    private var percentageText: String {
        "\(Int(clampedProgress * 100))%"
    }

    /// Center text to display
    private var displayText: String {
        centerText ?? (showPercentage ? percentageText : "")
    }

    /// Progress gradient
    private var progressGradient: AngularGradient {
        AngularGradient(
            colors: progressColors.isEmpty ? [.blue] : progressColors,
            center: .center,
            startAngle: startAngle,
            endAngle: startAngle + .degrees(360)
        )
    }

    // MARK: - Initializers

    /// Creates a basic progress ring
    /// - Parameters:
    ///   - progress: Progress value (0.0 to 1.0)
    ///   - size: Ring diameter
    ///   - lineWidth: Ring thickness
    init(
        progress: Double,
        size: CGFloat = 120,
        lineWidth: CGFloat = 12
    ) {
        self.progress = progress
        self.size = size
        self.lineWidth = lineWidth
        self.progressColors = [AppColors.primaryOrange, AppColors.primaryRed]
        self.backgroundColor = Color.gray.opacity(0.3)
        self.showPercentage = true
        self.centerText = nil
        self.textColor = .primary
        self.animated = true
        self.animationDuration = 0.8
        self.startAngle = .degrees(-90)
        self.clockwise = true
        self.subtitle = nil
        self.font = .title2.bold()
        self.subtitleFont = .caption
    }

    /// Creates a fully customizable progress ring
    /// - Parameters:
    ///   - progress: Progress value (0.0 to 1.0)
    ///   - size: Ring diameter
    ///   - lineWidth: Ring thickness
    ///   - progressColors: Colors for progress gradient
    ///   - backgroundColor: Background ring color
    ///   - showPercentage: Whether to show percentage in center
    ///   - centerText: Custom center text (overrides percentage)
    ///   - textColor: Color for center text
    ///   - animated: Whether to animate progress changes
    ///   - animationDuration: Animation duration in seconds
    ///   - startAngle: Starting angle for progress
    ///   - clockwise: Direction of progress fill
    ///   - subtitle: Optional subtitle text
    ///   - font: Font for main center text
    ///   - subtitleFont: Font for subtitle
    init(
        progress: Double,
        size: CGFloat = 120,
        lineWidth: CGFloat = 12,
        progressColors: [Color] = [AppColors.primaryOrange, AppColors.primaryRed],
        backgroundColor: Color = Color.gray.opacity(0.3),
        showPercentage: Bool = true,
        centerText: String? = nil,
        textColor: Color = .primary,
        animated: Bool = true,
        animationDuration: Double = 0.8,
        startAngle: Angle = .degrees(-90),
        clockwise: Bool = true,
        subtitle: String? = nil,
        font: Font = .title2.bold(),
        subtitleFont: Font = .caption
    ) {
        self.progress = progress
        self.size = size
        self.lineWidth = lineWidth
        self.progressColors = progressColors
        self.backgroundColor = backgroundColor
        self.showPercentage = showPercentage
        self.centerText = centerText
        self.textColor = textColor
        self.animated = animated
        self.animationDuration = animationDuration
        self.startAngle = startAngle
        self.clockwise = clockwise
        self.subtitle = subtitle
        self.font = font
        self.subtitleFont = subtitleFont
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)
                .frame(width: size, height: size)

            // Progress ring
            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(
                    progressGradient,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .frame(width: size, height: size)
                .rotationEffect(startAngle)
                .scaleEffect(x: clockwise ? 1 : -1, y: 1)
                .animation(
                    animated ? .easeInOut(duration: animationDuration) : .none,
                    value: clampedProgress
                )

            // Center content
            if showPercentage || centerText != nil || subtitle != nil {
                VStack(spacing: 2) {
                    if !displayText.isEmpty {
                        Text(displayText)
                            .font(font)
                            .foregroundColor(textColor)
                            .multilineTextAlignment(.center)
                    }

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(subtitleFont)
                            .foregroundColor(textColor.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(width: size * 0.6) // Limit text width to fit inside ring
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        if let centerText = centerText {
            return "\(L("progress_ring")) \(centerText)"
        } else if showPercentage {
            return L("progress_ring_percentage")
        } else {
            return L("progress_ring")
        }
    }

    private var accessibilityValue: String {
        let percentage = Int(clampedProgress * 100)
        return L("percentage_value", percentage)
    }
}

// MARK: - Convenience Initializers

extension ProgressRingView {

    /// Creates a progress ring with app theme colors
    /// - Parameters:
    ///   - progress: Progress value (0.0 to 1.0)
    ///   - size: Ring diameter
    ///   - colorScheme: Current color scheme for theming
    static func themed(
        progress: Double,
        size: CGFloat = 120,
        colorScheme: ColorScheme = .dark
    ) -> ProgressRingView {
        return ProgressRingView(
            progress: progress,
            size: size,
            lineWidth: 12,
            progressColors: [AppColors.primaryOrange, AppColors.primaryRed],
            backgroundColor: ThemeColors.cardBackgroundColor(for: colorScheme),
            textColor: ThemeColors.textColor(for: colorScheme)
        )
    }

    /// Creates a small progress ring for list items
    /// - Parameters:
    ///   - progress: Progress value (0.0 to 1.0)
    ///   - colors: Optional custom colors
    static func compact(
        progress: Double,
        colors: [Color]? = nil
    ) -> ProgressRingView {
        return ProgressRingView(
            progress: progress,
            size: 40,
            lineWidth: 4,
            progressColors: colors ?? [AppColors.primaryOrange, AppColors.primaryRed],
            showPercentage: false,
            font: .caption.bold(),
            subtitleFont: .caption2
        )
    }

    /// Creates a large progress ring for dashboards
    /// - Parameters:
    ///   - progress: Progress value (0.0 to 1.0)
    ///   - centerText: Custom center text
    ///   - subtitle: Optional subtitle
    static func large(
        progress: Double,
        centerText: String? = nil,
        subtitle: String? = nil
    ) -> ProgressRingView {
        return ProgressRingView(
            progress: progress,
            size: 200,
            lineWidth: 20,
            progressColors: [AppColors.primaryOrange, AppColors.primaryRed],
            centerText: centerText,
            subtitle: subtitle,
            font: .largeTitle.bold(),
            subtitleFont: .subheadline
        )
    }

    /// Creates a budget progress ring with appropriate colors
    /// - Parameters:
    ///   - progress: Progress value (0.0 to 1.0)
    ///   - isOverBudget: Whether budget is exceeded
    ///   - size: Ring diameter
    static func budget(
        progress: Double,
        isOverBudget: Bool = false,
        size: CGFloat = 120
    ) -> ProgressRingView {
        let colors: [Color] = {
            if isOverBudget {
                return [.red, .red]
            } else if progress < 0.5 {
                return [.green, .green]
            } else if progress < 0.8 {
                return [.green, .yellow]
            } else {
                return [.yellow, .orange]
            }
        }()

        return ProgressRingView(
            progress: progress,
            size: size,
            progressColors: colors
        )
    }

    /// Creates a savings goal progress ring
    /// - Parameters:
    ///   - progress: Progress value (0.0 to 1.0)
    ///   - amount: Current saved amount
    ///   - goal: Target goal amount
    ///   - currency: Currency symbol
    static func savingsGoal(
        progress: Double,
        amount: Double,
        goal: Double,
        currency: String = "TRY"
    ) -> ProgressRingView {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0

        let amountText = formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"
        let goalText = formatter.string(from: NSNumber(value: goal)) ?? "\(Int(goal))"

        return ProgressRingView(
            progress: progress,
            size: 160,
            lineWidth: 16,
            progressColors: [AppColors.successGreen, .green],
            centerText: amountText,
            subtitle: L("of_goal", goalText),
            font: .title.bold(),
            subtitleFont: .footnote
        )
    }
}

// MARK: - Preview Provider

#if DEBUG
struct ProgressRingView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Basic progress ring
                VStack {
                    Text("Basic Progress Ring")
                        .font(.headline)
                    ProgressRingView(progress: 0.7)
                }

                // Different sizes
                HStack(spacing: 20) {
                    ProgressRingView.compact(progress: 0.3)
                    ProgressRingView(progress: 0.6, size: 80)
                    ProgressRingView.large(progress: 0.9, centerText: "900", subtitle: "Points")
                }

                // Budget variations
                HStack(spacing: 20) {
                    VStack {
                        Text("Under Budget")
                            .font(.caption)
                        ProgressRingView.budget(progress: 0.4, size: 80)
                    }

                    VStack {
                        Text("Near Limit")
                            .font(.caption)
                        ProgressRingView.budget(progress: 0.85, size: 80)
                    }

                    VStack {
                        Text("Over Budget")
                            .font(.caption)
                        ProgressRingView.budget(progress: 1.2, isOverBudget: true, size: 80)
                    }
                }

                // Savings goal
                ProgressRingView.savingsGoal(
                    progress: 0.65,
                    amount: 6500,
                    goal: 10000
                )

                // Custom colors and text
                ProgressRingView(
                    progress: 0.8,
                    progressColors: [.purple, .pink, .orange],
                    centerText: "80",
                    subtitle: "Health Score",
                    font: .largeTitle.bold()
                )
            }
            .padding()
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
        .previewDisplayName("Progress Ring Components")
    }
}
#endif