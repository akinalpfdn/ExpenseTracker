//
//  DailyProgressRingView.swift
//  ExpenseTracker
//
//  Created by Akinalp Fidan on 11.08.2025.
//

import SwiftUI

struct DailyProgressRingView: View {
    let dailyProgressPercentage: Double
    let isOverDailyLimit: Bool
    let dailyLimitValue: Double
    let selectedDate: Date
    
    private var dailyProgressColors: [Color] {
        if isOverDailyLimit {
            return [.red, .red, .red, .red] // Limit aşıldığında tamamen kırmızı
        } else if dailyProgressPercentage < 0.3 {
            return [.green, .green, .green, .green] // %30'a kadar tamamen yeşil
        } else if dailyProgressPercentage < 0.6 {
            return [.green, .green, .yellow, .yellow] // %30-%60 arası yeşilden sarıya
        } else if dailyProgressPercentage < 0.9 {
            return [.green, .yellow, .orange, .orange] // %60-%90 arası yeşil-sarı-turuncu
        } else {
            return [.green, .yellow, .orange, .red] // %90+ yeşil-sarı-turuncu-kırmızı
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: dailyProgressPercentage)
                    .stroke(
                        AngularGradient(
                            colors: dailyProgressColors,
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1), value: dailyProgressPercentage)
                
                VStack(spacing: 2) {
                    Text("₺\(String(format: "%.0f", dailyLimitValue * dailyProgressPercentage))")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(isOverDailyLimit ? .red : .white)
                    Text(Calendar.current.isDateInToday(selectedDate) ? "Bugün" : "Seçili")
                        .font(.caption)
                        .foregroundColor(isOverDailyLimit ? .red : .secondary)
                }
            }
            
            Text("Günlük Limit")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
