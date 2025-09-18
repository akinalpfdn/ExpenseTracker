//
//  MonthlyAnalysisPieChart.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import SwiftUI
import Charts

struct MonthlyAnalysisPieChart: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var expenseViewModel: ExpenseViewModel

    let expenses: [Expense]
    let selectedMonth: Date

    @State private var selectedCategory: String? = nil
    @State private var showingCategoryDetails = false
    @State private var animateChart = false

    private var monthlyData: [CategoryData] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: selectedMonth)?.start ?? selectedMonth
        let endOfMonth = calendar.dateInterval(of: .month, for: selectedMonth)?.end ?? selectedMonth

        let monthExpenses = expenses.filter { expense in
            expense.date >= startOfMonth && expense.date < endOfMonth
        }

        let groupedByCategory = Dictionary(grouping: monthExpenses) { $0.categoryId }

        return groupedByCategory.map { categoryId, categoryExpenses in
            let totalAmount = categoryExpenses.reduce(0) { $0 + $1.amount }
            let percentage = monthExpenses.isEmpty ? 0 : (totalAmount / monthExpenses.totalAmount) * 100

            return CategoryData(
                id: categoryId,
                name: getCategoryName(categoryId),
                amount: totalAmount,
                percentage: percentage,
                expenseCount: categoryExpenses.count,
                color: getCategoryColor(categoryId)
            )
        }
        .sorted { $0.amount > $1.amount }
        .prefix(8) // Show top 8 categories
        .map { $0 }
    }

    private var totalAmount: Double {
        monthlyData.reduce(0) { $0 + $1.amount }
    }

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return formatter.string(from: selectedMonth)
    }

    var body: some View {
        VStack(spacing: 20) {
            headerView

            if monthlyData.isEmpty {
                emptyStateView
            } else {
                chartView
                legendView
            }
        }
        .padding()
        .background(ThemeColors.cardBackgroundColor(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .sheet(isPresented: $showingCategoryDetails) {
            if let selectedCategory = selectedCategory {
                CategoryDetailBottomSheet(
                    categoryId: selectedCategory,
                    expenses: expenses,
                    month: selectedMonth
                )
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                animateChart = true
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .font(AppTypography.bodyLarge)
                    .foregroundColor(AppColors.primaryOrange)

                Text(L("monthly_analysis"))
                    .font(AppTypography.cardTitle)
                    .foregroundColor(ThemeColors.textColor(for: colorScheme))

                Spacer()

                Text(monthName)
                    .font(AppTypography.labelMedium)
                    .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
            }

            HStack {
                Text(L("total_spent"))
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

                Spacer()

                Text(formatCurrency(totalAmount))
                    .font(AppTypography.expenseAmount)
                    .foregroundColor(ThemeColors.textColor(for: colorScheme))
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.pie")
                .font(.system(size: 60))
                .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

            Text(L("no_expenses_this_month"))
                .font(AppTypography.bodyLarge)
                .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
    }

    private var chartView: some View {
        Chart(monthlyData, id: \.id) { categoryData in
            SectorMark(
                angle: .value(L("amount"), animateChart ? categoryData.amount : 0),
                innerRadius: .ratio(0.4),
                angularInset: 2
            )
            .foregroundStyle(categoryData.color.gradient)
            .opacity(selectedCategory == nil || selectedCategory == categoryData.id ? 1.0 : 0.3)
            .scaleEffect(selectedCategory == categoryData.id ? 1.05 : 1.0)
        }
        .frame(height: 200)
        .chartBackground { chartProxy in
            GeometryReader { geometry in
                if let anchor = chartProxy.plotAreaFrame {
                    let frame = geometry[anchor]

                    VStack(spacing: 4) {
                        Text(L("total"))
                            .font(AppTypography.labelMedium)
                            .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

                        Text(formatCurrency(totalAmount))
                            .font(AppTypography.cardTitle)
                            .foregroundColor(ThemeColors.textColor(for: colorScheme))
                    }
                    .position(x: frame.midX, y: frame.midY)
                }
            }
        }
        .chartAngleSelection(value: .constant(nil))
        .onTapGesture { location in
            handleChartTap(at: location)
        }
        .animation(.easeInOut(duration: 0.3), value: selectedCategory)
    }

    private var legendView: some View {
        VStack(spacing: 8) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(monthlyData, id: \.id) { categoryData in
                    legendItem(for: categoryData)
                }
            }
        }
    }

    private func legendItem(for categoryData: CategoryData) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(categoryData.color)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(categoryData.name)
                    .font(AppTypography.labelMedium)
                    .foregroundColor(ThemeColors.textColor(for: colorScheme))
                    .lineLimit(1)

                HStack {
                    Text(formatCurrency(categoryData.amount))
                        .font(AppTypography.labelSmall)
                        .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

                    Text("(\(String(format: "%.1f", categoryData.percentage))%)")
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.primaryOrange)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(selectedCategory == categoryData.id ?
                      categoryData.color.opacity(0.1) :
                      Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(selectedCategory == categoryData.id ?
                        categoryData.color.opacity(0.3) :
                        Color.clear, lineWidth: 1)
        )
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                if selectedCategory == categoryData.id {
                    selectedCategory = nil
                } else {
                    selectedCategory = categoryData.id
                }
            }
        }
        .onLongPressGesture {
            selectedCategory = categoryData.id
            showingCategoryDetails = true
        }
    }

    // MARK: - Helper Functions

    private func handleChartTap(at location: CGPoint) {
        // Chart tap handling would require more complex geometric calculations
        // For now, we'll use the legend for interaction
    }

    private func getCategoryName(_ categoryId: String) -> String {
        // This would typically come from the category repository
        return expenseViewModel.availableCategories.first { $0.id == categoryId }?.name ?? L("unknown_category")
    }

    private func getCategoryColor(_ categoryId: String) -> Color {
        let colors: [Color] = [
            AppColors.primaryOrange,
            AppColors.primaryRed,
            AppColors.successGreen,
            .blue,
            .purple,
            .pink,
            .yellow,
            .cyan,
            .indigo,
            .mint
        ]

        let hash = categoryId.hashValue
        return colors[abs(hash) % colors.count]
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = expenseViewModel.settingsManager?.currency ?? "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"
    }
}

// MARK: - Supporting Types

struct CategoryData {
    let id: String
    let name: String
    let amount: Double
    let percentage: Double
    let expenseCount: Int
    let color: Color
}

// MARK: - Preview

#if DEBUG
struct MonthlyAnalysisPieChart_Previews: PreviewProvider {
    static var previews: some View {
        let mockExpenses = [
            Expense(amount: 500, categoryId: "food", subCategoryId: "restaurants", description: "Dinner"),
            Expense(amount: 300, categoryId: "transport", subCategoryId: "fuel", description: "Gas"),
            Expense(amount: 200, categoryId: "shopping", subCategoryId: "clothes", description: "Shirt")
        ]

        MonthlyAnalysisPieChart(
            expenseViewModel: ExpenseViewModel.preview,
            expenses: mockExpenses,
            selectedMonth: Date()
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif