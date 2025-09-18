//
//  MonthlyCalendarView.swift
//  ExpenseTracker
//
//  Created by Akinalp Fidan on 11.08.2025.
//  Updated by Claude on 17.09.2024.
//

import SwiftUI

struct MonthlyCalendarView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var expenseViewModel: ExpenseViewModel

    let expenses: [Expense]
    let selectedDate: Date
    let onDateSelected: (Date) -> Void
    let onDismiss: () -> Void

    @State private var currentMonth = Date()
    @State private var showingDatePicker = false
    @State private var selectedDayExpenses: [Expense] = []
    @State private var showingDayDetail = false

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.locale = Locale.current
        return cal
    }
    
    private var monthData: [MonthlyDayData] {
        let startOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
        let endOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.end ?? currentMonth

        // Add padding days for complete weeks
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let paddingDaysBefore = (firstWeekday + 5) % 7 // Adjust for Monday start

        var days: [MonthlyDayData] = []

        // Add previous month's padding days
        if paddingDaysBefore > 0 {
            let paddingStart = calendar.date(byAdding: .day, value: -paddingDaysBefore, to: startOfMonth) ?? startOfMonth
            var paddingDate = paddingStart

            for _ in 0..<paddingDaysBefore {
                let dayExpenses = getExpensesForDate(paddingDate)
                days.append(MonthlyDayData(
                    date: paddingDate,
                    totalAmount: dayExpenses.reduce(0) { $0 + $1.amount },
                    expenseCount: dayExpenses.count,
                    isCurrentMonth: false,
                    dailyLimit: expenseViewModel.spendingSummary?.currentDailyLimit ?? 0,
                    categories: getCategoriesForDate(paddingDate)
                ))
                paddingDate = calendar.date(byAdding: .day, value: 1, to: paddingDate) ?? paddingDate
            }
        }

        // Add current month days
        var currentDate = startOfMonth
        while currentDate < endOfMonth {
            let dayExpenses = getExpensesForDate(currentDate)
            let totalAmount = dayExpenses.reduce(0) { $0 + $1.amount }
            let expenseCount = dayExpenses.count

            let averageDailyLimit: Double
            if dayExpenses.isEmpty {
                averageDailyLimit = expenseViewModel.spendingSummary?.currentDailyLimit ?? 0
            } else {
                let totalLimit = dayExpenses.reduce(0) { $0 + $1.dailyLimitAtCreation }
                averageDailyLimit = totalLimit / Double(dayExpenses.count)
            }

            days.append(MonthlyDayData(
                date: currentDate,
                totalAmount: totalAmount,
                expenseCount: expenseCount,
                isCurrentMonth: true,
                dailyLimit: averageDailyLimit,
                categories: getCategoriesForDate(currentDate)
            ))

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        // Add next month's padding days to complete the last week
        let totalDays = days.count
        let remainingDays = (7 - (totalDays % 7)) % 7

        if remainingDays > 0 {
            var paddingDate = endOfMonth
            for _ in 0..<remainingDays {
                let dayExpenses = getExpensesForDate(paddingDate)
                days.append(MonthlyDayData(
                    date: paddingDate,
                    totalAmount: dayExpenses.reduce(0) { $0 + $1.amount },
                    expenseCount: dayExpenses.count,
                    isCurrentMonth: false,
                    dailyLimit: expenseViewModel.spendingSummary?.currentDailyLimit ?? 0,
                    categories: getCategoriesForDate(paddingDate)
                ))
                paddingDate = calendar.date(byAdding: .day, value: 1, to: paddingDate) ?? paddingDate
            }
        }

        return days
    }
    
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return formatter.string(from: currentMonth).capitalized
    }

    private var weekdayHeaders: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.shortWeekdaySymbols.map { String($0.prefix(1)) }
    }

    var body: some View {
        NavigationView {
            ZStack {
                ThemeColors.backgroundColor(for: colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    headerView

                    // Calendar content
                    calendarContentView

                    // Statistics section
                    statisticsSection
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingDatePicker) {
            monthPickerView
        }
        .sheet(isPresented: $showingDayDetail) {
            dayDetailView
        }
    }

    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(AppTypography.titleSmall)
                        .foregroundColor(ThemeColors.textColor(for: colorScheme))
                }

                Spacer()

                Text(L("monthly_calendar"))
                    .font(AppTypography.navigationTitle)
                    .foregroundColor(ThemeColors.textColor(for: colorScheme))

                Spacer()

                Button(action: { showingDatePicker = true }) {
                    Image(systemName: "calendar")
                        .font(AppTypography.titleSmall)
                        .foregroundColor(AppColors.primaryOrange)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)

            // Month navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(AppTypography.bodyLarge)
                        .foregroundColor(AppColors.primaryOrange)
                }

                Spacer()

                Button(action: { showingDatePicker = true }) {
                    Text(monthName)
                        .font(AppTypography.titleMedium)
                        .foregroundColor(ThemeColors.textColor(for: colorScheme))
                }

                Spacer()

                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(AppTypography.bodyLarge)
                        .foregroundColor(AppColors.primaryOrange)
                }
            }
            .padding(.horizontal, 40)
        }
        .padding(.bottom, 20)
    }

    private var calendarContentView: some View {
        VStack(spacing: 8) {
            // Day headers
            HStack {
                ForEach(weekdayHeaders, id: \.self) { day in
                    Text(day)
                        .font(AppTypography.labelMedium)
                        .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)

            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(monthData) { dayData in
                    MonthlyDayView(
                        dayData: dayData,
                        colorScheme: colorScheme,
                        isSelected: calendar.isDate(dayData.date, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(dayData.date),
                        isReadOnly: dayData.date > Date() || !dayData.isCurrentMonth,
                        onTap: {
                            if dayData.date <= Date() && dayData.isCurrentMonth {
                                onDateSelected(dayData.date)
                            }
                        },
                        onLongPress: {
                            selectedDayExpenses = getExpensesForDate(dayData.date)
                            showingDayDetail = true
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var statisticsSection: some View {
        VStack(spacing: 12) {
            Divider()
                .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

            HStack {
                statisticItem(
                    title: L("month_total"),
                    value: formatCurrency(monthTotalAmount),
                    icon: "chart.bar.fill"
                )

                Divider()
                    .frame(height: 40)
                    .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

                statisticItem(
                    title: L("daily_average"),
                    value: formatCurrency(monthDailyAverage),
                    icon: "calendar.badge.clock"
                )

                Divider()
                    .frame(height: 40)
                    .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

                statisticItem(
                    title: L("remaining_budget"),
                    value: formatCurrency(remainingBudget),
                    icon: "banknote"
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    private func statisticItem(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(AppTypography.bodyLarge)
                .foregroundColor(AppColors.primaryOrange)

            Text(title)
                .font(AppTypography.labelSmall)
                .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                .multilineTextAlignment(.center)

            Text(value)
                .font(AppTypography.labelLarge)
                .foregroundColor(ThemeColors.textColor(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
    }

    private var monthPickerView: some View {
        NavigationView {
            VStack {
                DatePicker(
                    L("select_month"),
                    selection: $currentMonth,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.wheel)
                .padding()

                Spacer()
            }
            .navigationTitle(L("select_month"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("cancel")) {
                        showingDatePicker = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("done")) {
                        showingDatePicker = false
                    }
                }
            }
        }
    }

    private var dayDetailView: some View {
        NavigationView {
            MonthlyExpensesView(
                expenses: selectedDayExpenses,
                date: selectedDayExpenses.first?.date ?? Date()
            )
            .navigationTitle(L("day_expenses"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("done")) {
                        showingDayDetail = false
                    }
                }
            }
        }
    }

    // MARK: - Helper Functions

    private func getExpensesForDate(_ date: Date) -> [Expense] {
        let startOfDay = calendar.startOfDay(for: date)
        return expenses.filter { expense in
            calendar.startOfDay(for: expense.date) == startOfDay
        }
    }

    private func getCategoriesForDate(_ date: Date) -> [String] {
        let dayExpenses = getExpensesForDate(date)
        return Array(Set(dayExpenses.map { $0.categoryId }))
    }

    private func previousMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        }
    }

    private func nextMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        }
    }

    private var monthTotalAmount: Double {
        let monthStart = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
        let monthEnd = calendar.dateInterval(of: .month, for: currentMonth)?.end ?? currentMonth
        return expenses.filter { $0.date >= monthStart && $0.date < monthEnd }.reduce(0) { $0 + $1.amount }
    }

    private var monthDailyAverage: Double {
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 30
        return monthTotalAmount / Double(daysInMonth)
    }

    private var remainingBudget: Double {
        let monthlyLimit = expenseViewModel.spendingSummary?.currentMonthlyLimit ?? 0
        return max(0, monthlyLimit - monthTotalAmount)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = expenseViewModel.settingsManager?.currency ?? "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"
    }
}

struct MonthlyDayData: Identifiable {
    let id = UUID()
    let date: Date
    let totalAmount: Double
    let expenseCount: Int
    let isCurrentMonth: Bool
    let dailyLimit: Double
    let categories: [String]

    var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var progressPercentage: Double {
        if dailyLimit <= 0 { return 0 }
        return min(totalAmount / dailyLimit, 1.0)
    }

    var isOverLimit: Bool {
        return totalAmount > dailyLimit && dailyLimit > 0
    }

    var hasExpenses: Bool {
        return expenseCount > 0
    }

    var progressColor: Color {
        if isOverLimit {
            return AppColors.deleteRed
        } else if progressPercentage < 0.3 {
            return AppColors.successGreen
        } else if progressPercentage < 0.6 {
            return .yellow
        } else if progressPercentage < 0.9 {
            return .orange
        } else {
            return AppColors.primaryRed
        }
    }

    var indicatorColors: [Color] {
        if categories.count <= 1 {
            return [progressColor]
        } else if categories.count == 2 {
            return [progressColor, progressColor.opacity(0.7)]
        } else if categories.count == 3 {
            return [progressColor, progressColor.opacity(0.7), progressColor.opacity(0.4)]
        } else {
            return [progressColor, progressColor.opacity(0.7), progressColor.opacity(0.4), progressColor.opacity(0.2)]
        }
    }
}

struct MonthlyDayView: View {
    let dayData: MonthlyDayData
    let colorScheme: ColorScheme
    let isSelected: Bool
    let isToday: Bool
    let isReadOnly: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 2) {
            // Day indicators
            dayIndicatorsView

            // Day number
            Text(dayData.dayNumber)
                .font(dayData.isCurrentMonth ? AppTypography.labelMedium : AppTypography.labelSmall)
                .fontWeight(isToday ? .bold : .medium)
                .foregroundColor(dayTextColor)
                .scaleEffect(isPressed ? 0.95 : 1.0)

            // Amount text
            if dayData.hasExpenses {
                Text(formatAmount(dayData.totalAmount))
                    .font(AppTypography.labelSmall)
                    .foregroundColor(amountTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            } else {
                Text(" ")
                    .font(AppTypography.labelSmall)
            }
        }
        .frame(width: 44, height: 60)
        .background(backgroundView)
        .overlay(overlayView)
        .opacity(dayData.isCurrentMonth ? 1.0 : 0.5)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            if !isReadOnly {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                    onTap()
                }
            }
        }
        .onLongPressGesture {
            if dayData.hasExpenses {
                onLongPress()
            }
        }
    }

    private var dayIndicatorsView: some View {
        HStack(spacing: 1) {
            ForEach(Array(dayData.indicatorColors.enumerated()), id: \.offset) { index, color in
                if index < 4 { // Maximum 4 indicators
                    Circle()
                        .fill(color)
                        .frame(width: dayData.categories.count > 1 ? 6 : 8, height: dayData.categories.count > 1 ? 6 : 8)
                }
            }

            if dayData.categories.count > 4 {
                Text("+")
                    .font(AppTypography.labelSmall)
                    .foregroundColor(dayData.progressColor)
            }
        }
        .frame(height: 8)
    }

    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
    }

    private var overlayView: some View {
        Group {
            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppColors.primaryOrange, lineWidth: 2)
            }

            if isToday {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppColors.primaryRed, lineWidth: 1.5)
            }
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return ThemeColors.cardBackgroundColor(for: colorScheme)
        } else if dayData.hasExpenses {
            return dayData.progressColor.opacity(0.1)
        } else {
            return Color.clear
        }
    }

    private var borderColor: Color {
        if dayData.hasExpenses {
            return dayData.progressColor.opacity(0.3)
        } else {
            return ThemeColors.textGrayColor(for: colorScheme).opacity(0.1)
        }
    }

    private var borderWidth: CGFloat {
        dayData.hasExpenses ? 1 : 0.5
    }

    private var dayTextColor: Color {
        if !dayData.isCurrentMonth {
            return ThemeColors.textGrayColor(for: colorScheme).opacity(0.6)
        } else if isReadOnly {
            return ThemeColors.textGrayColor(for: colorScheme)
        } else if isToday {
            return AppColors.primaryRed
        } else if isSelected {
            return AppColors.primaryOrange
        } else {
            return ThemeColors.textColor(for: colorScheme)
        }
    }

    private var amountTextColor: Color {
        if isReadOnly {
            return ThemeColors.textGrayColor(for: colorScheme)
        } else {
            return dayData.progressColor
        }
    }

    private func formatAmount(_ amount: Double) -> String {
        if amount >= 1000 {
            return String(format: "%.0fk", amount / 1000)
        } else {
            return String(format: "%.0f", amount)
        }
    }
}
