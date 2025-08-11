//
//  DailyHistoryView.swift
//  ExpenseTracker
//
//  Created by Akinalp Fidan on 11.08.2025.
//

import SwiftUI

struct DailyHistoryView: View {
    let dailyData: [DailyData]
    let selectedDate: Date
    let onDateSelected: (Date) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(dailyData) { dayData in
                    DailyHistoryItemView(
                        dayData: dayData,
                        isSelected: Calendar.current.isDate(dayData.date, inSameDayAs: selectedDate),
                        onTap: {
                            onDateSelected(dayData.date)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct DailyHistoryItemView: View {
    let dayData: DailyData
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Gün adı
            Text(dayData.dayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: dayData.progressPercentage)
                    .stroke(
                        AngularGradient(
                            colors: dayData.progressColors,
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: dayData.progressPercentage)
            }
            
            // Gün numarası
            Text(dayData.dayNumber)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .white : .secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.gray.opacity(0.3) : Color.clear)
        )
        .onTapGesture {
            onTap()
        }
    }
}
