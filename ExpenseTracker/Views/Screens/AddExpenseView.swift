//
//  AddExpenseView.swift
//  ExpenseTracker
//
//  Created by migration from Android AddExpenseScreen.kt
//

import SwiftUI

struct AddExpenseView: View {
    @EnvironmentObject var viewModel: ExpenseViewModel

    let selectedDate: Date
    let defaultCurrency: String
    let dailyLimit: String
    let monthlyLimit: String
    let isDarkTheme: Bool
    let onExpenseAdded: (Expense) -> Void
    let onDismiss: () -> Void
    let editingExpense: Expense?

    @State private var amount = ""
    @State private var selectedCurrency: String
    @State private var selectedSubCategoryId = ""
    @State private var description = ""
    @State private var exchangeRate = ""
    @State private var showCurrencyMenu = false
    @State private var showCategoryMenu = false
    @State private var showRecurrenceMenu = false
    @State private var categorySearchText = ""
    @State private var selectedCategoryFilter = "ALL"
    @State private var selectedRecurrenceType: RecurrenceType
    @State private var endDate: Date
    @State private var showEndDatePicker = false

    private let currencies = ["₺", "$", "€", "£"]

    private var recurrenceTypes: [(RecurrenceType, String)] {
        [
            (.NONE, "one_time".localized),
            (.DAILY, "every_day".localized),
            (.WEEKDAYS, "weekdays_only".localized),
            (.WEEKLY, "once_per_week".localized),
            (.MONTHLY, "once_per_month".localized)
        ]
    }

    init(selectedDate: Date, defaultCurrency: String, dailyLimit: String, monthlyLimit: String, isDarkTheme: Bool = true, onExpenseAdded: @escaping (Expense) -> Void, onDismiss: @escaping () -> Void, editingExpense: Expense? = nil) {
        self.selectedDate = selectedDate
        self.defaultCurrency = defaultCurrency
        self.dailyLimit = dailyLimit
        self.monthlyLimit = monthlyLimit
        self.isDarkTheme = isDarkTheme
        self.onExpenseAdded = onExpenseAdded
        self.onDismiss = onDismiss
        self.editingExpense = editingExpense

        self._amount = State(initialValue: editingExpense?.amount.description ?? "")
        self._selectedCurrency = State(initialValue: editingExpense?.currency ?? defaultCurrency)
        self._selectedSubCategoryId = State(initialValue: editingExpense?.subCategoryId ?? "")
        self._description = State(initialValue: editingExpense?.description ?? "")
        self._exchangeRate = State(initialValue: editingExpense?.exchangeRate?.description ?? "")
        self._selectedRecurrenceType = State(initialValue: editingExpense?.recurrenceType ?? .NONE)
        self._endDate = State(initialValue: editingExpense?.endDate ?? Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date())
    }

    private var selectedCategoryId: String {
        viewModel.subCategories.first { $0.id == selectedSubCategoryId }?.categoryId ?? ""
    }

    private var filteredSubCategories: [SubCategory] {
        var filtered = viewModel.subCategories

        if !categorySearchText.isEmpty {
            filtered = filtered.filter { subCategory in
                subCategory.name.localizedCaseInsensitiveContains(categorySearchText)
            }
        }

        return filtered.sorted { $0.name < $1.name }
    }

    private var isFormValid: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else { return false }
        guard !selectedSubCategoryId.isEmpty else { return false }

        if selectedCurrency != defaultCurrency {
            guard let exchangeRateValue = Double(exchangeRate), exchangeRateValue > 0 else { return false }
        }

        return true
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                formSection
                buttonsSection
            }
            .padding(20)
        }
        .background(ThemeColors.getBackgroundColor(isDarkTheme: isDarkTheme))
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
            initializeDefaultValues()
        }
        .sheet(isPresented: $showEndDatePicker) {
            endDatePickerSheet
        }
    }
}

// MARK: - View Components
extension AddExpenseView {
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(editingExpense != nil ? "edit_expense".localized : "new_expense".localized)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                .font(.system(size: 16))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
        }
    }

    private var formSection: some View {
        VStack(spacing: 20) {
            amountAndCurrencyRow
            categorySection
            descriptionSection

            if selectedCurrency != defaultCurrency {
                exchangeRateSection
            }

            recurrenceSection

            if selectedRecurrenceType != .NONE {
                endDateSection
            }
        }
    }

    private var amountAndCurrencyRow: some View {
        HStack(spacing: 12) {
            // Amount field
            VStack(alignment: .leading, spacing: 4) {
                Text("amount".localized)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

                TextField("expense_amount_placeholder".localized, text: $amount)
                    .textFieldStyle(CustomTextFieldStyle(isDarkTheme: isDarkTheme))
                    .keyboardType(.decimalPad)
                    .onChange(of: amount) { newValue in
                        // Filter input to only allow numbers, comma and period
                        let filtered = newValue.filter { "0123456789.,".contains($0) }

                        // Limit to one decimal separator
                        let components = filtered.components(separatedBy: CharacterSet(charactersIn: ".,"))
                        if components.count > 2 {
                            amount = components[0] + "," + (components[1].isEmpty ? "" : components[1])
                        } else {
                            amount = filtered
                        }
                    }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Currency selector
            VStack(alignment: .leading, spacing: 4) {
                Text("currency".localized)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

                Menu {
                    ForEach(currencies, id: \.self) { currency in
                        Button(currency) {
                            selectedCurrency = currency
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedCurrency)
                            .font(.system(size: 14))
                            .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                    }
                    .padding(16)
                    .background(ThemeColors.getInputBackgroundColor(isDarkTheme: isDarkTheme))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme), lineWidth: 1)
                    )
                }
            }
            .frame(width: 80)
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("category".localized)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            Button(action: { showCategoryMenu = true }) {
                HStack {
                    Text(viewModel.subCategories.first { $0.id == selectedSubCategoryId }?.name ?? "select_category".localized)
                        .font(.system(size: 14))
                        .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                }
                .padding(16)
                .background(ThemeColors.getInputBackgroundColor(isDarkTheme: isDarkTheme))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme), lineWidth: 1)
                )
            }
        }
        .sheet(isPresented: $showCategoryMenu) {
            categorySelectionSheet
        }
    }

    private var categorySelectionSheet: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Search field
                TextField("search_categories".localized, text: $categorySearchText)
                    .textFieldStyle(CustomTextFieldStyle(isDarkTheme: isDarkTheme))
                    .padding(.horizontal)

                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(
                            text: "all".localized,
                            isSelected: selectedCategoryFilter == "ALL",
                            isDarkTheme: isDarkTheme
                        ) {
                            selectedCategoryFilter = "ALL"
                        }

                        ForEach(viewModel.categories, id: \.id) { category in
                            FilterChip(
                                text: category.name,
                                isSelected: selectedCategoryFilter == category.id,
                                isDarkTheme: isDarkTheme
                            ) {
                                selectedCategoryFilter = category.id
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Subcategories list
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredSubCategoriesWithFilter, id: \.id) { subCategory in
                            Button(action: {
                                selectedSubCategoryId = subCategory.id
                                showCategoryMenu = false
                                categorySearchText = ""
                                selectedCategoryFilter = "ALL"
                            }) {
                                HStack {
                                    // Category color indicator
                                    if let category = viewModel.categories.first(where: { $0.id == subCategory.categoryId }) {
                                        Circle()
                                            .fill(category.getColor())
                                            .frame(width: 12, height: 12)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(subCategory.name)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

                                        if let category = viewModel.categories.first(where: { $0.id == subCategory.categoryId }) {
                                            Text(category.name)
                                                .font(.system(size: 12))
                                                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                                        }
                                    }

                                    Spacer()

                                    if selectedSubCategoryId == subCategory.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(AppColors.primaryOrange)
                                            .font(.system(size: 14, weight: .bold))
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    selectedSubCategoryId == subCategory.id ?
                                    AppColors.primaryOrange.opacity(0.1) :
                                    Color.clear
                                )
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .navigationTitle("select_category".localized)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("done".localized) {
                    showCategoryMenu = false
                    categorySearchText = ""
                    selectedCategoryFilter = "ALL"
                }
            )
            .background(ThemeColors.getBackgroundColor(isDarkTheme: isDarkTheme))
        }
    }

    private var filteredSubCategoriesWithFilter: [SubCategory] {
        var filtered = viewModel.subCategories

        // Apply category filter
        if selectedCategoryFilter != "ALL" {
            filtered = filtered.filter { $0.categoryId == selectedCategoryFilter }
        }

        // Apply search filter
        if !categorySearchText.isEmpty {
            filtered = filtered.filter { subCategory in
                subCategory.name.localizedCaseInsensitiveContains(categorySearchText) ||
                (viewModel.categories.first { $0.id == subCategory.categoryId }?.name.localizedCaseInsensitiveContains(categorySearchText) ?? false)
            }
        }

        return filtered.sorted { $0.name < $1.name }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("description".localized)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            TextField("optional".localized, text: $description)
                .textFieldStyle(CustomTextFieldStyle(isDarkTheme: isDarkTheme))
        }
    }

    private var exchangeRateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("exchange_rate".localized)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            TextField("1.0", text: $exchangeRate)
                .textFieldStyle(CustomTextFieldStyle(isDarkTheme: isDarkTheme))
                .keyboardType(.decimalPad)
                .onChange(of: exchangeRate) { newValue in
                    // Filter input to only allow numbers, comma and period
                    let filtered = newValue.filter { "0123456789.,".contains($0) }

                    // Limit to one decimal separator
                    let components = filtered.components(separatedBy: CharacterSet(charactersIn: ".,"))
                    if components.count > 2 {
                        exchangeRate = components[0] + "," + (components[1].isEmpty ? "" : components[1])
                    } else {
                        exchangeRate = filtered
                    }
                }
        }
    }

    private var recurrenceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("recurrence".localized)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            Menu {
                ForEach(recurrenceTypes, id: \.0) { type, name in
                    Button(name) {
                        selectedRecurrenceType = type
                    }
                }
            } label: {
                HStack {
                    Text(recurrenceTypes.first { $0.0 == selectedRecurrenceType }?.1 ?? "one_time".localized)
                        .font(.system(size: 14))
                        .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                }
                .padding(16)
                .background(ThemeColors.getInputBackgroundColor(isDarkTheme: isDarkTheme))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme), lineWidth: 1)
                )
            }
        }
    }

    private var endDateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("end_date".localized)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            Button(action: { showEndDatePicker = true }) {
                HStack {
                    Text(endDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 14))
                        .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                    Spacer()
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                }
                .padding(16)
                .background(ThemeColors.getInputBackgroundColor(isDarkTheme: isDarkTheme))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme), lineWidth: 1)
                )
            }
        }
    }

    private var buttonsSection: some View {
        HStack(spacing: 12) {
            Button("cancel".localized) {
                onDismiss()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme), lineWidth: 1)
            )

            Button(editingExpense != nil ? "update_expense".localized : "add_expense".localized) {
                addOrUpdateExpense()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(isFormValid ? AppColors.primaryOrange : ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
            .foregroundColor(.white)
            .cornerRadius(16)
            .disabled(!isFormValid)
        }
    }

    private var endDatePickerSheet: some View {
        NavigationView {
            DatePicker("end_date".localized, selection: $endDate, displayedComponents: .date)
                .datePickerStyle(GraphicalDatePickerStyle())
                .navigationTitle("select_end_date".localized)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    leading: Button("cancel".localized) { showEndDatePicker = false },
                    trailing: Button("done".localized) { showEndDatePicker = false }
                )
        }
    }
}

// MARK: - Helper Methods
extension AddExpenseView {
    private func initializeDefaultValues() {
        if selectedSubCategoryId.isEmpty && !viewModel.subCategories.isEmpty {
            selectedSubCategoryId = viewModel.subCategories.first?.id ?? ""
        }
    }

    private func addOrUpdateExpense() {
        guard let amountValue = Double(amount) else { return }

        let finalExchangeRate: Double?
        if selectedCurrency != defaultCurrency {
            finalExchangeRate = Double(exchangeRate)
        } else {
            finalExchangeRate = nil
        }

        let expense: Expense
        if let editing = editingExpense {
            expense = Expense(
                id: editing.id,
                amount: amountValue,
                currency: selectedCurrency,
                categoryId: selectedCategoryId,
                subCategoryId: selectedSubCategoryId,
                description:  description,
                date: selectedDate,
                dailyLimitAtCreation: Double(dailyLimit) ?? 0.0,
                monthlyLimitAtCreation: Double(monthlyLimit) ?? 0.0,
                exchangeRate: finalExchangeRate,
                recurrenceType: selectedRecurrenceType,
                endDate: selectedRecurrenceType != .NONE ? endDate : nil,
                recurrenceGroupId: selectedRecurrenceType != .NONE ? (editing.recurrenceGroupId ?? UUID().uuidString) : nil
            )
        } else {
            expense = Expense(
                id: UUID().uuidString,
                amount: amountValue,
                currency: selectedCurrency,
                categoryId: selectedCategoryId,
                subCategoryId: selectedSubCategoryId,
                description:   description,
                date: selectedDate,
                dailyLimitAtCreation: Double(dailyLimit) ?? 0.0,
                monthlyLimitAtCreation: Double(monthlyLimit) ?? 0.0,
                exchangeRate: finalExchangeRate,
                recurrenceType: selectedRecurrenceType,
                endDate: selectedRecurrenceType != .NONE ? endDate : nil,
                recurrenceGroupId: selectedRecurrenceType != .NONE ? UUID().uuidString : nil
            )
        }

        onExpenseAdded(expense)
        onDismiss()
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Preview
struct AddExpenseView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ExpenseViewModel()

        AddExpenseView(
            selectedDate: Date(),
            defaultCurrency: "₺",
            dailyLimit: "100",
            monthlyLimit: "1000",
            isDarkTheme: true,
            onExpenseAdded: { _ in },
            onDismiss: { }
        )
        .environmentObject(viewModel)
    }
}
