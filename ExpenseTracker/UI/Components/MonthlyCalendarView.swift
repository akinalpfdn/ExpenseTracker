//
//  MonthlyCalendarView.swift
//  ExpenseTracker
//
//  Created by migration from Android MonthlyCalendarView.kt
//

import SwiftUI

struct MonthlyCalendarView: View {
    let selectedDate: Date
    let expenses: [Expense]
    let onDateSelected: (Date) -> Void
    let defaultCurrency: String
    let dailyLimit: String
    let isDarkTheme: Bool
    let onMonthChanged: (Date) -> Void

    @State private var currentMonth: Date = Date()

    init(
        selectedDate: Date,
        expenses: [Expense],
        onDateSelected: @escaping (Date) -> Void,
        defaultCurrency: String = "₺",
        dailyLimit: String = "0",
        isDarkTheme: Bool = true,
        onMonthChanged: @escaping (Date) -> Void = { _ in }
    ) {
        self.selectedDate = selectedDate
        self.expenses = expenses
        self.onDateSelected = onDateSelected
        self.defaultCurrency = defaultCurrency
        self.dailyLimit = dailyLimit
        self.isDarkTheme = isDarkTheme
        self.onMonthChanged = onMonthChanged
        self._currentMonth = State(initialValue: Calendar.current.startOfMonth(for: selectedDate) ?? selectedDate)
    }

    var body: some View {
        VStack(spacing: 0) {
            calendarCard
        }
        .onAppear {
            onMonthChanged(currentMonth)
        }
    }
}

// MARK: - Calendar Card
extension MonthlyCalendarView {
    private var calendarCard: some View {
        VStack(spacing: 16) {
            monthHeader
            dayHeaders
            calendarGrid
        }
        .padding(16)
        .background(ThemeColors.getCardBackgroundColor(isDarkTheme: isDarkTheme))
        .cornerRadius(16)
        .padding(.horizontal, 16)
    }

    private var monthHeader: some View {
        HStack {
            monthYearText
            Spacer()
            navigationButtons
        }
    }

    private var monthYearText: some View {
        Text(monthYearString)
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
    }

    private var navigationButtons: some View {
        HStack(spacing: 8) {
            Button(action: previousMonth) {
                Text("‹")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
            }

            Button(action: nextMonth) {
                Text("›")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
            }
        }
    }

    private var dayHeaders: some View {
        HStack {
            ForEach(dayHeaderNames, id: \.self) { dayName in
                Text(dayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var calendarGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(calendarDays, id: \.id) { dayData in
                CalendarDayView(
                    dayData: dayData,
                    selectedDate: selectedDate,
                    currentMonth: currentMonth,
                    defaultCurrency: defaultCurrency,
                    isDarkTheme: isDarkTheme,
                    onDateSelected: onDateSelected
                )
            }
        }
    }
}

// MARK: - Computed Properties
extension MonthlyCalendarView {
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale.current
        return formatter.string(from: currentMonth)
    }

    private var dayHeaderNames: [String] {
        [
            "monday_short".localized,
            "tuesday_short".localized,
            "wednesday_short".localized,
            "thursday_short".localized,
            "friday_short".localized,
            "saturday_short".localized,
            "sunday_short".localized
        ]
    }

    private var calendarDays: [CalendarDayData] {
        generateCalendarDays()
    }
}

// MARK: - Helper Methods
extension MonthlyCalendarView {
    private func previousMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        }
        onMonthChanged(currentMonth)
    }

    private func nextMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        }
        onMonthChanged(currentMonth)
    }

    private func generateCalendarDays() -> [CalendarDayData] {
        let calendar = Calendar.current

        guard let monthStart = calendar.startOfMonth(for: currentMonth),
              let monthEnd = calendar.endOfMonth(for: currentMonth) else {
            return []
        }

        let startOfWeek = calendar.startOfWeek(for: monthStart)
        let endOfWeek = calendar.endOfWeek(for: monthEnd)

        var days: [CalendarDayData] = []
        var currentDate = startOfWeek

        while currentDate <= endOfWeek {
            let dayExpenses = getExpensesForDate(currentDate)
            let dayTotal = dayExpenses.reduce(0) { $0 + $1.getAmountInDefaultCurrency(defaultCurrency: defaultCurrency) }
            let progressAmount = dayExpenses.filter { $0.recurrenceType == .NONE }
                .reduce(0) { $0 + $1.getAmountInDefaultCurrency(defaultCurrency: defaultCurrency) }

            let dailyLimitValue = Double(dailyLimit) ?? 0.0
            let progressPercentage = dailyLimitValue > 0 ? min(progressAmount / dailyLimitValue, 1.0) : 0.0
            let isOverLimit = progressAmount > dailyLimitValue && dailyLimitValue > 0

            let dayData = CalendarDayData(
                date: currentDate,
                totalAmount: dayTotal,
                progressAmount: progressAmount,
                expenseCount: dayExpenses.count,
                progressPercentage: progressPercentage,
                isOverLimit: isOverLimit,
                isCurrentMonth: calendar.isDate(currentDate, equalTo: currentMonth, toGranularity: .month)
            )

            days.append(dayData)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return days
    }

    private func getExpensesForDate(_ date: Date) -> [Expense] {
        return expenses.filter { expense in
            expense.isActiveOnDate(targetDate: date)
        }
    }
}

struct CalendarDayData: Identifiable {
    let id = UUID()
    let date: Date
    let totalAmount: Double
    let progressAmount: Double
    let expenseCount: Int
    let progressPercentage: Double
    let isOverLimit: Bool
    let isCurrentMonth: Bool
}

struct CalendarDayView: View {
    let dayData: CalendarDayData
    let selectedDate: Date
    let currentMonth: Date
    let defaultCurrency: String
    let isDarkTheme: Bool
    let onDateSelected: (Date) -> Void

    private var isSelected: Bool {
        Calendar.current.isDate(dayData.date, inSameDayAs: selectedDate)
    }

    private var isToday: Bool {
        Calendar.current.isDate(dayData.date, inSameDayAs: Date())
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: dayData.date)
    }

    var body: some View {
        VStack(spacing: 4) {
            if !dayData.isCurrentMonth //&& dayData.expenseCount == 0
            {
                Spacer()
                    .frame(height: 50)
            } else {
                dayProgressRing
                amountText
            }
        }
        .onTapGesture {
            
            onDateSelected(dayData.date)
        }
    }
}

// MARK: - Calendar Day Components
extension CalendarDayView {
    private var dayProgressRing: some View {
        ZStack {
            Circle()
                .fill(isToday ? AppColors.primaryOrange.opacity(0.3) : Color.clear)
                .frame(width: 50, height: 50)

            if dayData.expenseCount > 0 {
                ProgressRingView(
                    progress: dayData.progressPercentage,
                    isLimitOver: dayData.isOverLimit,
                    strokeWidth: 3
                )
                .frame(width: 40, height: 40)
            }

            Text(dayNumber)
                .font(.system(size: 14, weight: (isSelected || isToday) ? .bold : .regular))
                .foregroundColor(dayNumberColor)
        }
    }

    private var amountText: some View {
        Text("\(defaultCurrency)\(NumberFormatter.formatAmount(dayData.totalAmount))")
            .font(.system(size: 9, weight: .medium))
            .foregroundColor(amountTextColor)
            .multilineTextAlignment(.center)
    }

    private var dayNumberColor: Color {
        switch true {
        case isSelected:
            return ThemeColors.getTextColor(isDarkTheme: isDarkTheme)
        case isToday:
            return AppColors.primaryOrange
        case !dayData.isCurrentMonth:
            return ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme).opacity(0.3)
        case dayData.expenseCount > 0:
            return ThemeColors.getTextColor(isDarkTheme: isDarkTheme)
        default:
            return ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme)
        }
    }

    private var amountTextColor: Color {
        switch true {
        case dayData.isOverLimit:
            return .red
        case !dayData.isCurrentMonth:
            return ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme).opacity(0.3)
        case dayData.expenseCount > 0:
            return ThemeColors.getTextColor(isDarkTheme: isDarkTheme)
        default:
            return ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme)
        }
    }
}

// MARK: - Calendar Extensions
extension Calendar {
    func startOfMonth(for date: Date) -> Date? {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components)
    }

    func endOfMonth(for date: Date) -> Date? {
        guard let startOfMonth = startOfMonth(for: date) else { return nil }
        return self.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)
    }

    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let startOfWeek = self.date(from: components) ?? date
        return self.date(byAdding: .day, value: 1, to: startOfWeek) ?? date // Monday start
    }

    func endOfWeek(for date: Date) -> Date {
        let startOfWeek = self.startOfWeek(for: date)
        return self.date(byAdding: .day, value: 6, to: startOfWeek) ?? date
    }
}


// MARK: - Preview
struct MonthlyCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleExpenses = [
            Expense(
                amount: 50.0,
                currency: "₺",
                categoryId: "food",
                subCategoryId: "restaurant",
                description: "Lunch",
                date: Date(),
                dailyLimitAtCreation: 200.0,
                monthlyLimitAtCreation: 5000.0
            ),
            Expense(
                amount: 25.0,
                currency: "₺",
                categoryId: "transport",
                subCategoryId: "fuel",
                description: "Gas",
                date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                dailyLimitAtCreation: 200.0,
                monthlyLimitAtCreation: 5000.0
            )
        ]

        MonthlyCalendarView(
            selectedDate: Date(),
            expenses: sampleExpenses,
            onDateSelected: { _ in },
            defaultCurrency: "₺",
            dailyLimit: "200",
            isDarkTheme: true
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
