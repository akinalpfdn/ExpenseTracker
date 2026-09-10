//
//  AddExpenseView.swift
//  ExpenseTracker
//
//  Created by migration from Android AddExpenseScreen.kt
//

import SwiftUI

struct AddExpenseView: View {
    @EnvironmentObject var viewModel: ExpenseViewModel
    @EnvironmentObject var tutorialManager: TutorialManager

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
    @State private var selectedRecurrenceType: RecurrenceType
    @State private var endDate: Date
    @State private var showEndDatePicker = false

    /// How many times the expense repeats, including the first. Kept in sync with
    /// `endDate` in both directions so the two can never contradict each other.
    @State private var occurrenceCountText = ""
    @State private var isLoading = false

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

    private var isFormValid: Bool {
        let amountValue = CurrencyInputFormatter.parseDouble(amount)
        guard amountValue > 0 else { return false }
        guard !selectedSubCategoryId.isEmpty else { return false }

        if selectedCurrency != defaultCurrency {
            let exchangeRateValue = CurrencyInputFormatter.parseDouble(exchangeRate)
            guard exchangeRateValue > 0 else { return false }
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
        // A sheet is presented above the whole app, so the tour's overlay back in
        // MainContentView is hidden behind it — exactly while the step about this form
        // is the one showing. The form carries its own copy for that step.
        .overlay {
            if tutorialManager.currentStepId == .fillForm {
                TutorialOverlay(manager: tutorialManager, isDarkTheme: isDarkTheme)
            }
        }
        // The count and the end date are two views of one thing. Each updates the
        // other only when they actually disagree, so the pair settles instead of
        // bouncing between these two handlers.
        .onChange(of: occurrenceCountText) { _ in
            syncEndDateFromCount()
        }
        .onChange(of: endDate) { _ in
            syncCountFromEndDate()
        }
        .onChange(of: selectedRecurrenceType) { _ in
            // Six monthly instalments and six weekly ones end on different days.
            syncEndDateFromCount()
        }
    }
}

// MARK: - Category Ordering

extension AddExpenseView {

    /// Built once per expense-set change on the view model, not per redraw.
    private var usageRanking: CategoryUsageRanking {
        viewModel.categoryUsage
    }

    /// Most-used first so the categories someone actually lives in are at the top,
    /// alphabetical among equals.
    private var orderedCategories: [Category] {
        usageRanking.sorted(viewModel.categories)
    }

    private func orderedSubCategories(in category: Category) -> [SubCategory] {
        usageRanking.sorted(viewModel.subCategories.filter { $0.categoryId == category.id })
    }
}

// MARK: - Occurrence Count

extension AddExpenseView {

    private var schedule: RecurrenceSchedule { RecurrenceSchedule() }

    private func syncEndDateFromCount() {
        guard selectedRecurrenceType != .NONE,
              let count = Int(occurrenceCountText), count >= 1,
              let newEndDate = schedule.endDate(
                startDate: selectedDate,
                recurrence: selectedRecurrenceType,
                occurrences: count
              ),
              newEndDate != endDate else {
            return
        }

        endDate = newEndDate
    }

    private func syncCountFromEndDate() {
        guard selectedRecurrenceType != .NONE,
              let count = schedule.occurrenceCount(
                startDate: selectedDate,
                endDate: endDate,
                recurrence: selectedRecurrenceType
              ),
              String(count) != occurrenceCountText else {
            return
        }

        occurrenceCountText = String(count)
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
                        amount = CurrencyInputFormatter.formatInput(newValue)
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

            Menu {
                ForEach(orderedCategories, id: \.id) { category in
                    Menu(category.name) {
                        ForEach(orderedSubCategories(in: category), id: \.id) { subCategory in
                            Button(subCategory.name) {
                                selectedSubCategoryId = subCategory.id
                            }
                        }
                    }
                }
            } label: {
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
            
            exchangeLabel
            TextField(exchangeRateExample, text: $exchangeRate)
                .textFieldStyle(CustomTextFieldStyle(isDarkTheme: isDarkTheme))
                .keyboardType(.decimalPad)
                .onChange(of: exchangeRate) { newValue in
                    // Filter input to only allow numbers, comma and period
                    let filtered = newValue.filter { "0123456789.,".contains($0) }

                    // Limit to 12 characters
                    let limited = String(filtered.prefix(12))

                    // Limit to one decimal separator
                    let components = limited.components(separatedBy: CharacterSet(charactersIn: ".,"))
                    if components.count > 2 {
                        exchangeRate = components[0] + "," + (components[1].isEmpty ? "" : components[1])
                    } else {
                        exchangeRate = limited
                    }
                }

            Text("exchange_rate_note".localized)
                .font(.system(size: 12))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// "Exchange Rate (1 USD = ? TRY)" — the currency pair spelled out, so it is
    /// unambiguous which direction the rate goes.
    private var exchangeLabel: some View {
        let labelText = String(
            format: "exchange_rate_label".localized,
            selectedCurrency,
            defaultCurrency
        )

        return Text(labelText)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
    }

    /// "e.g: 0.035 (1 USD = 0.035 TRY)" — shown in the empty field, since the rate
    /// direction is the part users get wrong.
    private var exchangeRateExample: String {
        return String(
            format: "exchange_rate_example".localized,
            selectedCurrency,
            defaultCurrency
        )
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
        HStack(alignment: .bottom, spacing: 12) {
            endDateField
            occurrenceCountField
        }
    }

    private var endDateField: some View {
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

    /// Lets the user say "six instalments" instead of working out which date that
    /// lands on. Narrow on purpose — the date beside it is the primary control, this
    /// is the shortcut.
    private var occurrenceCountField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("occurrence_count".localized)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            TextField("0", text: $occurrenceCountText)
                .textFieldStyle(CustomTextFieldStyle(isDarkTheme: isDarkTheme))
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 88)
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
            .disabled(!isFormValid || isLoading)
            .overlay(
                isLoading ? ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8) : nil
            )
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
            // Preselect the most-used subcategory rather than whichever happened to
            // load first, for the same reason the menu is ordered by use.
            selectedSubCategoryId = usageRanking.sorted(viewModel.subCategories).first?.id ?? ""
        }

        // Show the count the existing end date implies, so an expense being edited
        // opens with both fields already agreeing.
        syncCountFromEndDate()
    }

    private func addOrUpdateExpense() {
        let amountValue = CurrencyInputFormatter.parseDouble(amount)
        guard amountValue > 0 else { return }

        isLoading = true

        let finalExchangeRate: Double?
        if selectedCurrency != defaultCurrency {
            finalExchangeRate = Double(exchangeRate)
        } else {
            finalExchangeRate = 0
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
                description:   description.count > 1 ? description : "-",
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

        // Loading will be handled by the parent view when expense is added
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
            onDismiss()
        }
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
        .environmentObject(TutorialManager(preferencesManager: PreferencesManager()))
        .environmentObject(viewModel)
    }
}
