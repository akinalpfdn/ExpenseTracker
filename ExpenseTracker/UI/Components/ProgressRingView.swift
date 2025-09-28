//
//  ProgressRingView.swift
//  ExpenseTracker
//
//  Created by migration from Android ProgressRingComponent.kt
//

import SwiftUI

struct ProgressRingView: View {
    let progress: Double
    let isLimitOver: Bool
    let strokeWidth: CGFloat
    let onClick: (() -> Void)?

    @State private var animatedProgress: Double = 0

    init(
        progress: Double,
        isLimitOver: Bool = false,
        strokeWidth: CGFloat = 8,
        onClick: (() -> Void)? = nil
    ) {
        self.progress = progress
        self.isLimitOver = isLimitOver
        self.strokeWidth = strokeWidth
        self.onClick = onClick
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: strokeWidth)

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    progressGradient,
                    style: StrokeStyle(
                        lineWidth: strokeWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 1.5), value: animatedProgress)
        }
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { newValue in
            withAnimation(.easeOut(duration: 1.5)) {
                animatedProgress = newValue
            }
        }
        .onTapGesture {
            onClick?()
        }
    }

    private var progressGradient: AngularGradient {
        if isLimitOver {
            return AngularGradient(
                colors: [Color.red, Color.red],
                center: .center,
                startAngle: .degrees(0),
                endAngle: .degrees(360)
            )
        } else {
            return AngularGradient(
                colors: [
                    Color.green,
                    Color.green,
                    Color.yellow,
                    Color.yellow,
                    Color.red,
                    Color.red
                ],
                center: .center,
                startAngle: .degrees(0),
                endAngle: .degrees(360)
            )
        }
    }
}

struct MonthlyProgressRingView: View {
    let totalSpent: Double
    let progressPercentage: Double
    let isOverLimit: Bool
    let onTap: () -> Void
    let currency: String
    let isDarkTheme: Bool
    let month: String
    let selectedDate: Date

    init(
        totalSpent: Double,
        progressPercentage: Double,
        isOverLimit: Bool,
        onTap: @escaping () -> Void,
        currency: String = "₺",
        isDarkTheme: Bool = true,
        month: String = "",
        selectedDate: Date
    ) {
        self.totalSpent = totalSpent
        self.progressPercentage = progressPercentage
        self.isOverLimit = isOverLimit
        self.onTap = onTap
        self.currency = currency
        self.isDarkTheme = isDarkTheme
        self.month = month
        self.selectedDate = selectedDate
    }

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            ZStack {
                ProgressRingView(
                    progress: progressPercentage,
                    isLimitOver: isOverLimit,
                    strokeWidth: 8,
                    onClick: onTap
                )
                .frame(width: 140, height: 140)

                VStack(spacing: 4) {
                    Text("\(currency)\(NumberFormatter.formatAmount(totalSpent))")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(isOverLimit ? .red : ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

                    Text(month.isEmpty ? "monthly_label".localized : month)
                        .font(.system(size: 19))
                        .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                }
            }

            Text(formattedDate)
                .font(.system(size: 19))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy"
        formatter.locale = Locale.current
        return formatter.string(from: selectedDate)
    }
}

struct DailyProgressRingView: View {
    let dailyProgressPercentage: Double
    let isOverDailyLimit: Bool
    let selectedDateTotal: Double
    let currency: String
    let isDarkTheme: Bool

    init(
        dailyProgressPercentage: Double,
        isOverDailyLimit: Bool,
        selectedDateTotal: Double,
        currency: String = "₺",
        isDarkTheme: Bool = true
    ) {
        self.dailyProgressPercentage = dailyProgressPercentage
        self.isOverDailyLimit = isOverDailyLimit
        self.selectedDateTotal = selectedDateTotal
        self.currency = currency
        self.isDarkTheme = isDarkTheme
    }

    var body: some View {
        VStack(alignment: .center) {
            ZStack {
                ProgressRingView(
                    progress: dailyProgressPercentage,
                    isLimitOver: isOverDailyLimit,
                    strokeWidth: 8
                )
                .frame(width: 140, height: 140)

                VStack(spacing: 2) {
                    Text("\(currency)\(NumberFormatter.formatAmount(selectedDateTotal))")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(isOverDailyLimit ? .red : ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

                    Text("daily_label".localized)
                        .font(.system(size: 12))
                        .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                }
            }
        }
    }
}

// MARK: - NumberFormatter Extension

extension NumberFormatter {
    static func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
}

// MARK: - Preview

struct ProgressRingView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ProgressRingView(progress: 0.7, isLimitOver: false)
                .frame(width: 140, height: 140)

            MonthlyProgressRingView(
                totalSpent: 1250.75,
                progressPercentage: 0.75,
                isOverLimit: false,
                onTap: {},
                selectedDate: Date()
            )

            DailyProgressRingView(
                dailyProgressPercentage: 0.9,
                isOverDailyLimit: true,
                selectedDateTotal: 350.50
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
