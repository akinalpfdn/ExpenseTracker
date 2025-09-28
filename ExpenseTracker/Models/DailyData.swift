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
    let progressAmount: Double
    let expenseCount: Int
    let dailyLimit: Double

    var progressPercentage: Double {
        if dailyLimit <= 0 { return 0.0 }
        return min(progressAmount / dailyLimit, 1.0)
    }

    var isOverLimit: Bool {
        return progressAmount > dailyLimit && dailyLimit > 0
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
    
    
    
   
}
