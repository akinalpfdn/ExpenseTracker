//
//  DailyHistoryView.swift
//  ExpenseTracker
//
//  COMPLETE REWRITE - Exactly matching Kotlin DailyHistoryView.kt
//

import SwiftUI

struct DailyHistoryView: View {
    let weeklyData: [[DailyData]]
    let selectedDate: Date
    let onDateSelected: (Date) -> Void
    let onWeekNavigate: (Int) -> Void
    let isDarkTheme: Bool

    @State private var currentPageIndex = 1

    var body: some View {
        TabView(selection: $currentPageIndex) {
            ForEach(0..<weeklyData.count, id: \.self) { weekIndex in
                HStack(spacing: 8) {
                    ForEach(weeklyData[weekIndex], id: \.id) { dayData in
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
                .tag(weekIndex)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .frame(height: 100)
        .onChange(of: currentPageIndex) { newIndex in
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
}

private struct DailyHistoryItem: View {
    let data: DailyData
    let isSelected: Bool
    let isDarkTheme: Bool
    let onClick: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            // Day letter
            Text(data.dayName)
                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ?
                    ThemeColors.getTextColor(isDarkTheme: isDarkTheme) :
                    ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))

            // Progress ring with day number
            ZStack {
                ProgressRingView(
                    progress: data.progressPercentage,
                    isLimitOver: data.isOverLimit,
                    strokeWidth: 5,
                    onClick:
                        onClick
                )
                .frame(width: 40, height: 40)

                Text(data.dayNumber)
                    .font(.system(size: 12, weight: isSelected ? .bold : .regular))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
            }

            // Amount
            Text(NumberFormatter.formatAmount(data.totalAmount))
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(data.isOverLimit ? .red : ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
        }
        .padding(1)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ?
                    ThemeColors.getTextColor(isDarkTheme: isDarkTheme).opacity(0.2) :
                    Color.clear)
        )
        .onTapGesture {
            onClick()
        }
    }
}
