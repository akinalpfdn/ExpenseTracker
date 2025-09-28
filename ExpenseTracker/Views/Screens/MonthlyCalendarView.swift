//
//  MonthlyCalendarView.swift
//  ExpenseTracker
//
//  Created by Akinalp Fidan on 11.08.2025.
//

import SwiftUI

struct MonthlyCalendarView: View {
    let expenses: [Expense]
    let selectedDate: Date
    let onDateSelected: (Date) -> Void
    let onDismiss: () -> Void
    
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.locale = Locale(identifier: "tr_TR")
        return cal
    }
    
    private var monthData: [MonthlyDayData] {
        let startOfMonth = calendar.dateInterval(of: .month, for: selectedDate)?.start ?? selectedDate
        let endOfMonth = calendar.dateInterval(of: .month, for: selectedDate)?.end ?? selectedDate
        
        var days: [MonthlyDayData] = []
        var currentDate = startOfMonth
        
        while currentDate < endOfMonth {
            let dayExpenses = getExpensesForDate(currentDate)
            let totalAmount = dayExpenses.reduce(0) { $0 + $1.amount }
            let expenseCount = dayExpenses.count
            
            // O günkü harcamaların ortalama limit değerini hesapla
            let averageDailyLimit: Double
            if dayExpenses.isEmpty {
                averageDailyLimit = Double(UserDefaults.standard.string(forKey: "dailyLimit") ?? "0") ?? 0.0
            } else {
                let totalLimit = dayExpenses.reduce(0) { $0 + $1.dailyLimitAtCreation }
                averageDailyLimit = totalLimit / Double(dayExpenses.count)
            }
            
            days.append(MonthlyDayData(
                date: currentDate,
                totalAmount: totalAmount,
                expenseCount: expenseCount,
                isCurrentMonth: true,
                dailyLimit: averageDailyLimit
            ))
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return days
    }
    
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "MMM"
        return formatter.string(from: selectedDate).capitalized
    }
    
    private var isFutureDate: Bool {
        return calendar.isDate(selectedDate, inSameDayAs: Date()) || selectedDate > Date()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Text("Aylık Ajanda")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Placeholder for balance
                        Text("")
                            .font(.title2)
                            .foregroundColor(.clear)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Month name
                    Text(monthName)
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    

                    
                    // Calendar grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        // Day headers
                        ForEach(["P", "S", "Ç", "P", "C", "C", "P"], id: \.self) { day in
                            Text(day)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .frame(height: 30)
                        }
                        
                        // Calendar days
                        ForEach(monthData) { dayData in
                            MonthlyDayView(
                                dayData: dayData,
                                isSelected: calendar.isDate(dayData.date, inSameDayAs: selectedDate),
                                isReadOnly: dayData.date > Date(),
                                onTap: {
                                    if dayData.date <= Date() {
                                        onDateSelected(dayData.date)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
    }
    
    private func getExpensesForDate(_ date: Date) -> [Expense] {
        let startOfDay = calendar.startOfDay(for: date)
        return expenses.filter { expense in
            calendar.startOfDay(for: expense.date) == startOfDay
        }
    }
}

struct MonthlyDayData: Identifiable {
    let id = UUID()
    let date: Date
    let totalAmount: Double
    let expenseCount: Int
    let isCurrentMonth: Bool
    let dailyLimit: Double
    
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
    
    var progressColors: [Color] {
        if isOverLimit {
            return [.red, .red, .red, .red]
        } else if progressPercentage < 0.3 {
            return [.green, .green, .green, .green]
        } else if progressPercentage < 0.6 {
            return [.green, .green, .yellow, .yellow]
        } else if progressPercentage < 0.9 {
            return [.green, .yellow, .orange, .orange]
        } else {
            return [.green, .yellow, .orange, .red]
        }
    }
}

struct MonthlyDayView: View {
    let dayData: MonthlyDayData
    let isSelected: Bool
    let isReadOnly: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            // Progress rings
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 32, height: 32)
                
                if dayData.totalAmount > 0 {
                    Circle()
                        .trim(from: 0, to: dayData.progressPercentage)
                        .stroke(
                            AngularGradient(
                                colors: dayData.progressColors,
                                center: .center,
                                startAngle: .degrees(0),
                                endAngle: .degrees(360)
                            ),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round)
                        )
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(-90))
                }
            }
            
            // Day number
            Text(dayData.dayNumber)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isReadOnly ? .gray : (isSelected ? .white : (dayData.totalAmount > 0 ? .white : .secondary)))
            
            // Total amount (if any)
            if dayData.totalAmount > 0 {
                Text("₺\(String(format: "%.0f", dayData.totalAmount))")
                    .font(.caption2)
                    .foregroundColor(isReadOnly ? .gray : .secondary)
                    .lineLimit(1)
            }
        }
        .frame(height: 50)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.gray.opacity(0.3) : Color.clear)
        )
        .opacity(isReadOnly ? 0.5 : 1.0)
        .onTapGesture {
            if !isReadOnly {
                onTap()
            }
        }
    }
}
