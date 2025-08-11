//
//  CategoryDistributionView.swift
//  ExpenseTracker
//
//  Created by Akinalp Fidan on 11.08.2025.
//

import SwiftUI

struct CategoryDistributionView: View {
    let dailyExpensesByCategory: [(category: ExpenseCategory, amount: Double, percentage: Double)]
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                // Pie chart segments
                ForEach(Array(dailyExpensesByCategory.enumerated()), id: \.offset) { index, item in
                    let startAngle = getStartAngle(for: index)
                    
                    Circle()
                        .trim(from: 0, to: item.percentage)
                        .stroke(
                            CategoryHelper.getCategoryColor(item.category),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(startAngle - 90))
                        .animation(.easeInOut(duration: 1), value: dailyExpensesByCategory.count)
                }
                
                VStack(spacing: 2) {
                    Text("\(dailyExpensesByCategory.count)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Kategori")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text("Kategori Dağılımı")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func getStartAngle(for index: Int) -> Double {
        var startAngle: Double = 0
        for i in 0..<index {
            startAngle += dailyExpensesByCategory[i].percentage * 360
        }
        return startAngle
    }
}
