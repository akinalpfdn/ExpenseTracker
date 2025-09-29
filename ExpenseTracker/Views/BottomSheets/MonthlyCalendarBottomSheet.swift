//
//  MonthlyCalendarBottomSheet.swift
//  ExpenseTracker
//
//  Created by migration from Android MonthlyCalendarBottomSheet
//

import SwiftUI

// MARK: - View Extensions
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct MonthlyCalendarBottomSheet: View {
    @EnvironmentObject var viewModel: ExpenseViewModel

    let selectedMonth: Date
    let onDismiss: () -> Void

    @State private var selectedTabIndex = 0
    @State private var currentMonth: Date

    private let tabs = ["calendar".localized, "expenses".localized]

    private var isDarkTheme: Bool {
        viewModel.theme == "dark"
    }

    init(selectedMonth: Date, onDismiss: @escaping () -> Void) {
        self.selectedMonth = selectedMonth
        self.onDismiss = onDismiss
        self._currentMonth = State(initialValue: selectedMonth)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Handle Bar
            handleBar

            // Header
            header

            // Tab Row
            customTabRow

            Spacer().frame(height: 16)

            // Tab Content
            if selectedTabIndex == 0 {
                calendarTab
            } else {
                monthlyExpensesTab
            }
        }
        .background(ThemeColors.getBottomSheetBackgroundColor(isDarkTheme: isDarkTheme))
        .cornerRadius(20, corners: [.topLeft, .topRight])
    }
}

// MARK: - View Components
extension MonthlyCalendarBottomSheet {
    private var handleBar: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme).opacity(0.3))
            .frame(width: 40, height: 4)
            .padding(.top, 12)
    }

    private var header: some View {
        HStack {
             
            Spacer()

            Button("done".localized) {
                onDismiss()
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(AppColors.primaryOrange)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var customTabRow: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, title in
                Button(action: { selectedTabIndex = index }) {
                    VStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 18, weight: selectedTabIndex == index ? .semibold : .regular))
                            .foregroundColor(
                                selectedTabIndex == index ?
                                AppColors.primaryOrange :
                                ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme)
                            )
                            .padding(.vertical, 8)

                        // Tab indicator
                        Rectangle()
                            .fill(selectedTabIndex == index ? AppColors.primaryOrange : Color.clear)
                            .frame(height: 3)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    private var calendarTab: some View {
        ScrollView {
            MonthlyCalendarView(
                selectedDate: viewModel.selectedDate,
                expenses: viewModel.expenses,
                onDateSelected: { date in
                    viewModel.updateSelectedDate(date)
                },
                defaultCurrency: viewModel.defaultCurrency,
                dailyLimit: viewModel.dailyLimit,
                isDarkTheme: isDarkTheme,
                onMonthChanged: { month in
                    currentMonth = month
                }
            )
            .padding(.bottom, 20)
        }
    }

    private var monthlyExpensesTab: some View {
        MonthlyExpensesView(
            currentMonth: currentMonth,
            expenses: viewModel.expenses,
            isDarkTheme: isDarkTheme
        )
        .environmentObject(viewModel)
    }

    private var monthNavigationHeader: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
            }

            Spacer()

            Text(monthYearString)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            Spacer()

            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(ThemeColors.getCardBackgroundColor(isDarkTheme: isDarkTheme))
        .cornerRadius(12)
    }

}

// MARK: - Helper Methods
extension MonthlyCalendarBottomSheet {
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale.current
        return formatter.string(from: currentMonth)
    }


    private func previousMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        }
    }

    private func nextMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        }
    }
}

// MARK: - MonthlyExpenseRowView
struct MonthlyExpenseRowView: View {
    @EnvironmentObject var viewModel: ExpenseViewModel

    let expense: Expense
    let defaultCurrency: String
    let isDarkTheme: Bool
    let onTap: () -> Void

    private var category: Category? {
        viewModel.categories.first { $0.id == expense.categoryId }
    }

    private var subCategory: SubCategory? {
        viewModel.subCategories.first { $0.id == expense.subCategoryId }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Date
                VStack(alignment: .leading, spacing: 2) {
                    Text(dayFormatter.string(from: expense.date))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

                    Text(dayNameFormatter.string(from: expense.date))
                        .font(.system(size: 12))
                        .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                }
                .frame(width: 40)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.description ?? "")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                        .lineLimit(1)

                    Text(subCategory?.name ?? category?.name ?? "")
                        .font(.system(size: 12))
                        .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                        .lineLimit(1)
                }

                Spacer()

                // Amount
                Text("\(defaultCurrency)\(NumberFormatter.formatAmount(expense.getAmountInDefaultCurrency(defaultCurrency: defaultCurrency)))")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.primaryOrange)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(ThemeColors.getInputBackgroundColor(isDarkTheme: isDarkTheme))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter
    }

    private var dayNameFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }
}

// MARK: - Preview
struct MonthlyCalendarBottomSheet_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ExpenseViewModel()

        MonthlyCalendarBottomSheet(
            selectedMonth: Date(),
            onDismiss: { }
        )
        .environmentObject(viewModel)
    }
}
