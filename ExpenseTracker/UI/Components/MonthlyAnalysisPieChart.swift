//
//  MonthlyAnalysisPieChart.swift
//  ExpenseTracker
//
//  Created by migration from Android MonthlyAnalysisPieChart.kt
//

import SwiftUI

struct CategoryAnalysisData: Identifiable, Equatable {
    let id = UUID()
    let category: Category
    let totalAmount: Double
    let expenseCount: Int
    let percentage: Double
    let expenses: [Expense]
}

struct MonthlyAnalysisPieChart: View {
    let categoryData: [CategoryAnalysisData]
    let isDarkTheme: Bool
    let selectedSegment: Int?
    let onSegmentSelected: (Int?) -> Void

    @State private var isCollapsed = false
    @State private var animationProgress: Double = 0
    @State private var segmentScales: [Double] = []

    init(
        categoryData: [CategoryAnalysisData],
        isDarkTheme: Bool = true,
        selectedSegment: Int? = nil,
        onSegmentSelected: @escaping (Int?) -> Void = { _ in }
    ) {
        self.categoryData = categoryData
        self.isDarkTheme = isDarkTheme
        self.selectedSegment = selectedSegment
        self.onSegmentSelected = onSegmentSelected
        self._segmentScales = State(initialValue: Array(repeating: 1.0, count: categoryData.count))
    }

    var body: some View {
        VStack(spacing: 0) {
            chartCard
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2)) {
                animationProgress = 1.0
            }
        }
        .onChange(of: selectedSegment) { newValue in
            updateSegmentScales(selectedIndex: newValue)
        }
    }
}

// MARK: - Chart Card
extension MonthlyAnalysisPieChart {
    private var chartCard: some View {
        VStack(spacing: 10) {
            headerRow

            if !isCollapsed {
                chartContent
            }
        }
        .padding(10)
        .background(ThemeColors.getCardBackgroundColor(isDarkTheme: isDarkTheme))
        .cornerRadius(16)
        .frame(maxWidth: .infinity)
    }

    private var headerRow: some View {
        HStack {
            Text("category_distribution".localized)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            Spacer()

            Button(action: toggleCollapse) {
                Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                    .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                    .font(.system(size: 16))
            }
        }
        .onTapGesture {
            toggleCollapse()
        }
    }

    private var chartContent: some View {
        Group {
            if categoryData.isEmpty {
                emptyChartView
            } else {
                pieChartContainer
            }
        }
    }

    private var emptyChartView: some View {
        VStack {
            Text("no_data".localized)
                .font(.system(size: 16))
                .foregroundColor(.gray)
        }
        .frame(height: 265)
    }

    private var pieChartContainer: some View {
        ZStack {
            pieChart
            centerHole
            hintText
        }
        .frame(width: 250, height: 265)
    }
}

// MARK: - Pie Chart Components
extension MonthlyAnalysisPieChart {
    private var pieChart: some View {
        ZStack {
            ForEach(Array(categoryData.enumerated()), id: \.offset) { index, data in
                AnimatedPieSlice(
                    startAngle: startAngle(for: index),
                    endAngle: endAngle(for: index),
                    animationProgress: animationProgress,
                    scale: segmentScales.indices.contains(index) ? segmentScales[index] : 1.0
                )
                .fill(data.category.getColor())
                .onTapGesture {
                    handleSegmentTap(index: index)
                }
            }
        }
        .frame(width: 250, height: 250)
    }

    private var centerHole: some View {
        Circle()
            .fill(ThemeColors.getBackgroundColor(isDarkTheme: isDarkTheme))
            .frame(width: 112, height: 112)
    }

    private var hintText: some View {
        Group {
            if selectedSegment == nil {
                VStack(spacing: 4) {
                    Image(systemName: "hand.tap")
                        .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme).opacity(0.6))
                        .font(.system(size: 24))

                    Text("tap_chart_to_select_category".localized)
                        .font(.system(size: 11))
                        .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme).opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .offset(y: 110)
            }
        }
    }
}

// MARK: - Helper Methods
extension MonthlyAnalysisPieChart {
    private func toggleCollapse() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isCollapsed.toggle()
        }
        if isCollapsed {
            onSegmentSelected(nil)
        }
    }

    private func handleSegmentTap(index: Int) {
        if selectedSegment == index {
            onSegmentSelected(nil)
        } else {
            onSegmentSelected(index)
        }
    }

    private func updateSegmentScales(selectedIndex: Int?) {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0)) {
            segmentScales = categoryData.indices.map { index in
                selectedIndex == index ? 1.1 : 1.0
            }
        }
    }

    private func startAngle(for index: Int) -> Angle {
        let previousPercentages = categoryData.prefix(index).reduce(0) { $0 + $1.percentage }
        return Angle.degrees(-90 + (previousPercentages * 360))
    }

    private func endAngle(for index: Int) -> Angle {
        let currentPercentage = categoryData[index].percentage
        let previousPercentages = categoryData.prefix(index).reduce(0) { $0 + $1.percentage }
        return Angle.degrees(-90 + ((previousPercentages + currentPercentage) * 360))
    }
}

struct AnimatedPieSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle
    var animationProgress: Double
    var scale: Double

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(animationProgress, scale) }
        set {
            animationProgress = newValue.first
            scale = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let baseRadius = min(rect.width, rect.height) / 2 - 10
        let radius = baseRadius * scale

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
struct MonthlyAnalysisPieChart_Previews: PreviewProvider {
    static var previews: some View {
        let sampleCategories = Category.getDefaultCategories()
        let sampleCategoryData = [
            CategoryAnalysisData(
                category: sampleCategories[0],
                totalAmount: 500.0,
                expenseCount: 10,
                percentage: 0.4,
                expenses: []
            ),
            CategoryAnalysisData(
                category: sampleCategories[1],
                totalAmount: 300.0,
                expenseCount: 6,
                percentage: 0.35,
                expenses: []
            ),
            CategoryAnalysisData(
                category: sampleCategories[2],
                totalAmount: 200.0,
                expenseCount: 4,
                percentage: 0.25,
                expenses: []
            )
        ]

        VStack(spacing: 20) {
            MonthlyAnalysisPieChart(
                categoryData: sampleCategoryData,
                isDarkTheme: true
            )

            MonthlyAnalysisPieChart(
                categoryData: [],
                isDarkTheme: true
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
