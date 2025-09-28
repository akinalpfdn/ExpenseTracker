//
//  DailyHistoryView.swift
//  ExpenseTracker
//
//  Created by migration from Android DailyHistoryView.kt
//

import SwiftUI

struct DailyHistoryView: View {
    let weeklyData: [[DailyData]]
    let selectedDate: Date
    let onDateSelected: (Date) -> Void
    let onWeekNavigate: (Int) -> Void
    let isDarkTheme: Bool

    @State private var currentPageIndex = 1

    init(
        weeklyData: [[DailyData]],
        selectedDate: Date,
        onDateSelected: @escaping (Date) -> Void,
        onWeekNavigate: @escaping (Int) -> Void,
        isDarkTheme: Bool = true
    ) {
        self.weeklyData = weeklyData
        self.selectedDate = selectedDate
        self.onDateSelected = onDateSelected
        self.onWeekNavigate = onWeekNavigate
        self.isDarkTheme = isDarkTheme
    }

    var body: some View {
        TabView(selection: $currentPageIndex) {
            ForEach(0..<weeklyData.count, id: \.self) { weekIndex in
                weekView(weekData: weeklyData[weekIndex])
                    .tag(weekIndex)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .frame(height: 100)
        .onChange(of: currentPageIndex) { newIndex in
            handlePageChange(newIndex: newIndex)
        }
    }
}

// MARK: - Week View
extension DailyHistoryView {
    private func weekView(weekData: [DailyData]) -> some View {
        HStack(spacing: 8) {
            ForEach(weekData, id: \.id) { dayData in
                DailyHistoryItem(
                    data: dayData,
                    isSelected: Calendar.current.isDate(selectedDate, inSameDayAs: dayData.date),
                    isDarkTheme: isDarkTheme,
                    onClick: { onDateSelected(dayData.date) }
                )
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
    }

    private func handlePageChange(newIndex: Int) {
        let previousIndex = 1
        if newIndex != previousIndex {
            let direction = newIndex > previousIndex ? 1 : -1
            onWeekNavigate(direction)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                currentPageIndex = 1
            }
        }
    }
}

struct DailyHistoryItem: View {
    let data: DailyData
    let isSelected: Bool
    let isDarkTheme: Bool
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            VStack(alignment: .center, spacing: 4) {
                dayNameText
                progressRingSection
                amountText
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(selectionBackground)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Daily History Item Components
extension DailyHistoryItem {
    private var dayNameText: some View {
        Text(data.dayName)
            .font(.system(size: 12, weight: isSelected ? .bold : .medium))
            .foregroundColor(isSelected ?
                ThemeColors.getTextColor(isDarkTheme: isDarkTheme) :
                ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
    }

    private var progressRingSection: some View {
        ZStack {
            ProgressRingView(
                progress: data.progressPercentage,
                isLimitOver: data.isOverLimit,
                strokeWidth: 5
            )
            .frame(width: 40, height: 40)

            Text(data.dayNumber)
                .font(.system(size: 12, weight: isSelected ? .bold : .regular))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
        }
    }

    private var amountText: some View {
        Text(NumberFormatter.formatAmount(data.totalAmount))
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(data.isOverLimit ? .red : ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
    }

    private var selectionBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isSelected ?
                ThemeColors.getTextColor(isDarkTheme: isDarkTheme).opacity(0.2) :
                Color.clear)
    }
}

// MARK: - Preview
struct DailyHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleWeeklyData = [
            // Previous week
            (0...6).map { dayOffset in
                DailyData(
                    date: Calendar.current.date(byAdding: .day, value: dayOffset - 7, to: Date()) ?? Date(),
                    totalAmount: Double.random(in: 50...300),
                    progressAmount: Double.random(in: 30...250),
                    expenseCount: Int.random(in: 0...5),
                    dailyLimit: 200.0
                )
            },
            // Current week
            (0...6).map { dayOffset in
                DailyData(
                    date: Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date(),
                    totalAmount: Double.random(in: 50...300),
                    progressAmount: Double.random(in: 30...250),
                    expenseCount: Int.random(in: 0...5),
                    dailyLimit: 200.0
                )
            },
            // Next week
            (0...6).map { dayOffset in
                DailyData(
                    date: Calendar.current.date(byAdding: .day, value: dayOffset + 7, to: Date()) ?? Date(),
                    totalAmount: Double.random(in: 50...300),
                    progressAmount: Double.random(in: 30...250),
                    expenseCount: Int.random(in: 0...5),
                    dailyLimit: 200.0
                )
            }
        ]

        DailyHistoryView(
            weeklyData: sampleWeeklyData,
            selectedDate: Date(),
            onDateSelected: { _ in },
            onWeekNavigate: { _ in },
            isDarkTheme: true
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
