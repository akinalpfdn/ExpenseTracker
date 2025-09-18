//
//  RecurringExpensesView.swift
//  ExpenseTracker
//
//  Recurring expenses management screen with comprehensive functionality for managing recurring expense templates
//

import SwiftUI

struct RecurringExpensesView: View {
    // MARK: - Environment Objects

    @EnvironmentObject var expenseViewModel: ExpenseViewModel
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var appTheme: AppTheme

    // MARK: - State

    @Environment(\.dismiss) var dismiss
    @State private var showingAddRecurring = false
    @State private var selectedRecurringExpense: Expense?
    @State private var showingEditRecurring = false
    @State private var showingDeleteConfirmation = false
    @State private var expenseToDelete: Expense?

    // Search and filter state
    @State private var searchText = ""
    @State private var selectedFrequency: RecurrenceType?
    @State private var selectedStatus: RecurringExpenseStatus = .all
    @State private var showingFilters = false

    // View state
    @State private var viewMode: ViewMode = .list
    @State private var sortBy: SortOption = .nextDue
    @State private var sortAscending = true

    // Animation state
    @State private var isLoaded = false

    // Enums for recurring expense management
    enum RecurringExpenseStatus: String, CaseIterable {
        case all = "all"
        case active = "active"
        case paused = "paused"

        var displayName: String {
            switch self {
            case .all:
                return L("all")
            case .active:
                return L("active")
            case .paused:
                return L("paused")
            }
        }
    }

    enum ViewMode: String, CaseIterable {
        case list = "list"
        case grid = "grid"

        var iconName: String {
            switch self {
            case .list:
                return "list.bullet"
            case .grid:
                return "grid"
            }
        }
    }

    enum SortOption: String, CaseIterable {
        case nextDue = "nextDue"
        case amount = "amount"
        case name = "name"
        case frequency = "frequency"

        var displayName: String {
            switch self {
            case .nextDue:
                return L("next_due")
            case .amount:
                return L("amount")
            case .name:
                return L("name")
            case .frequency:
                return L("frequency")
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.themedBackground(appTheme.colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // MARK: - Header Section
                    headerSection

                    // MARK: - Search and Filter Section
                    searchAndFilterSection

                    // MARK: - Quick Stats Section
                    quickStatsSection

                    // MARK: - Content Section
                    contentSection
                }

                // MARK: - Floating Action Button
                floatingActionButton
            }
            .navigationBarHidden(true)
            .themedBackground()
            .onAppear {
                loadInitialData()
            }
            .refreshable {
                await refreshData()
            }
            .sheet(isPresented: $showingAddRecurring) {
                AddRecurringExpenseView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedRecurringExpense) { expense in
                RecurringExpenseDetailView(
                    expense: expense,
                    onEdit: {
                        showingEditRecurring = true
                    },
                    onDelete: {
                        expenseToDelete = expense
                        showingDeleteConfirmation = true
                    },
                    onExecute: {
                        Task {
                            await expenseViewModel.executeRecurringExpense(expense)
                        }
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingEditRecurring) {
                if let expense = selectedRecurringExpense {
                    EditRecurringExpenseView(expense: expense)
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                }
            }
            .sheet(isPresented: $showingFilters) {
                RecurringExpenseFiltersView(
                    selectedFrequency: $selectedFrequency,
                    selectedStatus: $selectedStatus,
                    sortBy: $sortBy,
                    sortAscending: $sortAscending
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .alert(L("delete_recurring_expense"), isPresented: $showingDeleteConfirmation) {
                Button(L("cancel"), role: .cancel) {
                    expenseToDelete = nil
                }
                Button(L("delete"), role: .destructive) {
                    if let expense = expenseToDelete {
                        Task {
                            await expenseViewModel.deleteRecurringExpense(expense)
                        }
                    }
                    expenseToDelete = nil
                }
            } message: {
                Text(L("delete_recurring_confirmation"))
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Top header with title and actions
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .themedTextColor()
                }

                Spacer()

                VStack(spacing: 4) {
                    Text(L("recurring_expenses"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .themedTextColor()

                    Text(L("manage_recurring_expenses"))
                        .font(.subheadline)
                        .themedSecondaryTextColor()
                }

                Spacer()

                HStack(spacing: 12) {
                    // View mode toggle
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewMode = viewMode == .list ? .grid : .list
                        }
                    }) {
                        Image(systemName: viewMode.iconName)
                            .font(.title3)
                            .themedTextColor()
                            .frame(width: 44, height: 44)
                            .themedCardBackground()
                            .cornerRadius(12)
                    }

                    // Filters button
                    Button(action: { showingFilters = true }) {
                        ZStack {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.title3)
                                .foregroundColor(hasActiveFilters ? .orange : Color.themedText(appTheme.colorScheme))
                                .frame(width: 44, height: 44)
                                .themedCardBackground()
                                .cornerRadius(12)

                            if hasActiveFilters {
                                Circle()
                                    .fill(.orange)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 12, y: -12)
                            }
                        }
                    }
                }
            }

            // Status filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(RecurringExpenseStatus.allCases, id: \.rawValue) { status in
                        StatusFilterChip(
                            status: status,
                            isSelected: selectedStatus == status
                        ) {
                            selectedStatus = status
                            applyFilters()
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Search and Filter Section

    private var searchAndFilterSection: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)

                TextField(L("search_recurring_expenses"), text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .themedTextColor()
                    .onChange(of: searchText) { newValue in
                        applyFilters()
                    }

                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        applyFilters()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .themedInputBackground()
            .cornerRadius(12)

            // Active filters display
            if hasActiveFilters {
                activeFiltersDisplay
            }
        }
        .padding(.horizontal, 20)
    }

    private var activeFiltersDisplay: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let frequency = selectedFrequency {
                    FilterChip(
                        title: frequency.displayName,
                        onRemove: { selectedFrequency = nil; applyFilters() }
                    )
                }

                if selectedStatus != .all {
                    FilterChip(
                        title: selectedStatus.displayName,
                        onRemove: { selectedStatus = .all; applyFilters() }
                    )
                }

                Button(L("clear_all")) {
                    clearAllFilters()
                }
                .font(.caption)
                .foregroundColor(.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.orange.opacity(0.1))
                .cornerRadius(16)
            }
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, -20)
    }

    // MARK: - Quick Stats Section

    private var quickStatsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text(L("overview"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .themedTextColor()

                Spacer()

                if expenseViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                        .scaleEffect(0.8)
                }
            }

            HStack(spacing: 12) {
                // Total recurring expenses
                QuickStatCard(
                    title: L("total_recurring"),
                    value: "\(filteredRecurringExpenses.count)",
                    subtitle: L("templates"),
                    icon: "repeat.circle",
                    color: .blue
                )

                // Monthly total
                QuickStatCard(
                    title: L("monthly_total"),
                    value: formatCurrency(monthlyRecurringTotal),
                    subtitle: L("estimated"),
                    icon: "calendar",
                    color: .green
                )

                // Next due
                QuickStatCard(
                    title: L("next_due"),
                    value: nextDueCount > 0 ? "\(nextDueCount)" : L("none"),
                    subtitle: L("this_week"),
                    icon: "clock",
                    color: nextDueCount > 0 ? .orange : .gray
                )
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Content Section

    private var contentSection: some View {
        Group {
            if expenseViewModel.isLoading && filteredRecurringExpenses.isEmpty {
                loadingView
            } else if filteredRecurringExpenses.isEmpty {
                emptyStateView
            } else {
                recurringExpensesListView
            }
        }
        .opacity(isLoaded ? 1 : 0)
        .offset(y: isLoaded ? 0 : 20)
        .animation(.easeOut(duration: 0.6), value: isLoaded)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                .scaleEffect(1.2)

            Text(L("loading_recurring_expenses"))
                .font(.subheadline)
                .themedSecondaryTextColor()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .themedBackground()
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle" : "repeat.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.6))

            VStack(spacing: 8) {
                Text(hasActiveFilters ? L("no_recurring_match_filters") : L("no_recurring_expenses"))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .themedTextColor()

                Text(hasActiveFilters ? L("try_adjusting_filters") : L("create_first_recurring_message"))
                    .font(.subheadline)
                    .themedSecondaryTextColor()
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                if hasActiveFilters {
                    Button(L("clear_filters")) {
                        clearAllFilters()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }

                Button(L("add_recurring_expense")) {
                    showingAddRecurring = true
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .themedBackground()
    }

    // MARK: - Recurring Expenses List View

    private var recurringExpensesListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if viewMode == .grid {
                    recurringExpensesGridView
                } else {
                    recurringExpensesListRows
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // Account for floating button
        }
    }

    private var recurringExpensesGridView: some View {
        let columns = [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]

        return LazyVGrid(columns: columns, spacing: 16) {
            ForEach(filteredRecurringExpenses) { expense in
                RecurringExpenseCard(
                    expense: expense,
                    compactMode: true,
                    onTap: {
                        selectedRecurringExpense = expense
                    },
                    onExecute: {
                        Task {
                            await expenseViewModel.executeRecurringExpense(expense)
                        }
                    }
                )
            }
        }
    }

    private var recurringExpensesListRows: some View {
        ForEach(filteredRecurringExpenses) { expense in
            RecurringExpenseCard(
                expense: expense,
                compactMode: false,
                onTap: {
                    selectedRecurringExpense = expense
                },
                onExecute: {
                    Task {
                        await expenseViewModel.executeRecurringExpense(expense)
                    }
                }
            )
        }
    }

    // MARK: - Floating Action Button

    private var floatingActionButton: some View {
        VStack {
            Spacer()

            HStack {
                Spacer()

                Button(action: {
                    showingAddRecurring = true
                    settingsManager.triggerHapticFeedback(.medium)
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(.orange.gradient)
                        .clipShape(Circle())
                        .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.trailing, 20)
            }
            .padding(.bottom, 34) // Account for safe area
        }
    }

    // MARK: - Helper Methods

    private func loadInitialData() {
        guard !isLoaded else { return }

        Task {
            await expenseViewModel.loadRecurringTemplates()

            await MainActor.run {
                withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                    isLoaded = true
                }
            }
        }
    }

    private func refreshData() async {
        await expenseViewModel.loadRecurringTemplates()
    }

    private func applyFilters() {
        // Filter logic would be applied here
        // This would update the filteredRecurringExpenses array
    }

    private func clearAllFilters() {
        selectedFrequency = nil
        selectedStatus = .all
        searchText = ""
        applyFilters()
    }

    private var hasActiveFilters: Bool {
        return selectedFrequency != nil || selectedStatus != .all || !searchText.isEmpty
    }

    private var filteredRecurringExpenses: [Expense] {
        var expenses = expenseViewModel.recurringTemplates

        // Apply search filter
        if !searchText.isEmpty {
            expenses = expenses.filter { expense in
                expense.description.localizedCaseInsensitiveContains(searchText) ||
                expense.notes.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply frequency filter
        if let frequency = selectedFrequency {
            expenses = expenses.filter { $0.recurrenceType == frequency }
        }

        // Apply status filter
        switch selectedStatus {
        case .all:
            break
        case .active:
            expenses = expenses.filter { $0.isActive }
        case .paused:
            expenses = expenses.filter { !$0.isActive }
        }

        // Apply sorting
        return sortExpenses(expenses)
    }

    private func sortExpenses(_ expenses: [Expense]) -> [Expense] {
        return expenses.sorted { expense1, expense2 in
            let comparison: Bool
            switch sortBy {
            case .nextDue:
                // Sort by next due date
                comparison = expense1.nextDueDate < expense2.nextDueDate
            case .amount:
                comparison = expense1.amount < expense2.amount
            case .name:
                comparison = expense1.description < expense2.description
            case .frequency:
                comparison = expense1.recurrenceType.rawValue < expense2.recurrenceType.rawValue
            }
            return sortAscending ? comparison : !comparison
        }
    }

    private var monthlyRecurringTotal: Double {
        return filteredRecurringExpenses.reduce(0) { total, expense in
            total + expense.monthlyEquivalentAmount
        }
    }

    private var nextDueCount: Int {
        let nextWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date()
        return filteredRecurringExpenses.filter { expense in
            expense.nextDueDate <= nextWeek
        }.count
    }

    private func formatCurrency(_ amount: Double) -> String {
        return settingsManager.formatCurrency(amount)
    }
}

// MARK: - Supporting Views

struct StatusFilterChip: View {
    let status: RecurringExpensesView.RecurringExpenseStatus
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(status.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .orange)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? .orange : .orange.opacity(0.2))
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FilterChip: View {
    let title: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.orange)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.orange.opacity(0.1))
        .cornerRadius(16)
    }
}

struct QuickStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .themedTextColor()

                Text(subtitle)
                    .font(.caption2)
                    .themedSecondaryTextColor()
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .themedCardBackground()
        .cornerRadius(12)
    }
}

struct RecurringExpenseCard: View {
    let expense: Expense
    let compactMode: Bool
    let onTap: () -> Void
    let onExecute: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: compactMode ? 8 : 12) {
                // Header with amount and status
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatCurrency(expense.amount))
                            .font(compactMode ? .subheadline : .headline)
                            .fontWeight(.bold)
                            .themedTextColor()

                        if !compactMode {
                            Text(expense.description)
                                .font(.subheadline)
                                .themedTextColor()
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    // Status indicator
                    Circle()
                        .fill(expense.isActive ? .green : .gray)
                        .frame(width: 8, height: 8)
                }

                if compactMode {
                    Text(expense.description)
                        .font(.caption)
                        .themedTextColor()
                        .lineLimit(2)
                }

                // Frequency and next due
                HStack {
                    Label(expense.recurrenceType.displayName, systemImage: "repeat.circle")
                        .font(.caption)
                        .foregroundColor(.orange)

                    Spacer()

                    Text(L("next") + ": " + formatDate(expense.nextDueDate))
                        .font(.caption2)
                        .themedSecondaryTextColor()
                }

                if !compactMode {
                    // Action buttons
                    HStack(spacing: 8) {
                        Button(L("execute_now")) {
                            onExecute()
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.orange)
                        .cornerRadius(16)

                        Spacer()

                        Text(daysBetweenDates(from: Date(), to: expense.nextDueDate))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(expense.nextDueDate <= Date() ? .red : .orange)
                    }
                }
            }
            .padding(compactMode ? 12 : 16)
            .themedCardBackground()
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TRY"
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }

    private func daysBetweenDates(from startDate: Date, to endDate: Date) -> String {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0

        if days == 0 {
            return L("today")
        } else if days == 1 {
            return L("tomorrow")
        } else if days < 0 {
            return L("overdue")
        } else {
            return L("in_days", days)
        }
    }
}

// MARK: - Additional Views

struct AddRecurringExpenseView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack {
                Text(L("add_recurring_expense"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .themedTextColor()

                Spacer()

                Text(L("feature_coming_soon"))
                    .font(.subheadline)
                    .themedSecondaryTextColor()

                Spacer()
            }
            .padding()
            .themedBackground()
            .navigationBarHidden(true)
        }
    }
}

struct EditRecurringExpenseView: View {
    let expense: Expense
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack {
                Text(L("edit_recurring_expense"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .themedTextColor()

                Spacer()

                Text(L("feature_coming_soon"))
                    .font(.subheadline)
                    .themedSecondaryTextColor()

                Spacer()
            }
            .padding()
            .themedBackground()
            .navigationBarHidden(true)
        }
    }
}

struct RecurringExpenseDetailView: View {
    let expense: Expense
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onExecute: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text(formatCurrency(expense.amount))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)

                        Text(expense.description)
                            .font(.title2)
                            .fontWeight(.medium)
                            .themedTextColor()
                            .multilineTextAlignment(.center)
                    }

                    // Details
                    VStack(spacing: 16) {
                        DetailRow(title: L("frequency"), value: expense.recurrenceType.displayName)
                        DetailRow(title: L("next_due"), value: formatDate(expense.nextDueDate))
                        DetailRow(title: L("status"), value: expense.isActive ? L("active") : L("paused"))

                        if !expense.notes.isEmpty {
                            DetailRow(title: L("notes"), value: expense.notes)
                        }
                    }
                    .padding(20)
                    .themedCardBackground()
                    .cornerRadius(12)

                    // Action buttons
                    VStack(spacing: 12) {
                        Button(L("execute_now")) {
                            onExecute()
                            dismiss()
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        HStack(spacing: 12) {
                            Button(L("edit")) {
                                onEdit()
                            }
                            .buttonStyle(SecondaryButtonStyle())

                            Button(L("delete")) {
                                onDelete()
                                dismiss()
                            }
                            .buttonStyle(DestructiveButtonStyle())
                        }
                    }

                    Spacer(minLength: 50)
                }
                .padding()
            }
            .themedBackground()
            .navigationTitle(L("recurring_expense"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("done")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TRY"
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .themedSecondaryTextColor()

            Spacer()

            Text(value)
                .font(.subheadline)
                .themedTextColor()
                .multilineTextAlignment(.trailing)
        }
    }
}

struct RecurringExpenseFiltersView: View {
    @Binding var selectedFrequency: RecurrenceType?
    @Binding var selectedStatus: RecurringExpensesView.RecurringExpenseStatus
    @Binding var sortBy: RecurringExpensesView.SortOption
    @Binding var sortAscending: Bool
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text(L("filters_and_sorting"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .themedTextColor()

                // Frequency filter
                VStack(alignment: .leading, spacing: 12) {
                    Text(L("frequency"))
                        .font(.headline)
                        .themedTextColor()

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(RecurrenceType.allCases, id: \.rawValue) { frequency in
                            Button(action: {
                                selectedFrequency = selectedFrequency == frequency ? nil : frequency
                            }) {
                                Text(frequency.displayName)
                                    .font(.subheadline)
                                    .foregroundColor(selectedFrequency == frequency ? .white : .orange)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(selectedFrequency == frequency ? .orange : .orange.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }

                // Sort options
                VStack(alignment: .leading, spacing: 12) {
                    Text(L("sort_by"))
                        .font(.headline)
                        .themedTextColor()

                    Picker(L("sort_by"), selection: $sortBy) {
                        ForEach(RecurringExpensesView.SortOption.allCases, id: \.rawValue) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)

                    Toggle(L("ascending_order"), isOn: $sortAscending)
                        .toggleStyle(SwitchToggleStyle(tint: .orange))
                }

                Spacer()

                Button(L("apply_filters")) {
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding()
            .themedBackground()
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(.orange.gradient)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.medium)
            .foregroundColor(.orange)
            .frame(maxWidth: .infinity)
            .padding()
            .background(.orange.opacity(0.1))
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.medium)
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding()
            .background(.red.opacity(0.1))
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

// MARK: - Extensions

extension Expense {
    var nextDueDate: Date {
        // Calculate next due date based on recurrence type
        let calendar = Calendar.current
        switch recurrenceType {
        case .none:
            return date
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date) ?? date
        case .custom:
            return calendar.date(byAdding: .day, value: customRecurrenceInterval, to: date) ?? date
        }
    }

    var monthlyEquivalentAmount: Double {
        switch recurrenceType {
        case .none:
            return 0
        case .daily:
            return amount * 30
        case .weekly:
            return amount * 4.33
        case .monthly:
            return amount
        case .yearly:
            return amount / 12
        case .custom:
            let daysInMonth = 30.0
            return amount * (daysInMonth / Double(customRecurrenceInterval))
        }
    }

    var isActive: Bool {
        // This would be determined by the expense status or a separate field
        return status == .pending || status == .completed
    }
}

// MARK: - Preview

#if DEBUG
struct RecurringExpensesView_Previews: PreviewProvider {
    static var previews: some View {
        RecurringExpensesView()
            .environmentObject(ExpenseViewModel.preview)
            .environmentObject(SettingsManager.preview)
            .environmentObject(AppTheme.shared)
            .preferredColorScheme(.dark)
    }
}
#endif