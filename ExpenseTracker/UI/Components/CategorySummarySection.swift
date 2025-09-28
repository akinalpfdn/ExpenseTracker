//
//  CategorySummarySection.swift
//  ExpenseTracker
//
//  Created by migration from Android CategorySummarySection.kt
//

import SwiftUI

struct SubCategoryAnalysisData: Identifiable, Equatable {
    let id = UUID()
    let subCategory: SubCategory
    let parentCategory: Category
    let totalAmount: Double
    let expenseCount: Int
    let percentage: Double
    let expenses: [Expense]
}

struct CategorySummarySection: View {
    let categoryData: [CategoryAnalysisData]
    let subCategoryData: [SubCategoryAnalysisData]
    let totalAmount: Double
    let defaultCurrency: String
    let isDarkTheme: Bool
    let onCategoryClick: (CategoryAnalysisData) -> Void
    let onSubCategoryClick: (SubCategoryAnalysisData) -> Void

    @State private var showMainCategories = true

    init(
        categoryData: [CategoryAnalysisData],
        subCategoryData: [SubCategoryAnalysisData],
        totalAmount: Double,
        defaultCurrency: String = "₺",
        isDarkTheme: Bool = true,
        onCategoryClick: @escaping (CategoryAnalysisData) -> Void = { _ in },
        onSubCategoryClick: @escaping (SubCategoryAnalysisData) -> Void = { _ in }
    ) {
        self.categoryData = categoryData
        self.subCategoryData = subCategoryData
        self.totalAmount = totalAmount
        self.defaultCurrency = defaultCurrency
        self.isDarkTheme = isDarkTheme
        self.onCategoryClick = onCategoryClick
        self.onSubCategoryClick = onSubCategoryClick
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            categoryTypeSelector
            categoryListSection
        }
        .padding(6)
    }
}

// MARK: - Section Components
extension CategorySummarySection {
    private var headerSection: some View {
        HStack {
            Text("category_details".localized)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            Spacer()

            Text("\(defaultCurrency) \(NumberFormatter.formatAmount(totalAmount))")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppColors.primaryOrange)
        }
        .padding(.bottom, 18)
    }

    private var categoryTypeSelector: some View {
        HStack(spacing: 24) {
            categoryTypeOption(
                title: "main_categories".localized,
                isSelected: showMainCategories,
                action: { showMainCategories = true }
            )

            categoryTypeOption(
                title: "sub_categories".localized,
                isSelected: !showMainCategories,
                action: { showMainCategories = false }
            )

            Spacer()
        }
        .padding(.bottom, 12)
    }

    private func categoryTypeOption(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? AppColors.primaryOrange : ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme), lineWidth: 2)
                        .frame(width: 20, height: 20)

                    if isSelected {
                        Circle()
                            .fill(AppColors.primaryOrange)
                            .frame(width: 12, height: 12)
                    }
                }

                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var categoryListSection: some View {
        LazyVStack(spacing: 4) {
            if showMainCategories {
                ForEach(categoryData, id: \.id) { data in
                    CategorySummaryRow(
                        categoryData: data,
                        defaultCurrency: defaultCurrency,
                        isDarkTheme: isDarkTheme,
                        onClick: { onCategoryClick(data) }
                    )
                }
            } else {
                ForEach(subCategoryData, id: \.id) { data in
                    SubCategorySummaryRow(
                        subCategoryData: data,
                        defaultCurrency: defaultCurrency,
                        isDarkTheme: isDarkTheme,
                        onClick: { onSubCategoryClick(data) }
                    )
                }
            }
        }
    }
}

struct CategorySummaryRow: View {
    let categoryData: CategoryAnalysisData
    let defaultCurrency: String
    let isDarkTheme: Bool
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            rowContent
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Category Row Components
extension CategorySummaryRow {
    private var rowContent: some View {
        HStack {
            categoryInfo
            Spacer()
            amountAndArrow
        }
        .padding(12)
        .background(categoryData.category.getColor().opacity(0.1))
        .cornerRadius(12)
    }

    private var categoryInfo: some View {
        HStack(spacing: 12) {
            categoryIcon
            categoryDetails
        }
    }

    private var categoryIcon: some View {
        ZStack {
            Circle()
                .fill(categoryData.category.getColor().opacity(0.2))
                .frame(width: 32, height: 32)

            Image(systemName: categoryData.category.getIcon())
                .foregroundColor(categoryData.category.getColor())
                .font(.system(size: 16))
        }
    }

    private var categoryDetails: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(categoryData.category.name)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                .lineLimit(1)

            Text("\(categoryData.expenseCount) \("expense_lowercase".localized) • \(String(format: "%.1f", categoryData.percentage * 100))%")
                .font(.system(size: 14))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
        }
    }

    private var amountAndArrow: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("\(defaultCurrency) \(NumberFormatter.formatAmount(categoryData.totalAmount))")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            Image(systemName: "chevron.right")
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                .font(.system(size: 12))
        }
    }
}

struct SubCategorySummaryRow: View {
    let subCategoryData: SubCategoryAnalysisData
    let defaultCurrency: String
    let isDarkTheme: Bool
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            rowContent
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Sub Category Row Components
extension SubCategorySummaryRow {
    private var rowContent: some View {
        HStack {
            subCategoryInfo
            Spacer()
            amountAndArrow
        }
        .padding(12)
        .background(subCategoryData.parentCategory.getColor().opacity(0.1))
        .cornerRadius(12)
    }

    private var subCategoryInfo: some View {
        HStack(spacing: 12) {
            subCategoryIcon
            subCategoryDetails
        }
    }

    private var subCategoryIcon: some View {
        ZStack {
            Circle()
                .fill(subCategoryData.parentCategory.getColor().opacity(0.2))
                .frame(width: 32, height: 32)

            Image(systemName: subCategoryData.parentCategory.getIcon())
                .foregroundColor(subCategoryData.parentCategory.getColor())
                .font(.system(size: 16))
        }
    }

    private var subCategoryDetails: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(subCategoryData.subCategory.name)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                .lineLimit(1)

            Text("\(subCategoryData.expenseCount) \("expense_lowercase".localized) • \(String(format: "%.1f", subCategoryData.percentage * 100))%")
                .font(.system(size: 14))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
        }
    }

    private var amountAndArrow: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("\(defaultCurrency) \(NumberFormatter.formatAmount(subCategoryData.totalAmount))")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            Image(systemName: "chevron.right")
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                .font(.system(size: 12))
        }
    }
}

// MARK: - Preview
struct CategorySummarySection_Previews: PreviewProvider {
    static var previews: some View {
        let sampleCategories = Category.getDefaultCategories()
        let sampleSubCategories = SubCategory.getDefaultSubCategories()

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
            )
        ]

        let sampleSubCategoryData = [
            SubCategoryAnalysisData(
                subCategory: sampleSubCategories[0],
                parentCategory: sampleCategories[0],
                totalAmount: 250.0,
                expenseCount: 5,
                percentage: 0.2,
                expenses: []
            ),
            SubCategoryAnalysisData(
                subCategory: sampleSubCategories[1],
                parentCategory: sampleCategories[0],
                totalAmount: 250.0,
                expenseCount: 5,
                percentage: 0.2,
                expenses: []
            )
        ]

        CategorySummarySection(
            categoryData: sampleCategoryData,
            subCategoryData: sampleSubCategoryData,
            totalAmount: 800.0,
            defaultCurrency: "₺",
            isDarkTheme: true
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}