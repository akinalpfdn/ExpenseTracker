//
//  DailyData.swift
//  ExpenseTracker
//
//  Created by Akinalp Fidan on 11.08.2025.
//

import Foundation
import SwiftUI

struct DailyData: Identifiable {
    let id = UUID()
    let date: Date
    let totalAmount: Double
    let expenseCount: Int
    let dailyLimit: Double
    
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
    
    var dayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "E"
        return formatter.string(from: date).prefix(1).uppercased()
    }
    
    var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var isToday: Bool {
        return Calendar.current.isDateInToday(date)
    }
    
    var isSelected: Bool {
        return Calendar.current.isDate(date, inSameDayAs: Date())
    }
}
