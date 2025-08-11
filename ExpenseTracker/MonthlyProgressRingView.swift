//
//  MonthlyProgressRingView.swift
//  ExpenseTracker
//
//  Created by Akinalp Fidan on 11.08.2025.
//

import SwiftUI

struct MonthlyProgressRingView: View {
    let totalSpent: Double
    let progressPercentage: Double
    let progressColors: [Color]
    let isOverLimit: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: progressPercentage)
                    .stroke(
                        AngularGradient(
                            colors: progressColors,
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1), value: totalSpent)
                
                VStack(spacing: 2) {
                    Text("₺\(String(format: "%.0f", totalSpent))")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(isOverLimit ? .red : .white)
                    Text("Bu ay")
                        .font(.caption)
                        .foregroundColor(isOverLimit ? .red : .secondary)
                }
            }
            
            Text("Aylık Limit")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
