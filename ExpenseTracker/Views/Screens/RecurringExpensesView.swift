//
//  RecurringExpensesView.swift
//  ExpenseTracker
//
//  Created by migration from Android RecurringExpensesScreen.kt
//

import SwiftUI

// MARK: - RecurrenceType Extension
extension RecurrenceType {
    var localizedName: String {
        switch self {
        case .NONE:
            return "one_time".localized
        case .DAILY:
            return "daily".localized
        case .WEEKDAYS:
            return "weekdays".localized
        case .WEEKLY:
            return "weekly".localized
        case .MONTHLY:
            return "monthly".localized
        }
    }
}

enum SortType: String, CaseIterable {
    case amountHighToLow = "amount_high_to_low"
    case amountLowToHigh = "amount_low_to_high"
    case descriptionAToZ = "description_a_to_z"
    case descriptionZToA = "description_z_to_a"
    case categoryAToZ = "category_a_to_z"
    case categoryZToA = "category_z_to_a"

    var localizedTitle: String {
        rawValue.localized
    }
}

struct RecurringExpensesView: View {
    @EnvironmentObject var viewModel: ExpenseViewModel
    let onDismiss: () -> Void

    @State private var searchText = ""
    @State private var showSortMenu = false
    @State private var currentSortType: SortType = .amountHighToLow

    private var isDarkTheme: Bool {
        viewModel.theme == "dark"
    }

    // Get only recurring expenses that still have future occurrences
    private var baseRecurringExpenses: [Expense] {
        let today = Date()
        let calendar = Calendar.current

        return Dictionary(grouping: viewModel.expenses.filter { $0.recurrenceType != .NONE }, by: { $0.recurrenceGroupId })
            .compactMap { (_, groupExpenses) -> Expense? in
                let baseExpense = groupExpenses.first!

                // Check if this recurring expense still has future occurrences
                let hasFutureOccurrences = groupExpenses.contains { expense in
                    calendar.compare(expense.date, to: calendar.startOfDay(for: today), toGranularity: .day) != .orderedAscending
                }

                return hasFutureOccurrences ? baseExpense : nil
            }
    }

    // Filter and sort expenses
    private var recurringExpenses: [Expense] {
        var filteredExpenses = baseRecurringExpenses

        // Apply search filter
        if !searchText.isEmpty {
            filteredExpenses = filteredExpenses.filter { expense in
                let category = viewModel.categories.first { $0.id == expense.categoryId }
                let subCategory = viewModel.subCategories.first { $0.id == expense.subCategoryId }

                return expense.description.localizedCaseInsensitiveContains(searchText) == true ||
                       String(expense.amount).contains(searchText) ||
                       category?.name.localizedCaseInsensitiveContains(searchText) == true ||
                       subCategory?.name.localizedCaseInsensitiveContains(searchText) == true
            }
        }

        // Apply sorting
        switch currentSortType {
        case .amountHighToLow:
            return filteredExpenses.sorted { $0.getAmountInDefaultCurrency(defaultCurrency: viewModel.defaultCurrency) > $1.getAmountInDefaultCurrency(defaultCurrency: viewModel.defaultCurrency) }
        case .amountLowToHigh:
            return filteredExpenses.sorted { $0.getAmountInDefaultCurrency(defaultCurrency: viewModel.defaultCurrency) < $1.getAmountInDefaultCurrency(defaultCurrency: viewModel.defaultCurrency) }
        case .descriptionAToZ:
            return filteredExpenses.sorted { ($0.description).lowercased() < ($1.description).lowercased() }
        case .descriptionZToA:
            return filteredExpenses.sorted { ($0.description).lowercased() > ($1.description).lowercased() }
        case .categoryAToZ:
            return filteredExpenses.sorted { expense1, expense2 in
                let subCategory1 = viewModel.subCategories.first { $0.id == expense1.subCategoryId }
                let subCategory2 = viewModel.subCategories.first { $0.id == expense2.subCategoryId }
                return (subCategory1?.name ?? "zzz").lowercased() < (subCategory2?.name ?? "zzz").lowercased()
            }
        case .categoryZToA:
            return filteredExpenses.sorted { expense1, expense2 in
                let subCategory1 = viewModel.subCategories.first { $0.id == expense1.subCategoryId }
                let subCategory2 = viewModel.subCategories.first { $0.id == expense2.subCategoryId }
                return (subCategory1?.name ?? "").lowercased() > (subCategory2?.name ?? "").lowercased()
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            searchSection
            contentSection
        }
        .background(ThemeColors.getBackgroundColor(isDarkTheme: isDarkTheme))
    }
}

// MARK: - View Components
extension RecurringExpensesView {
    private var headerSection: some View {
        HStack {
            Button(action: onDismiss) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
            }

            Spacer().frame(width: 8)

            Text("recurring_expenses".localized)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            Spacer()

            // Sort button
            Menu {
                ForEach(SortType.allCases, id: \.rawValue) { sortType in
                    Button(sortType.localizedTitle) {
                        currentSortType = sortType
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 20))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
            }
        }
        .padding(16)
    }

    private var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))

            TextField("search_placeholder".localized, text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 14))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(ThemeColors.getInputBackgroundColor(isDarkTheme: isDarkTheme))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme).opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var contentSection: some View {
        if recurringExpenses.isEmpty {
            emptyStateView
        } else {
            expensesList
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            VStack(spacing: 8) {
                Text(searchText.isEmpty ? "no_recurring_expenses".localized : "no_search_results".localized)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                    .multilineTextAlignment(.center)

                Text(searchText.isEmpty ? "recurring_expenses_hint".localized : "search_no_results_description".localized.replacingOccurrences(of: "%@", with: searchText))
                    .font(.system(size: 14))
                    .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    private var expensesList: some View {
        VStack(spacing: 0) {
            // Results count (only show when searching)
            if !searchText.isEmpty {
                HStack {
                    Text("results_found".localized.replacingOccurrences(of: "%d", with: "\(recurringExpenses.count)"))
                        .font(.system(size: 12))
                        .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(recurringExpenses, id: \.id) { expense in
                        RecurringExpenseCard(
                            expense: expense,
                            isDarkTheme: isDarkTheme,
                            onDelete: {
                                viewModel.deleteRecurringExpenseFromDate(expense, fromDate: Date())
                            }
                        )
                        .environmentObject(viewModel)
                    }
                }
                .padding(16)
            }
        }
    }
}

// MARK: - Helper Methods
extension RecurringExpensesView {
    private func deleteRecurringExpense(_ expense: Expense) {
        let today = Date()
        let calendar = Calendar.current

        // Delete all expenses with the same recurrence group ID that are from today onwards
        let expensesToDelete = viewModel.expenses.filter {
            $0.recurrenceGroupId == expense.recurrenceGroupId &&
            calendar.compare($0.date, to: calendar.startOfDay(for: today), toGranularity: .day) != .orderedAscending
        }

        expensesToDelete.forEach { viewModel.deleteExpense($0) }
    }
}

// MARK: - Recurring Expense Card
struct RecurringExpenseCard: View {
    @EnvironmentObject var viewModel: ExpenseViewModel
    let expense: Expense
    let isDarkTheme: Bool
    let onDelete: () -> Void

    @State private var isEditing = false
    @State private var editAmount = ""
    @State private var editDescription = ""
    @State private var editExchangeRate = ""
    @State private var showDeleteConfirmation = false
    @State private var showEndDatePicker = false
    @State private var tempEndDate = Date()
    @State private var dragOffset: CGFloat = 0
    @State private var isDeleting = false

    private var category: Category? {
        viewModel.categories.first { $0.id == expense.categoryId }
    }

    private var subCategory: SubCategory? {
        viewModel.subCategories.first { $0.id == expense.subCategoryId }
    }

    var body: some View {
        ZStack {
            // Background delete indicator
            HStack {
                Spacer()
                VStack {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                    Text("delete".localized)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.trailing, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.red)
            .cornerRadius(12)
            .opacity(abs(dragOffset) > 50 ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: dragOffset)

            // Main card content
            VStack(spacing: 0) {
                if isEditing {
                    editingView
                } else {
                    displayView
                }
            }
            .background(ThemeColors.getCardBackgroundColor(isDarkTheme: isDarkTheme))
            .cornerRadius(12)
            .offset(x: dragOffset)
            .scaleEffect(isDeleting ? 0.9 : 1.0)
            .opacity(isDeleting ? 0.6 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: dragOffset)
            .animation(.easeInOut(duration: 0.2), value: isDeleting)
        }
        .onAppear {
            initializeEditState()
        }
        .alert("delete_confirmation".localized, isPresented: $showDeleteConfirmation) {
            Button("delete".localized, role: .destructive) {
                onDelete()
            }
            Button("cancel".localized, role: .cancel) { }
        } message: {
            Text("delete_recurring_expense_confirmation".localized)
        }
        .sheet(isPresented: $showEndDatePicker) {
            endDatePickerSheet
        }
    }

    private var displayView: some View {
        ZStack {
           

            // Main card content
            HStack(spacing: 12) {
                // Category icon and color
                if let category = category {
                    ZStack {
                        Circle()
                            .fill(category.getColor().opacity(0.2))
                            .frame(width: 32, height: 32)

                        Image(systemName: category.getIcon())
                            .font(.system(size: 16))
                            .foregroundColor(category.getColor())
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    // Category and description
                    VStack(alignment: .leading, spacing: 2) {
                        if let subCategory = subCategory {
                            Text(subCategory.name)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                                .lineLimit(1)
                        }

                        if !expense.description.isEmpty {
                            Text(expense.description)
                                .font(.system(size: 13))
                                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                                .lineLimit(1)
                        }
                    }

                    // Recurrence info row
                    HStack {
                        Text(expense.recurrenceType.localizedName)
                            .font(.system(size: 12))
                            .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))

                        Spacer()

                    }
                }.swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Sil", systemImage: "trash")
                    }
                    .tint(.red)
                }

                Spacer()

                // Amount section
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(expense.currency) \(NumberFormatter.formatAmount(expense.amount))")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

                    if let exchangeRate = expense.exchangeRate {
                        if exchangeRate>0{
                            Text(expense.currency + ": \(String(format: "%.2f", exchangeRate)) " + viewModel.defaultCurrency)
                                .font(.system(size: 11))
                                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                            
                            Text("\(viewModel.defaultCurrency) \(NumberFormatter.formatAmount(expense.getAmountInDefaultCurrency(defaultCurrency: viewModel.defaultCurrency)))")
                                .font(.system(size: 12))
                                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                        }}
                    
                    if let endDate = expense.endDate {
                        Text("end_date_recurring".localized.replacingOccurrences(of: "%@", with: endDate.formatted(date: .abbreviated, time: .omitted)))
                            .font(.system(size: 12))
                            .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                    }
                }
            }
            .padding(12)
            .background(ThemeColors.getCardBackgroundColor(isDarkTheme: isDarkTheme))
            .cornerRadius(12)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    if isEditing {
                        isEditing = false
                        initializeEditState()
                    } else {
                        isEditing = true
                    }
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Only allow left swipe (negative translation)
                        if value.translation.width < 0 {
                            withAnimation(.interactiveSpring()) {
                                dragOffset = max(value.translation.width, -120) // Limit max swipe distance
                            }
                        }
                    }
                    .onEnded { value in
                        // If swiped left more than 80 points, show delete confirmation
                        if value.translation.width < -80 {
                            withAnimation(.spring()) {
                                isDeleting = true
                            }

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                showDeleteConfirmation = true
                                withAnimation(.spring()) {
                                    dragOffset = 0
                                    isDeleting = false
                                }
                            }
                        } else {
                            // Snap back to original position
                            withAnimation(.spring()) {
                                dragOffset = 0
                            }
                        }
                    }
            )
        }
    }

    private var editingView: some View {
        VStack(spacing: 16) {
            // Amount field
            VStack(alignment: .leading, spacing: 4) {
                Text("amount".localized)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

                TextField("0", text: $editAmount)
                    .textFieldStyle(CustomTextFieldStyle(isDarkTheme: isDarkTheme))
                    .keyboardType(.decimalPad)
            }

            // Description field
            VStack(alignment: .leading, spacing: 4) {
                Text("description".localized)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

                TextField("optional".localized, text: $editDescription)
                    .textFieldStyle(CustomTextFieldStyle(isDarkTheme: isDarkTheme))
            }

            // Exchange rate field (if needed)
            if expense.currency != viewModel.defaultCurrency {
                VStack(alignment: .leading, spacing: 4) {
                    Text("exchange_rate".localized)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

                    TextField("1.0", text: $editExchangeRate)
                        .textFieldStyle(CustomTextFieldStyle(isDarkTheme: isDarkTheme))
                        .keyboardType(.decimalPad)
                }
            }

            // End date field
            VStack(alignment: .leading, spacing: 4) {
                Text("end_date".localized)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

                Button(action: { showEndDatePicker = true }) {
                    HStack {
                        Text(tempEndDate.formatted(date: .abbreviated, time: .omitted))
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

            // Action buttons
            HStack(spacing: 12) {
                Button("cancel".localized) {
                    isEditing = false
                    initializeEditState()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme), lineWidth: 1)
                )

                Button("save".localized) {
                    saveChanges()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(AppColors.primaryOrange)
                .foregroundColor(.white)
                .cornerRadius(16)
                .disabled(!isFormValid)
            }
        }
        .padding(16)
    }

    private var endDatePickerSheet: some View {
        NavigationView {
            DatePicker("end_date".localized, selection: $tempEndDate, displayedComponents: .date)
                .datePickerStyle(GraphicalDatePickerStyle())
                .navigationTitle("select_end_date".localized)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    leading: Button("cancel".localized) { showEndDatePicker = false },
                    trailing: Button("done".localized) { showEndDatePicker = false }
                )
        }
    }

    private var isFormValid: Bool {
        guard let amountValue = Double(editAmount), amountValue > 0 else { return false }

        if expense.currency != viewModel.defaultCurrency {
            guard let exchangeRateValue = Double(editExchangeRate), exchangeRateValue > 0 else { return false }
        }

        return true
    }

    private func initializeEditState() {
        editAmount = String(expense.amount)
        editDescription = expense.description
        editExchangeRate = expense.exchangeRate?.description ?? ""
        tempEndDate = expense.endDate ?? Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    }

    private func saveChanges() {
        guard let amountValue = Double(editAmount) else { return }

        let finalExchangeRate: Double?
        if expense.currency != viewModel.defaultCurrency {
            finalExchangeRate = Double(editExchangeRate)
        } else {
            finalExchangeRate = nil
        }

        let updatedExpense = Expense(
            id: expense.id,
            amount: amountValue,
            currency: expense.currency,
            categoryId: expense.categoryId,
            subCategoryId: expense.subCategoryId,
            description:   editDescription,
            date: expense.date,
            dailyLimitAtCreation: expense.dailyLimitAtCreation,
            monthlyLimitAtCreation: expense.monthlyLimitAtCreation,
            exchangeRate: finalExchangeRate,
            recurrenceType: expense.recurrenceType,
            endDate: tempEndDate,
            recurrenceGroupId: expense.recurrenceGroupId
        )

        viewModel.updateExpense(updatedExpense)
        isEditing = false
    }
}

// MARK: - Preview
struct RecurringExpensesView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ExpenseViewModel()

        RecurringExpensesView(onDismiss: { })
            .environmentObject(viewModel)
    }
}
