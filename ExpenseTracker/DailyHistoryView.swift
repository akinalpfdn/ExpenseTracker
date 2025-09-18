//
//  DailyHistoryView.swift
//  ExpenseTracker
//
//  Created by Akinalp Fidan on 11.08.2025.
//  Updated by Claude on 17.09.2024.
//

import SwiftUI

/// Enhanced daily history component showing weekly calendar with expense progress
/// Integrates with theme system and provides comprehensive daily expense visualization
struct DailyHistoryView: View {

    // MARK: - Properties

    let dailyData: [DailyData]
    let selectedDate: Date
    let onDateSelected: (Date) -> Void
    let onDayLongPress: ((DailyData) -> Void)?
    let showMonthTransition: Bool
    let compactMode: Bool
    let showSavingsIndicator: Bool

    @Environment(\.colorScheme) private var colorScheme
    @State private var scrollPosition: Int = 0
    @State private var showingDayDetails = false
    @State private var selectedDayData: DailyData?

    // MARK: - Initialization

    init(
        dailyData: [DailyData],
        selectedDate: Date,
        onDateSelected: @escaping (Date) -> Void,
        onDayLongPress: ((DailyData) -> Void)? = nil,
        showMonthTransition: Bool = false,
        compactMode: Bool = false,
        showSavingsIndicator: Bool = true
    ) {
        self.dailyData = dailyData
        self.selectedDate = selectedDate
        self.onDateSelected = onDateSelected
        self.onDayLongPress = onDayLongPress
        self.showMonthTransition = showMonthTransition
        self.compactMode = compactMode
        self.showSavingsIndicator = showSavingsIndicator
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: compactMode ? 8 : 12) {
            if showMonthTransition {
                monthHeader
            }

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: compactMode ? 8 : 12) {
                        ForEach(Array(dailyData.enumerated()), id: \.element.id) { index, dayData in
                            DailyHistoryItemView(
                                dayData: dayData,
                                isSelected: Calendar.current.isDate(dayData.date, inSameDayAs: selectedDate),
                                compactMode: compactMode,
                                showSavingsIndicator: showSavingsIndicator,
                                onTap: {
                                    onDateSelected(dayData.date)
                                },
                                onLongPress: {
                                    if let onDayLongPress = onDayLongPress {
                                        onDayLongPress(dayData)
                                    } else {
                                        selectedDayData = dayData
                                        showingDayDetails = true
                                    }
                                }
                            )
                            .id(index)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .onAppear {
                    scrollToSelectedDate(proxy: proxy)
                }
                .onChange(of: selectedDate) { _ in
                    scrollToSelectedDate(proxy: proxy)
                }
            }

            if !compactMode {
                selectedDayInfo
            }
        }
        .sheet(isPresented: $showingDayDetails) {
            if let dayData = selectedDayData {
                DayDetailsSheet(dayData: dayData)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L("daily_history_accessibility_label"))
    }

    // MARK: - View Components

    @ViewBuilder
    private var monthHeader: some View {
        HStack {
            Text(monthYearString)
                .font(.title2.bold())
                .foregroundColor(ThemeColors.textColor(for: colorScheme))

            Spacer()

            if !compactMode {
                HStack(spacing: 4) {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    Text(L("under_budget"))
                        .font(.caption2)
                        .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

                    Circle()
                        .fill(.orange)
                        .frame(width: 8, height: 8)
                    Text(L("over_budget"))
                        .font(.caption2)
                        .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                }
            }
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var selectedDayInfo: some View {
        if let selectedDayData = dailyData.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) {
            VStack(spacing: 8) {
                HStack {
                    Text(selectedDayData.fullDateString)
                        .font(.subheadline.bold())
                        .foregroundColor(ThemeColors.textColor(for: colorScheme))

                    Spacer()

                    if selectedDayData.isOverLimit {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                            Text(L("over_budget"))
                                .font(.caption.bold())
                                .foregroundColor(.red)
                        }
                    }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L("spent"))
                            .font(.caption)
                            .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                        Text(formatCurrency(selectedDayData.totalAmount))
                            .font(.subheadline.bold())
                            .foregroundColor(ThemeColors.textColor(for: colorScheme))
                    }

                    Spacer()

                    VStack(alignment: .center, spacing: 2) {
                        Text(L("expenses"))
                            .font(.caption)
                            .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                        Text("\(selectedDayData.expenseCount)")
                            .font(.subheadline.bold())
                            .foregroundColor(ThemeColors.textColor(for: colorScheme))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(L("remaining"))
                            .font(.caption)
                            .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                        Text(formatCurrency(selectedDayData.remainingBudget))
                            .font(.subheadline.bold())
                            .foregroundColor(selectedDayData.isOverLimit ? .red : .green)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(ThemeColors.cardBackgroundColor(for: colorScheme))
            )
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Computed Properties

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }

    // MARK: - Methods

    private func scrollToSelectedDate(proxy: ScrollViewReader) {
        if let selectedIndex = dailyData.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) {
            withAnimation(.easeInOut(duration: 0.3)) {
                proxy.scrollTo(selectedIndex, anchor: .center)
            }
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TRY" // Should come from settings
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "₺\(Int(amount))"
    }
}

/// Enhanced daily history item with modern theming and additional features
struct DailyHistoryItemView: View {

    // MARK: - Properties

    let dayData: DailyData
    let isSelected: Bool
    let compactMode: Bool
    let showSavingsIndicator: Bool
    let onTap: () -> Void
    let onLongPress: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false

    // MARK: - Initialization

    init(
        dayData: DailyData,
        isSelected: Bool,
        compactMode: Bool = false,
        showSavingsIndicator: Bool = true,
        onTap: @escaping () -> Void,
        onLongPress: (() -> Void)? = nil
    ) {
        self.dayData = dayData
        self.isSelected = isSelected
        self.compactMode = compactMode
        self.showSavingsIndicator = showSavingsIndicator
        self.onTap = onTap
        self.onLongPress = onLongPress
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: compactMode ? 6 : 8) {
            // Day name
            Text(dayData.dayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

            // Progress ring with ProgressRingView
            ZStack {
                ProgressRingView(
                    progress: dayData.progressPercentage,
                    size: compactMode ? 32 : 40,
                    lineWidth: compactMode ? 2.5 : 3,
                    progressColors: dayData.progressColors,
                    backgroundColor: ThemeColors.cardBackgroundColor(for: colorScheme),
                    showPercentage: false,
                    animated: true
                )

                // Central indicator
                if dayData.expenseCount > 0 {
                    if compactMode {
                        Circle()
                            .fill(dayData.statusColor)
                            .frame(width: 4, height: 4)
                    } else {
                        Text("\(dayData.expenseCount)")
                            .font(.caption2.bold())
                            .foregroundColor(ThemeColors.textColor(for: colorScheme))
                    }
                }

                // Savings indicator
                if showSavingsIndicator && dayData.didMeetSavingsTarget && !compactMode {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                        .offset(x: 12, y: -12)
                }
            }

            // Day number
            Text(dayData.dayNumber)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(dayTextColor)

            // Amount (if not compact)
            if !compactMode && dayData.totalAmount > 0 {
                Text(formatCurrency(dayData.totalAmount))
                    .font(.caption2)
                    .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                    .lineLimit(1)
            }
        }
        .padding(.vertical, compactMode ? 6 : 8)
        .padding(.horizontal, compactMode ? 3 : 4)
        .background(backgroundView)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture {
            onLongPress?()
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(L("daily_item_accessibility_hint"))
    }

    // MARK: - View Components

    @ViewBuilder
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: compactMode ? 8 : 12)
            .fill(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: compactMode ? 8 : 12)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 0)
            )
            .shadow(
                color: .black.opacity(isSelected ? 0.15 : 0.05),
                radius: isSelected ? 3 : 1,
                x: 0,
                y: isSelected ? 2 : 1
            )
    }

    // MARK: - Computed Properties

    private var dayTextColor: Color {
        if isSelected {
            return ThemeColors.textColor(for: colorScheme)
        } else if dayData.isFuture {
            return ThemeColors.textGrayColor(for: colorScheme).opacity(0.5)
        } else {
            return ThemeColors.textGrayColor(for: colorScheme)
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return AppColors.primaryOrange.opacity(0.2)
        } else if dayData.isToday {
            return ThemeColors.cardBackgroundColor(for: colorScheme).opacity(0.8)
        } else {
            return Color.clear
        }
    }

    private var borderColor: Color {
        if isSelected {
            return AppColors.primaryOrange
        } else {
            return Color.clear
        }
    }

    private var accessibilityLabel: String {
        return L("day_accessibility_label", dayData.dayNumber, dayData.dayName)
    }

    private var accessibilityValue: String {
        var value = formatCurrency(dayData.totalAmount)
        if dayData.expenseCount > 0 {
            value += ", \(dayData.expenseCount) \(L("expenses"))"
        }
        if dayData.isOverLimit {
            value += ", \(L("over_budget"))"
        }
        return value
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TRY"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "₺\(Int(amount))"
    }
}

// MARK: - Day Details Sheet

/// Detailed view for a specific day's data
struct DayDetailsSheet: View {
    let dayData: DailyData

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with progress ring
                    VStack(spacing: 16) {
                        ProgressRingView.large(
                            progress: dayData.progressPercentage,
                            centerText: formatCurrency(dayData.totalAmount),
                            subtitle: L("of_daily_limit", formatCurrency(dayData.dailyLimit))
                        )

                        Text(dayData.fullDateString)
                            .font(.title2.bold())
                            .foregroundColor(ThemeColors.textColor(for: colorScheme))
                    }
                    .padding(.top, 20)

                    // Statistics grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        StatCard(
                            title: L("expenses"),
                            value: "\(dayData.expenseCount)",
                            icon: "list.number",
                            color: .blue
                        )

                        StatCard(
                            title: L("remaining_budget"),
                            value: formatCurrency(dayData.remainingBudget),
                            icon: dayData.isOverLimit ? "exclamationmark.triangle.fill" : "checkmark.circle.fill",
                            color: dayData.isOverLimit ? .red : .green
                        )

                        StatCard(
                            title: L("avg_expense"),
                            value: formatCurrency(dayData.averageExpenseAmount),
                            icon: "chart.bar.fill",
                            color: .orange
                        )

                        StatCard(
                            title: L("efficiency_score"),
                            value: "\(Int(dayData.efficiencyScore))%",
                            icon: "gauge.medium",
                            color: .purple
                        )
                    }

                    if let topCategory = dayData.topSpendingCategory {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(L("top_spending_category"))
                                .font(.headline)
                                .foregroundColor(ThemeColors.textColor(for: colorScheme))

                            Text(topCategory)
                                .font(.subheadline)
                                .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                        }
                    }

                    // Summary report
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L("daily_summary"))
                            .font(.headline)
                            .foregroundColor(ThemeColors.textColor(for: colorScheme))

                        Text(dayData.generateSummaryReport())
                            .font(.subheadline)
                            .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(ThemeColors.cardBackgroundColor(for: colorScheme))
                            )
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle(L("day_details"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("done")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TRY"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "₺\(Int(amount))"
    }
}

// MARK: - Stat Card Component

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title3.bold())
                .foregroundColor(ThemeColors.textColor(for: colorScheme))

            Text(title)
                .font(.caption)
                .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(ThemeColors.cardBackgroundColor(for: colorScheme))
        )
    }
}

// MARK: - Convenience Initializers

extension DailyHistoryView {
    /// Creates a compact daily history view
    static func compact(
        dailyData: [DailyData],
        selectedDate: Date,
        onDateSelected: @escaping (Date) -> Void
    ) -> DailyHistoryView {
        return DailyHistoryView(
            dailyData: dailyData,
            selectedDate: selectedDate,
            onDateSelected: onDateSelected,
            compactMode: true,
            showSavingsIndicator: false
        )
    }

    /// Creates a full-featured daily history view with month header
    static func withMonthHeader(
        dailyData: [DailyData],
        selectedDate: Date,
        onDateSelected: @escaping (Date) -> Void,
        onDayLongPress: @escaping (DailyData) -> Void
    ) -> DailyHistoryView {
        return DailyHistoryView(
            dailyData: dailyData,
            selectedDate: selectedDate,
            onDateSelected: onDateSelected,
            onDayLongPress: onDayLongPress,
            showMonthTransition: true
        )
    }
}

// MARK: - Preview Provider

#if DEBUG
struct DailyHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Normal view
                DailyHistoryView(
                    dailyData: DailyData.mockWeekData(),
                    selectedDate: Date(),
                    onDateSelected: { _ in }
                )

                // Compact view
                DailyHistoryView.compact(
                    dailyData: DailyData.mockWeekData(),
                    selectedDate: Date(),
                    onDateSelected: { _ in }
                )

                // With month header
                DailyHistoryView.withMonthHeader(
                    dailyData: DailyData.mockWeekData(),
                    selectedDate: Date(),
                    onDateSelected: { _ in },
                    onDayLongPress: { _ in }
                )
            }
            .padding()
        }
        .background(ThemeColors.backgroundColor(for: .dark))
        .preferredColorScheme(.dark)
        .previewDisplayName("Daily History Views")
    }
}

// MARK: - Mock Data

extension DailyData {
    static func mockWeekData() -> [DailyData] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) ?? today
            let isToday = dayOffset == 0
            return DailyData(
                date: date,
                totalAmount: isToday ? 75.0 : Double.random(in: 20...150),
                expenseCount: isToday ? 3 : Int.random(in: 0...8),
                dailyLimit: 100.0,
                isWorkingDay: !calendar.dateInterval(of: .weekOfYear, for: date)?.contains(date) ?? true,
                targetSavings: 25.0,
                actualSavings: isToday ? 25.0 : Double.random(in: 0...30)
            )
        }.reversed()
    }
}
#endif
