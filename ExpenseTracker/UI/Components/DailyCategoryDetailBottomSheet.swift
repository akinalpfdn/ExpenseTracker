//
//  DailyCategoryDetailBottomSheet.swift
//  ExpenseTracker
//
//  Created by migration from Android DailyCategoryDetailBottomSheet.kt
//

import SwiftUI

enum DailyCategorySortType: String, CaseIterable {
    case amountHighToLow = "AMOUNT_HIGH_TO_LOW"
    case amountLowToHigh = "AMOUNT_LOW_TO_HIGH"
    case timeNewestFirst = "TIME_NEWEST_FIRST"
    case timeOldestFirst = "TIME_OLDEST_FIRST"
    case descriptionAToZ = "DESCRIPTION_A_TO_Z"
    case descriptionZToA = "DESCRIPTION_Z_TO_A"

    var displayName: String {
        switch self {
        case .amountHighToLow:
            return "amount_high_to_low_arrow".localized
        case .amountLowToHigh:
            return "amount_low_to_high_arrow".localized
        case .timeNewestFirst:
            return "time_newest_first_arrow".localized
        case .timeOldestFirst:
            return "time_oldest_first_arrow".localized
        case .descriptionAToZ:
            return "description_a_to_z_arrow".localized
        case .descriptionZToA:
            return "description_z_to_a_arrow".localized
        }
    }
}

struct DailyCategoryDetailBottomSheet: View {
    let category: Category
    let selectedDateExpenses: [Expense]
    let subCategories: [SubCategory]
    let selectedDate: Date
    let defaultCurrency: String
    let isDarkTheme: Bool
    let onDismiss: () -> Void

    @State private var showSortMenu = false
    @State private var currentSortType: DailyCategorySortType = .amountHighToLow

    init(
        category: Category,
        selectedDateExpenses: [Expense],
        subCategories: [SubCategory] = [],
        selectedDate: Date,
        defaultCurrency: String = "₺",
        isDarkTheme: Bool = true,
        onDismiss: @escaping () -> Void = { }
    ) {
        self.category = category
        self.selectedDateExpenses = selectedDateExpenses
        self.subCategories = subCategories
        self.selectedDate = selectedDate
        self.defaultCurrency = defaultCurrency
        self.isDarkTheme = isDarkTheme
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(spacing: 0) {
            dragHandle
            sheetContent
        }
        .background(ThemeColors.getBackgroundColor(isDarkTheme: isDarkTheme))
    }
}

// MARK: - Computed Properties
extension DailyCategoryDetailBottomSheet {
    private var categoryExpenses: [Expense] {
        selectedDateExpenses.filter { expense in
            expense.categoryId == category.id
        }
    }

    private var sortedExpenses: [Expense] {
        switch currentSortType {
        case .amountHighToLow:
            return categoryExpenses.sorted { $0.getAmountInDefaultCurrency(defaultCurrency: defaultCurrency) > $1.getAmountInDefaultCurrency(defaultCurrency: defaultCurrency) }
        case .amountLowToHigh:
            return categoryExpenses.sorted { $0.getAmountInDefaultCurrency(defaultCurrency: defaultCurrency) < $1.getAmountInDefaultCurrency(defaultCurrency: defaultCurrency) }
        case .timeNewestFirst:
            return categoryExpenses.sorted { $0.date > $1.date }
        case .timeOldestFirst:
            return categoryExpenses.sorted { $0.date < $1.date }
        case .descriptionAToZ:
            return categoryExpenses.sorted { $0.description.lowercased() < $1.description.lowercased() }
        case .descriptionZToA:
            return categoryExpenses.sorted { $0.description.lowercased() > $1.description.lowercased() }
        }
    }

    private var totalAmount: Double {
        categoryExpenses.reduce(0) { $0 + $1.getAmountInDefaultCurrency(defaultCurrency: defaultCurrency) }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        formatter.locale = Locale.current
        return formatter.string(from: selectedDate)
    }
}

// MARK: - View Components
extension DailyCategoryDetailBottomSheet {
    private var dragHandle: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme).opacity(0.5))
            .frame(width: 40, height: 4)
            .padding(.top, 8)
    }

    private var sheetContent: some View {
        VStack(spacing: 16) {
            headerSection
            totalAmountCard
            expensesSection
        }
        .padding(16)
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

                Text(formattedDate)
                    .font(.system(size: 14))
                    .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
            }

            Spacer()

            sortButton
        }
    }

    private var sortButton: some View {
        Menu {
            ForEach(DailyCategorySortType.allCases, id: \.self) { sortType in
                Button(action: {
                    currentSortType = sortType
                }) {
                    Text(sortType.displayName)
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                .font(.system(size: 16))
                .padding(8)
        }
    }

    private var totalAmountCard: some View {
        HStack {
            Text("total_spending".localized)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            Spacer()

            Text("\(NumberFormatter.formatAmount(totalAmount)) \(defaultCurrency)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(category.getColor())
        }
        .padding(16)
        .background(category.getColor().opacity(0.1))
        .cornerRadius(12)
    }

    private var expensesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if sortedExpenses.isEmpty {
                emptyStateView
            } else {
                expensesList
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Text("no_expenses_in_category".localized)
                .font(.system(size: 16))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
    }

    private var expensesList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(sortedExpenses.count) \("expense_singular".localized)")
                .font(.system(size: 14))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(sortedExpenses, id: \.id) { expense in
                        DailyExpenseCard(
                            expense: expense,
                            subCategory: subCategories.first { $0.id == expense.subCategoryId },
                            category: category,
                            defaultCurrency: defaultCurrency,
                            isDarkTheme: isDarkTheme
                        )
                    }
                }
            }
        }
    }
}

struct DailyExpenseCard: View {
    let expense: Expense
    let subCategory: SubCategory?
    let category: Category
    let defaultCurrency: String
    let isDarkTheme: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.description.isEmpty ? "no_description".localized : expense.description)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                    .lineLimit(2)

                if let subCategory = subCategory {
                    Text(subCategory.name)
                        .font(.system(size: 12))
                        .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                }
            }

            Spacer()

            Text("\(NumberFormatter.formatAmount(expense.getAmountInDefaultCurrency(defaultCurrency: defaultCurrency))) \(defaultCurrency)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(category.getColor())
        }
        .padding(16)
        .background(ThemeColors.getCardBackgroundColor(isDarkTheme: isDarkTheme))
        .cornerRadius(12)
    }
}

// MARK: - Preview
struct DailyCategoryDetailBottomSheet_Previews: PreviewProvider {
    static var previews: some View {
        let sampleCategory = Category.getDefaultCategories()[0]
        let sampleSubCategories = SubCategory.getDefaultSubCategories()
        let sampleExpenses = [
            Expense(
                amount: 150.0,
                currency: "₺",
                categoryId: sampleCategory.id,
                subCategoryId: sampleSubCategories[0].id,
                description: "Lunch at restaurant",
                date: Date(),
                dailyLimitAtCreation: 200.0,
                monthlyLimitAtCreation: 5000.0
            ),
            Expense(
                amount: 75.0,
                currency: "₺",
                categoryId: sampleCategory.id,
                subCategoryId: sampleSubCategories[1].id,
                description: "Coffee break",
                date: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
                dailyLimitAtCreation: 200.0,
                monthlyLimitAtCreation: 5000.0
            )
        ]

        DailyCategoryDetailBottomSheet(
            category: sampleCategory,
            selectedDateExpenses: sampleExpenses,
            subCategories: sampleSubCategories,
            selectedDate: Date(),
            defaultCurrency: "₺",
            isDarkTheme: true
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}