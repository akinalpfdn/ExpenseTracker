//
//  ExpensesView.swift
//  ExpenseTracker
//
//  Main expenses list and management screen with search, filtering, and analytics
//

import SwiftUI

struct ExpensesView: View {
    // MARK: - Environment Objects

    @EnvironmentObject var expenseViewModel: ExpenseViewModel
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var appTheme: AppTheme

    // MARK: - State

    @State private var showingFilters = false
    @State private var showingAddExpense = false
    @State private var showingSettings = false
    @State private var showingRecurringExpenses = false
    @State private var showingDatePicker = false
    @State private var selectedExpenseForDetails: Expense?

    // View state
    @State private var searchText = ""
    @State private var isSearchActive = false
    @State private var isGridView = false

    // Animation state
    @State private var isLoaded = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.themedBackground(appTheme.colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // MARK: - Header Section
                    headerSection

                    // MARK: - Search Bar
                    if isSearchActive {
                        searchBarSection
                    }

                    // MARK: - Filter Pills
                    if expenseViewModel.hasActiveFilters {
                        activeFiltersSection
                    }

                    // MARK: - Daily History Chart
                    dailyHistorySection

                    // MARK: - Quick Stats
                    quickStatsSection

                    // MARK: - Content Section
                    contentSection
                }

                // MARK: - Floating Action Buttons
                floatingActionButtons
            }
            .navigationBarHidden(true)
            .themedBackground()
            .onAppear {
                loadInitialData()
            }
            .refreshable {
                await refreshData()
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingRecurringExpenses) {
                RecurringExpensesView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingFilters) {
                FiltersView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .alert(L("error"), isPresented: $expenseViewModel.showingErrorAlert) {
                Button(L("ok")) {
                    expenseViewModel.showingErrorAlert = false
                }
            } message: {
                Text(expenseViewModel.errorMessage ?? L("unknown_error"))
            }
            .alert(L("success"), isPresented: $expenseViewModel.showingSuccessAlert) {
                Button(L("ok")) {
                    expenseViewModel.showingSuccessAlert = false
                }
            } message: {
                Text(expenseViewModel.successMessage ?? "")
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Top header with greeting and profile
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greetingText)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .themedTextColor()

                    Text(L("track_your_expenses"))
                        .font(.subheadline)
                        .themedSecondaryTextColor()
                }

                Spacer()

                // Profile/Settings button
                Button(action: { showingSettings = true }) {
                    Image(systemName: "person.circle")
                        .font(.title2)
                        .themedTextColor()
                }
            }

            // Search and actions bar
            HStack(spacing: 12) {
                // Search button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isSearchActive.toggle()
                    }
                }) {
                    Image(systemName: isSearchActive ? "xmark" : "magnifyingglass")
                        .font(.title3)
                        .themedTextColor()
                        .frame(width: 44, height: 44)
                        .themedCardBackground()
                        .cornerRadius(12)
                }

                // View toggle
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isGridView.toggle()
                    }
                    settingsManager.triggerHapticFeedback(.light)
                }) {
                    Image(systemName: isGridView ? "list.bullet" : "grid")
                        .font(.title3)
                        .themedTextColor()
                        .frame(width: 44, height: 44)
                        .themedCardBackground()
                        .cornerRadius(12)
                }

                // Filter button
                Button(action: { showingFilters = true }) {
                    ZStack {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title3)
                            .foregroundColor(expenseViewModel.hasActiveFilters ? .orange : Color.themedText(appTheme.colorScheme))
                            .frame(width: 44, height: 44)
                            .themedCardBackground()
                            .cornerRadius(12)

                        if expenseViewModel.hasActiveFilters {
                            Circle()
                                .fill(.orange)
                                .frame(width: 8, height: 8)
                                .offset(x: 12, y: -12)
                        }
                    }
                }

                Spacer()

                // Date picker button
                Button(action: { showingDatePicker = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.subheadline)

                        Text(formatSelectedDate())
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .themedTextColor()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .themedCardBackground()
                    .cornerRadius(20)
                }
                .sheet(isPresented: $showingDatePicker) {
                    DatePickerView(selectedDate: $expenseViewModel.selectedDate)
                        .presentationDetents([.medium])
                        .presentationDragIndicator(.visible)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Search Bar Section

    private var searchBarSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)

                TextField(L("search_expenses"), text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .themedTextColor()
                    .onChange(of: searchText) { newValue in
                        expenseViewModel.searchText = newValue
                    }

                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        expenseViewModel.searchText = ""
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
            .padding(.horizontal, 20)
            .padding(.top, 8)

            Divider()
                .padding(.top, 16)
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Active Filters Section

    private var activeFiltersSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if !expenseViewModel.selectedCategoryIds.isEmpty {
                    FilterPill(
                        title: L("categories_count", expenseViewModel.selectedCategoryIds.count),
                        onRemove: { expenseViewModel.selectedCategoryIds.removeAll() }
                    )
                }

                if let status = expenseViewModel.selectedStatus {
                    FilterPill(
                        title: status.displayName,
                        onRemove: { expenseViewModel.selectedStatus = nil }
                    )
                }

                if expenseViewModel.isDateRangeFilterActive {
                    FilterPill(
                        title: L("date_range"),
                        onRemove: { expenseViewModel.isDateRangeFilterActive = false }
                    )
                }

                if expenseViewModel.isAmountFilterActive {
                    FilterPill(
                        title: L("amount_range"),
                        onRemove: { expenseViewModel.isAmountFilterActive = false }
                    )
                }

                Button(L("clear_all")) {
                    expenseViewModel.clearFilters()
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
        .padding(.vertical, 8)
    }

    // MARK: - Daily History Section

    private var dailyHistorySection: some View {
        Group {
            if !expenseViewModel.todayExpenses.isEmpty || !expenseViewModel.thisMonthExpenses.isEmpty {
                VStack(spacing: 12) {
                    HStack {
                        Text(L("spending_overview"))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .themedTextColor()

                        Spacer()

                        Button(L("view_analytics")) {
                            // Switch to analytics tab or show detailed view
                        }
                        .font(.caption)
                        .foregroundColor(.orange)
                    }

                    DailyHistoryView(
                        dailyData: generateDailyHistoryData(),
                        selectedDate: expenseViewModel.selectedDate,
                        onDateSelected: { date in
                            expenseViewModel.selectedDate = date
                        }
                    )
                    .frame(height: 120)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
    }

    // MARK: - Quick Stats Section

    private var quickStatsSection: some View {
        HStack(spacing: 16) {
            // Today's spending
            StatCard(
                title: L("today"),
                amount: expenseViewModel.formattedTodaySpending,
                subtitle: L("expenses_count", expenseViewModel.todayExpenses.count),
                color: .green,
                icon: "calendar.badge.clock"
            )

            // Monthly spending
            StatCard(
                title: L("this_month"),
                amount: expenseViewModel.formattedMonthSpending,
                subtitle: L("expenses_count", expenseViewModel.thisMonthExpenses.count),
                color: .blue,
                icon: "calendar"
            )

            // Filtered total
            if expenseViewModel.hasActiveFilters {
                StatCard(
                    title: L("filtered"),
                    amount: expenseViewModel.formattedTotalAmount,
                    subtitle: L("expenses_count", expenseViewModel.filteredExpenseCount),
                    color: .orange,
                    icon: "line.3.horizontal.decrease.circle"
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Content Section

    private var contentSection: some View {
        Group {
            if expenseViewModel.isLoading {
                loadingView
            } else if expenseViewModel.filteredExpenses.isEmpty {
                emptyStateView
            } else {
                expenseListView
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

            Text(L("loading_expenses"))
                .font(.subheadline)
                .themedSecondaryTextColor()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .themedBackground()
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: expenseViewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle" : "creditcard")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.6))

            VStack(spacing: 8) {
                Text(expenseViewModel.hasActiveFilters ? L("no_expenses_match_filters") : L("no_expenses_yet"))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .themedTextColor()

                Text(expenseViewModel.hasActiveFilters ? L("try_adjusting_filters") : L("add_first_expense_message"))
                    .font(.subheadline)
                    .themedSecondaryTextColor()
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                if expenseViewModel.hasActiveFilters {
                    Button(L("clear_filters")) {
                        expenseViewModel.clearFilters()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }

                Button(L("add_expense")) {
                    showingAddExpense = true
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .themedBackground()
    }

    // MARK: - Expense List View

    private var expenseListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if isGridView {
                    expenseGridView
                } else {
                    expenseListRows
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // Account for floating buttons
        }
    }

    private var expenseListRows: some View {
        ForEach(expenseViewModel.filteredExpenses) { expense in
            ExpenseRowView(
                expense: expense,
                onUpdate: { updatedExpense in
                    Task {
                        await expenseViewModel.updateExpense()
                    }
                },
                onEditingChanged: { isEditing in
                    // Handle editing state if needed
                },
                onDelete: {
                    Task {
                        await expenseViewModel.deleteExpense(expense)
                    }
                },
                isCurrentlyEditing: false,
                dailyExpenseRatio: calculateDailyExpenseRatio(for: expense)
            )
            .onTapGesture {
                selectedExpenseForDetails = expense
            }
        }
    }

    private var expenseGridView: some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]

        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(expenseViewModel.filteredExpenses) { expense in
                ExpenseCardView(expense: expense)
                    .onTapGesture {
                        selectedExpenseForDetails = expense
                    }
            }
        }
    }

    // MARK: - Floating Action Buttons

    private var floatingActionButtons: some View {
        VStack {
            Spacer()

            HStack {
                // Recurring expenses button
                if !expenseViewModel.recurringTemplates.isEmpty {
                    Button(action: { showingRecurringExpenses = true }) {
                        Image(systemName: "repeat.circle")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(.blue.gradient)
                            .clipShape(Circle())
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.leading, 20)
                }

                Spacer()

                // Add expense button
                Button(action: {
                    showingAddExpense = true
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

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12:
            return L("good_morning")
        case 12..<17:
            return L("good_afternoon")
        case 17..<21:
            return L("good_evening")
        default:
            return L("good_night")
        }
    }

    private func formatSelectedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: expenseViewModel.selectedDate)
    }

    private func loadInitialData() {
        guard !isLoaded else { return }

        Task {
            await expenseViewModel.loadExpenses()
            await expenseViewModel.loadRecurringTemplates()

            await MainActor.run {
                withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                    isLoaded = true
                }
            }
        }
    }

    private func refreshData() async {
        await expenseViewModel.loadExpenses()
        await expenseViewModel.refreshAnalytics()
    }

    private func generateDailyHistoryData() -> [DailyData] {
        // Convert expense data to DailyData format
        let calendar = Calendar.current
        let today = Date()

        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) ?? today
            let dayExpenses = expenseViewModel.expenses.filter { expense in
                calendar.isDate(expense.date, inSameDayAs: date)
            }
            let totalAmount = dayExpenses.reduce(0) { $0 + $1.amount }

            return DailyData(
                date: date,
                totalAmount: totalAmount,
                expenseCount: dayExpenses.count,
                dailyLimit: settingsManager.dailyLimit
            )
        }.reversed()
    }

    private func calculateDailyExpenseRatio(for expense: Expense) -> Double {
        let calendar = Calendar.current
        let sameDayExpenses = expenseViewModel.expenses.filter { other in
            calendar.isDate(expense.date, inSameDayAs: other.date)
        }
        let dailyTotal = sameDayExpenses.reduce(0) { $0 + $1.amount }
        return dailyTotal > 0 ? expense.amount / dailyTotal : 1.0
    }
}

// MARK: - Supporting Views

struct FilterPill: View {
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

struct StatCard: View {
    let title: String
    let amount: String
    let subtitle: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(color)

                Spacer()
            }

            Text(amount)
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

struct DatePickerView: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    L("select_date"),
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .themedTextColor()

                Spacer()
            }
            .padding()
            .themedBackground()
            .navigationTitle(L("select_date"))
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
}

struct ExpenseCardView: View {
    let expense: Expense

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Category icon
                Image(systemName: "circle.fill")
                    .foregroundColor(.orange)
                    .font(.caption)

                Spacer()

                // Amount
                Text(formatCurrency(expense.amount))
                    .font(.headline)
                    .fontWeight(.bold)
                    .themedTextColor()
            }

            Text(expense.description)
                .font(.subheadline)
                .themedTextColor()
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer()

            Text(formatDate(expense.date))
                .font(.caption2)
                .themedSecondaryTextColor()
        }
        .padding(12)
        .frame(height: 100)
        .themedCardBackground()
        .cornerRadius(12)
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

// MARK: - Preview

#if DEBUG
struct ExpensesView_Previews: PreviewProvider {
    static var previews: some View {
        ExpensesView()
            .environmentObject(ExpenseViewModel.preview)
            .environmentObject(SettingsManager.preview)
            .environmentObject(AppTheme.shared)
            .preferredColorScheme(.dark)
    }
}
#endif