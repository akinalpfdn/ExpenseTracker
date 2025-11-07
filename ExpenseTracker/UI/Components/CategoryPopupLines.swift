//
//  CategoryPopupLines.swift
//  ExpenseTracker
//
//  Created by migration from Android CategoryPopupLines.kt
//

import SwiftUI

struct CategoryPopupLines: View {
    let segmentIndex: Int
    let animatedPercentages: [Float]
    let selectedCategory: CategoryAnalysisData
    let line1Progress: Double
    let line2Progress: Double
    let isDarkTheme: Bool

    init(
        segmentIndex: Int,
        animatedPercentages: [Float],
        selectedCategory: CategoryAnalysisData,
        line1Progress: Double = 1.0,
        line2Progress: Double = 1.0,
        isDarkTheme: Bool = true
    ) {
        self.segmentIndex = segmentIndex
        self.animatedPercentages = animatedPercentages
        self.selectedCategory = selectedCategory
        self.line1Progress = line1Progress
        self.line2Progress = line2Progress
        self.isDarkTheme = isDarkTheme
    }

    var body: some View {
        Canvas { context, size in
            drawConnectorLines(context: context, size: size)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .offset(y: -150)
        .opacity(max(line1Progress, line2Progress))
    }
}

// MARK: - Drawing Methods
extension CategoryPopupLines {
    private func drawConnectorLines(context: GraphicsContext, size: CGSize) {
        // Calculate pie chart center position
        let pieChartCenterX = size.width / 2
        let pieChartCenterY: CGFloat = 40 // Pie chart center position
        let pieRadius: CGFloat = 125 // Half of 250pt pie chart size

        // Calculate segment center
        let segmentCenter = calculateSegmentCenter(
            pieChartCenter: CGPoint(x: pieChartCenterX, y: pieChartCenterY),
            pieRadius: pieRadius
        )

        // Calculate elbow point
        let elbowPoint = calculateElbowPoint(
            segmentCenter: segmentCenter,
            pieChartCenterX: pieChartCenterX
        )

        // Draw connector lines
        drawLine1(context: context, from: segmentCenter, to: elbowPoint)
        drawLine2(context: context, from: elbowPoint, to: CGPoint(x: elbowPoint.x, y: size.height - 10))
    }

    private func calculateSegmentCenter(pieChartCenter: CGPoint, pieRadius: CGFloat) -> CGPoint {
        // Calculate the middle angle of the selected segment
        var segmentStartAngle: Float = -90 // Start from top
        for i in 0..<segmentIndex {
            segmentStartAngle += animatedPercentages[i] * 360
        }

        let segmentMiddleAngle = segmentStartAngle + (animatedPercentages[segmentIndex] * 360 / 2)
        let segmentAngleRad = segmentMiddleAngle * .pi / 180

        // Position at the middle of the segment thickness
        let segmentRadius = pieRadius * 0.725 // Middle of donut
        let segmentCenterX = pieChartCenter.x + CGFloat(cos(segmentAngleRad)) * segmentRadius
        let segmentCenterY = pieChartCenter.y + CGFloat(sin(CGFloat(segmentAngleRad))) * segmentRadius

        return CGPoint(x: segmentCenterX, y: segmentCenterY)
    }

    private func calculateElbowPoint(segmentCenter: CGPoint, pieChartCenterX: CGFloat) -> CGPoint {
        let elbowDistance: CGFloat = 35

        // Determine elbow angle based on which side of chart we're on
        let elbowAngle: Float = segmentCenter.x < pieChartCenterX ? 150 : 30 // Down and left/right
        let elbowAngleRad = elbowAngle * .pi / 180

        let elbowX = segmentCenter.x + CGFloat(cos(CGFloat(elbowAngleRad))) * elbowDistance
        let elbowY = segmentCenter.y + CGFloat(sin(CGFloat(elbowAngleRad))) * elbowDistance

        return CGPoint(x: elbowX, y: elbowY)
    }

    private func drawLine1(context: GraphicsContext, from start: CGPoint, to end: CGPoint) {
        // Draw first line (angled connector) with animation
        guard line1Progress > 0 else { return }

        let animatedEnd = CGPoint(
            x: start.x + (end.x - start.x) * line1Progress,
            y: start.y + (end.y - start.y) * line1Progress
        )

        var path = Path()
        path.move(to: start)
        path.addLine(to: animatedEnd)

        context.stroke(path, with: .color(selectedCategory.category.getColor()), lineWidth: 2)
    }

    private func drawLine2(context: GraphicsContext, from start: CGPoint, to end: CGPoint) {
        // Draw second line (vertical) only after first line starts and if line2Progress > 0
        guard line2Progress > 0 && line1Progress >= 1.0 else { return }

        let animatedEnd = CGPoint(
            x: start.x,
            y: start.y + (end.y - start.y) * line2Progress
        )

        var path = Path()
        path.move(to: start)
        path.addLine(to: animatedEnd)

        context.stroke(path, with: .color(selectedCategory.category.getColor()), lineWidth: 2)

        // Draw arrow tip when line is complete
        if line2Progress >= 1.0 {
            drawArrowTip(context: context, at: end)
        }
    }

    private func drawArrowTip(context: GraphicsContext, at point: CGPoint) {
        let arrowSize: CGFloat = 6

        var arrowPath = Path()
        arrowPath.move(to: point) // Arrow tip (bottom)
        arrowPath.addLine(to: CGPoint(x: point.x - arrowSize, y: point.y - arrowSize)) // Left side
        arrowPath.addLine(to: CGPoint(x: point.x + arrowSize, y: point.y - arrowSize)) // Right side
        arrowPath.closeSubpath()

        context.fill(arrowPath, with: .color(selectedCategory.category.getColor()))
    }
}

struct CategoryPopupCard: View {
    let selectedCategory: CategoryAnalysisData
    let defaultCurrency: String
    let comparisonData: CategoryComparisonData?
    let popupScale: Double
    let onCategoryClick: (CategoryAnalysisData) -> Void
    let isDarkTheme: Bool

    init(
        selectedCategory: CategoryAnalysisData,
        defaultCurrency: String = "₺",
        comparisonData: CategoryComparisonData? = nil,
        popupScale: Double = 1.0,
        onCategoryClick: @escaping (CategoryAnalysisData) -> Void = { _ in },
        isDarkTheme: Bool = true
    ) {
        self.selectedCategory = selectedCategory
        self.defaultCurrency = defaultCurrency
        self.comparisonData = comparisonData
        self.popupScale = popupScale
        self.onCategoryClick = onCategoryClick
        self.isDarkTheme = isDarkTheme
    }

    var body: some View {
        Button(action: { onCategoryClick(selectedCategory) }) {
            cardContent
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(popupScale)
    }
}

// MARK: - Category Popup Card Components
extension CategoryPopupCard {
    private var cardContent: some View {
        HStack(spacing: 16) {
            categoryIcon
            categoryInfo
            Spacer()
            amountInfo
        }
        .padding(16)
        .frame(minHeight: 120)
        .background(selectedCategory.category.getColor().)
        .cornerRadius(16)
    }

    private var categoryIcon: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 48, height: 48)

            Image(systemName: selectedCategory.category.getIcon())
                .foregroundColor(.white)
                .font(.system(size: 24))
        }
    }

    private var categoryInfo: some View {
        VStack(alignment: .leading, spacing: 6) {
            categoryName
            categoryStats
            if let comparison = comparisonData {
                comparisonIndicators(comparison)
            }
        }
    }

    private var categoryName: some View {
        Text(selectedCategory.category.name)
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.black)
            .lineLimit(1)
    }

    private var categoryStats: some View {
        Text("\(selectedCategory.expenseCount) \("expense_lowercase".localized) • \(String(format: "%.1f", selectedCategory.percentage * 100))%")
            .font(.system(size: 12))
            .foregroundColor(.black)
    }

    private func comparisonIndicators(_ comparison: CategoryComparisonData) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ComparisonIndicator(
                percentage: comparison.vsLastMonth,
                label: "vs_previous_month_colon".localized,
                textColor: .white,
                isDarkTheme:isDarkTheme
            )
            ComparisonIndicator(
                percentage: comparison.vsAverage,
                label: "vs_average_colon".localized,
                textColor: .white,
                isDarkTheme:isDarkTheme
            )
        }
    }

    private var amountInfo: some View {
        VStack(alignment: .trailing) {
            Text("\(defaultCurrency) \(NumberFormatter.formatAmount(selectedCategory.totalAmount))")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black)
        }
    }
}

struct ComparisonIndicator: View {
    let percentage: Double
    let label: String
    let textColor: Color
    let isDarkTheme: Bool

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.black)

            Text(formattedPercentage)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(percentageColor)
        }
    }

    private var formattedPercentage: String {
        if percentage == 0.0 {
            return "±0%"
        } else {
            let sign = percentage > 0 ? "+" : ""
            return "\(sign)\(String(format: "%.1f", percentage))%"
        }
    }

    private var percentageColor: Color {
        switch percentage {
        case let x where x > 0:
            return .red.opacity(0.9)
        case let x where x < 0:
            return .green.opacity(0.9)
        default:
            return textColor.opacity(0.7)
        }
    }
}

struct CategoryComparisonData {
    let vsLastMonth: Double
    let vsAverage: Double
}

// MARK: - Preview
struct CategoryPopupLines_Previews: PreviewProvider {
    static var previews: some View {
        let sampleCategory = Category.getDefaultCategories()[0]
        let sampleCategoryData = CategoryAnalysisData(
            category: sampleCategory,
            totalAmount: 500.0,
            expenseCount: 10,
            percentage: 0.35,
            expenses: []
        )

        let sampleComparison = CategoryComparisonData(
            vsLastMonth: 15.5,
            vsAverage: -8.2
        )

        VStack(spacing: 20) {
            ZStack {
                // Background to show the popup
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)

                CategoryPopupLines(
                    segmentIndex: 0,
                    animatedPercentages: [0.35, 0.25, 0.4],
                    selectedCategory: sampleCategoryData,
                    line1Progress: 1.0,
                    line2Progress: 1.0
                )
            }

            CategoryPopupCard(
                selectedCategory: sampleCategoryData,
                defaultCurrency: "₺",
                comparisonData: sampleComparison,
                popupScale: 1.0
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
