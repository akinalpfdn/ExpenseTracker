//
//  ExpenseRowView.swift
//  ExpenseTracker
//
//  Created by migration from Android ExpenseRowView.kt
//

import SwiftUI

struct ExpenseRowView: View {
    let expense: Expense
    let onUpdate: (Expense) -> Void
    let onEditingChanged: (Bool) -> Void
    let onDelete: () -> Void
    let isCurrentlyEditing: Bool
    let dailyExpenseRatio: Double
    let defaultCurrency: String
    let isDarkTheme: Bool
    let categories: [Category]
    let subCategories: [SubCategory]

    @State private var isEditing = false
    @State private var editAmount = ""
    @State private var editDescription = ""
    @State private var editExchangeRate = ""
    @State private var showDeleteConfirmation = false

    init(
        expense: Expense,
        onUpdate: @escaping (Expense) -> Void,
        onEditingChanged: @escaping (Bool) -> Void,
        onDelete: @escaping () -> Void,
        isCurrentlyEditing: Bool,
        dailyExpenseRatio: Double,
        defaultCurrency: String,
        isDarkTheme: Bool = true,
        categories: [Category],
        subCategories: [SubCategory]
    ) {
        self.expense = expense
        self.onUpdate = onUpdate
        self.onEditingChanged = onEditingChanged
        self.onDelete = onDelete
        self.isCurrentlyEditing = isCurrentlyEditing
        self.dailyExpenseRatio = dailyExpenseRatio
        self.defaultCurrency = defaultCurrency
        self.isDarkTheme = isDarkTheme
        self.categories = categories
        self.subCategories = subCategories
    }

    var body: some View {
        VStack(spacing: 0) {
            mainCardContent
            progressBar
        }
        .onAppear {
            setupEditFields()
        }
        .onChange(of: isCurrentlyEditing) { newValue in
            withAnimation(.easeInOut(duration: 0.3)) {
                isEditing = newValue
            }
            onEditingChanged(isEditing)
            if newValue {
                setupEditFields()
            }
        }
        .onChange(of: expense) { _ in
            if isEditing {
                setupEditFields()
            }
        }
        .alert("delete_expense".localized, isPresented: $showDeleteConfirmation) {
            Button("delete".localized, role: .destructive) {
                onDelete()
            }
            Button("cancel".localized, role: .cancel) { }
        } message: {
            Text("delete_expense_confirmation".localized)
        }
    }
}

// MARK: - Main Card Content
extension ExpenseRowView {
    private var mainCardContent: some View {
        ZStack {
            cardBackground

            VStack(spacing: 0) {
                mainRow

                if isEditing {
                    editingSection
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(ThemeColors.getCardBackgroundColor(isDarkTheme: isDarkTheme))
            .onTapGesture {
                handleCardTap()
            }
            .onLongPressGesture {
                showDeleteConfirmation = true
            }
    }
}

// MARK: - Main Row
extension ExpenseRowView {
    private var mainRow: some View {
        HStack(alignment: .center, spacing: 12) {
            categoryIcon
            categoryInfo
            Spacer()
            amountDetails
        }
        .padding(12)
    }

    private var categoryIcon: some View {
        ZStack {
            Circle()
                .fill((category?.getColor() ?? .gray).opacity(0.2))
                .frame(width: 32, height: 32)

            Image(systemName: category?.getIcon() ?? "square.grid.2x2")
                .foregroundColor(category?.getColor() ?? .gray)
                .font(.system(size: 16))
        }
    }

    private var categoryInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(subCategory?.name ?? "unknown".localized)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                .lineLimit(1)

            if !expense.description.isEmpty {
                Text(expense.description)
                    .font(.system(size: 14))
                    .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                    .lineLimit(1)
            }
        }
    }

    private var amountDetails: some View {
        VStack(alignment: .trailing, spacing: 2) {
            amountText
            exchangeRateInfo
            dateText
            recurrenceInfo
        }
    }
}

// MARK: - Amount Details Components
extension ExpenseRowView {
    private var amountText: some View {
        Text("\(expense.currency) \(NumberFormatter.formatAmount(expense.amount))")
            .font(.system(size: 17, weight: .bold))
            .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
    }

    @ViewBuilder
    private var exchangeRateInfo: some View {
        if let exchangeRate = expense.exchangeRate{
            if exchangeRate>0{
                VStack(alignment: .trailing, spacing: 1) {
                    Text(expense.currency + ": \(String(format: "%.2f", exchangeRate)) " + defaultCurrency)
                        .font(.system(size: 12))
                        .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                    
                    Text("\(defaultCurrency) \(NumberFormatter.formatAmount(expense.getAmountInDefaultCurrency(defaultCurrency: defaultCurrency)))")
                        .font(.system(size: 12))
                        .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                }
            }}
    }

    private var dateText: some View {
        Text(formattedDate)
            .font(.system(size: 13))
            .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
    }

    @ViewBuilder
    private var recurrenceInfo: some View {
        if expense.recurrenceType != .NONE {
            HStack(spacing: 4) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 10))
                    .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))

                Text(recurrenceText)
                    .font(.system(size: 11))
                    .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
            }
        }
    }
}

// MARK: - Editing Section
extension ExpenseRowView {
    private var editingSection: some View {
        VStack(spacing: 8) {
            Divider()
                .padding(.horizontal, 12)

            VStack(spacing: 8) {
                editingFields
                actionButtons
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }

    private var editingFields: some View {
        VStack(spacing: 8) {
            amountField
            descriptionField

            if expense.currency != defaultCurrency {
                exchangeRateField
            }
        }
    }

    private var amountField: some View {
        CustomTextField(
            text: $editAmount,
            placeholder: "amount".localized,
            keyboardType: .decimalPad,
            isDarkTheme: isDarkTheme
        )
        .onChange(of: editAmount) { newValue in
            // Filter input to only allow numbers, comma and period
            let filtered = newValue.filter { "0123456789.,".contains($0) }

            // Limit to 12 characters
            let limited = String(filtered.prefix(12))

            // Limit to one decimal separator
            let components = limited.components(separatedBy: CharacterSet(charactersIn: ".,"))
            if components.count > 2 {
                editAmount = components[0] + "," + (components[1].isEmpty ? "" : components[1])
            } else {
                editAmount = limited
            }
        }
    }

    private var descriptionField: some View {
        CustomTextField(
            text: $editDescription,
            placeholder: "description".localized,
            isDarkTheme: isDarkTheme
        )
    }

    private var exchangeRateField: some View {
        CustomTextField(
            text: $editExchangeRate,
            placeholder: "exchange_rate_field".localized,
            keyboardType: .decimalPad,
            isDarkTheme: isDarkTheme
        )
        .onChange(of: editExchangeRate) { newValue in
            // Filter input to only allow numbers, comma and period
            let filtered = newValue.filter { "0123456789.,".contains($0) }

            // Limit to 12 characters
            let limited = String(filtered.prefix(12))

            // Limit to one decimal separator
            let components = limited.components(separatedBy: CharacterSet(charactersIn: ".,"))
            if components.count > 2 {
                editExchangeRate = components[0] + "," + (components[1].isEmpty ? "" : components[1])
            } else {
                editExchangeRate = limited
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 8) {
            deleteButton
            saveButton
        }
    }

    private var deleteButton: some View {
        Button(action: {
            showDeleteConfirmation = true
        }) {
            HStack(spacing: 4) {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                Text("delete".localized)
                    .font(.system(size: 12))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(Color.red)
            .cornerRadius(18)
        }
    }

    private var saveButton: some View {
        Button(action: {
            saveChanges()
        }) {
            HStack(spacing: 4) {
                Image(systemName: "checkmark")
                    .font(.system(size: 16))
                Text("save".localized)
                    .font(.system(size: 12))
            }
            .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(AppColors.primaryOrange)
            .cornerRadius(18)
        }
    }
}

// MARK: - Progress Bar
extension ExpenseRowView {
    private var progressBar: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(height: 2)
            .overlay(progressBarFill, alignment: .leading)
    }

    private var progressBarFill: some View {
        Rectangle()
            .fill(category?.getColor() ?? .gray)
            .frame(width: UIScreen.main.bounds.width * dailyExpenseRatio)
    }
}

// MARK: - Computed Properties
extension ExpenseRowView {
    private var category: Category? {
        categories.first { $0.id == expense.categoryId }
    }

    private var subCategory: SubCategory? {
        subCategories.first { $0.id == expense.subCategoryId }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: expense.date)
    }

    private var recurrenceText: String {
        switch expense.recurrenceType {
        case .DAILY:
            return "daily".localized
        case .WEEKDAYS:
            return "weekdays".localized
        case .WEEKLY:
            return "weekly".localized
        case .MONTHLY:
            return "monthly".localized
        case .NONE:
            return ""
        }
    }
}

// MARK: - Helper Methods
extension ExpenseRowView {
    private func handleCardTap() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if isEditing {
                isEditing = false
                onEditingChanged(false)
                setupEditFields()
            } else {
                isEditing = true
                onEditingChanged(true)
            }
        }
    }

    private func setupEditFields() {
        editAmount = String(expense.amount)
        editDescription = expense.description
        editExchangeRate = expense.exchangeRate?.description ?? ""
    }

    private func saveChanges() {
        guard let newAmount = Double(editAmount), newAmount > 0 else { return }

        let updatedExpense = Expense(
            id: expense.id,
            amount: newAmount,
            currency: expense.currency,
            categoryId: expense.categoryId,
            subCategoryId: expense.subCategoryId,
            description: editDescription,
            date: expense.date,
            dailyLimitAtCreation: expense.dailyLimitAtCreation,
            monthlyLimitAtCreation: expense.monthlyLimitAtCreation,
            exchangeRate: expense.currency != defaultCurrency ? Double(editExchangeRate) : nil,
            recurrenceType: expense.recurrenceType,
            endDate: expense.endDate,
            recurrenceGroupId: expense.recurrenceGroupId
        )

        onUpdate(updatedExpense)

        withAnimation(.easeInOut(duration: 0.3)) {
            isEditing = false
        }
        onEditingChanged(false)
    }
}

// MARK: - Custom TextField Component
struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    let isDarkTheme: Bool

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboardType)
            .textFieldStyle(PlainTextFieldStyle())
            .padding(.horizontal, 12)
            .frame(height: 40)
            .background(ThemeColors.getInputBackgroundColor(isDarkTheme: isDarkTheme))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme), lineWidth: 1)
            )
            .cornerRadius(12)
    }
}

// MARK: - Preview
struct ExpenseRowView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleExpense = Expense(
            amount: 125.50,
            currency: "₺",
            categoryId: "food",
            subCategoryId: "restaurant",
            description: "Lunch at restaurant",
            date: Date(),
            dailyLimitAtCreation: 500.0,
            monthlyLimitAtCreation: 5000.0
        )

        let sampleCategories = Category.getDefaultCategories()
        let sampleSubCategories = SubCategory.getDefaultSubCategories()

        ExpenseRowView(
            expense: sampleExpense,
            onUpdate: { _ in },
            onEditingChanged: { _ in },
            onDelete: { },
            isCurrentlyEditing: false,
            dailyExpenseRatio: 0.3,
            defaultCurrency: "₺",
            categories: sampleCategories,
            subCategories: sampleSubCategories
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
