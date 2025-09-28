//
//  CategoryDistributionChart.swift
//  ExpenseTracker
//
//  Created by migration from Android CategoryDistributionChart.kt
//

import SwiftUI

struct CategoryDistributionChart: View {
    let categoryExpenses: [CategoryExpense]
    let onCategoryClick: (Category) -> Void
    let isDarkTheme: Bool

    @State private var animationProgress: Double = 0

    init(
        categoryExpenses: [CategoryExpense],
        onCategoryClick: @escaping (Category) -> Void = { _ in },
        isDarkTheme: Bool = true
    ) {
        self.categoryExpenses = categoryExpenses
        self.onCategoryClick = onCategoryClick
        self.isDarkTheme = isDarkTheme
    }

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            if categoryExpenses.isEmpty {
                emptyStateView
            } else {
                pieChartView
                categoryLabel
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2)) {
                animationProgress = 1.0
            }
        }
        .onChange(of: categoryExpenses) { _ in
            animationProgress = 0
            withAnimation(.easeInOut(duration: 1.2)) {
                animationProgress = 1.0
            }
        }
    }
}

// MARK: - Chart Components
extension CategoryDistributionChart {
    private var emptyStateView: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                .frame(width: 120, height: 120)

            Text("no_data".localized)
                .font(.system(size: 16))
                .foregroundColor(.gray)
        }
    }

    private var pieChartView: some View {
        ZStack {
            ForEach(Array(categoryExpenses.enumerated()), id: \.offset) { index, categoryExpense in
                PieSlice(
                    startAngle: startAngle(for: index),
                    endAngle: endAngle(for: index),
                    animationProgress: animationProgress
                )
                .fill(categoryExpense.category.getColor())
                .onTapGesture {
                    onCategoryClick(categoryExpense.category)
                }
            }

            Circle()
                .fill(ThemeColors.getBackgroundColor(isDarkTheme: isDarkTheme))
                .frame(width: 80, height: 80)
        }
        .frame(width: 160, height: 160)
    }

    private var categoryLabel: some View {
        Text("category".localized)
            .font(.system(size: 12))
            .foregroundColor(.gray)
    }
}

// MARK: - Helper Methods
extension CategoryDistributionChart {
    private func startAngle(for index: Int) -> Angle {
        let previousPercentages = categoryExpenses.prefix(index).reduce(0) { $0 + $1.percentage }
        return Angle.degrees(-90 + (previousPercentages * 360))
    }

    private func endAngle(for index: Int) -> Angle {
        let currentPercentage = categoryExpenses[index].percentage
        let previousPercentages = categoryExpenses.prefix(index).reduce(0) { $0 + $1.percentage }
        return Angle.degrees(-90 + ((previousPercentages + currentPercentage) * 360))
    }
}

struct PieSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let animationProgress: Double

    var animatableData: Double {
        get { animationProgress }
        set { }
    }

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - 5

        let animatedEndAngle = Angle.degrees(
            startAngle.degrees + (endAngle.degrees - startAngle.degrees) * animationProgress
        )

        var path = Path()
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: animatedEndAngle,
            clockwise: false
        )
        path.closeSubpath()

        return path
    }
}

// MARK: - Preview
struct CategoryDistributionChart_Previews: PreviewProvider {
    static var previews: some View {
        let sampleCategories = Category.getDefaultCategories()
        let sampleCategoryExpenses = [
            CategoryExpense(
                category: sampleCategories[0],
                amount: 150.0,
                percentage: 0.4
            ),
            CategoryExpense(
                category: sampleCategories[1],
                amount: 100.0,
                percentage: 0.35
            ),
            CategoryExpense(
                category: sampleCategories[2],
                amount: 75.0,
                percentage: 0.25
            )
        ]

        VStack(spacing: 20) {
            CategoryDistributionChart(
                categoryExpenses: sampleCategoryExpenses,
                isDarkTheme: true
            )

            CategoryDistributionChart(
                categoryExpenses: [],
                isDarkTheme: true
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}