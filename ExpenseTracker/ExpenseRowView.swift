//
//  ExpenseRowView.swift
//  ExpenseTracker
//
//  Created by Akinalp Fidan on 11.08.2025.
//  Updated by Claude on 17.09.2024.
//

import SwiftUI
import Foundation

/// Enhanced expense row component with modern SwiftUI patterns
/// Integrates with ExpenseViewModel and uses new theme system and data models
struct ExpenseRowView: View {

    // MARK: - Properties

    let expense: Expense
    let onUpdate: (Expense) -> Void
    let onEditingChanged: (Bool) -> Void
    let onDelete: () -> Void
    let isCurrentlyEditing: Bool
    let dailyExpenseRatio: Double
    let category: Category?
    let subCategory: SubCategory?
    let isSelected: Bool
    let showProgressBar: Bool
    let compactMode: Bool

    @Environment(\.colorScheme) private var colorScheme
    @State private var isEditing = false
    @State private var editedAmount: String
    @State private var editedCurrency: String
    @State private var editedSubCategoryId: String
    @State private var editedDescription: String
    @State private var editedNotes: String
    @State private var editedStatus: ExpenseStatus
    @State private var showingDeleteConfirmation = false

    // MARK: - Initialization

    init(
        expense: Expense,
        onUpdate: @escaping (Expense) -> Void,
        onEditingChanged: @escaping (Bool) -> Void,
        onDelete: @escaping () -> Void,
        isCurrentlyEditing: Bool = false,
        dailyExpenseRatio: Double = 0.0,
        category: Category? = nil,
        subCategory: SubCategory? = nil,
        isSelected: Bool = false,
        showProgressBar: Bool = true,
        compactMode: Bool = false
    ) {
        self.expense = expense
        self.onUpdate = onUpdate
        self.onEditingChanged = onEditingChanged
        self.onDelete = onDelete
        self.isCurrentlyEditing = isCurrentlyEditing
        self.dailyExpenseRatio = dailyExpenseRatio
        self.category = category
        self.subCategory = subCategory
        self.isSelected = isSelected
        self.showProgressBar = showProgressBar
        self.compactMode = compactMode

        self._editedAmount = State(initialValue: String(format: "%.2f", expense.amount))
        self._editedCurrency = State(initialValue: expense.currency)
        self._editedSubCategoryId = State(initialValue: expense.subCategoryId)
        self._editedDescription = State(initialValue: expense.description)
        self._editedNotes = State(initialValue: expense.notes)
        self._editedStatus = State(initialValue: expense.status)
    }
    
    // MARK: - Computed Properties

    private var categoryColor: Color {
        category?.color ?? Color.gray
    }

    private var categoryIcon: String {
        category?.iconName ?? "questionmark.circle"
    }

    private var subcategoryName: String {
        subCategory?.name ?? L("unknown_subcategory")
    }

    private var categoryName: String {
        category?.displayName ?? L("unknown_category")
    }

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = expense.currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: expense.amount)) ??
               "\(expense.currency) \(String(format: "%.2f", expense.amount))"
    }

    private var statusColor: Color {
        switch expense.status {
        case .confirmed:
            return ThemeColors.successGreenColor(for: colorScheme)
        case .pending:
            return .orange
        case .cancelled:
            return ThemeColors.deleteRedColor(for: colorScheme)
        case .refunded:
            return .blue
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: compactMode ? 8 : 12) {
            mainContent

            if showProgressBar && dailyExpenseRatio > 0 && !compactMode {
                progressBar
            }

            if !expense.description.isEmpty && !compactMode {
                descriptionText
            }

            if expense.hasTags && !compactMode {
                tagsView
            }

            if isEditing {
                editingForm
            }
        }
        .padding(.vertical, compactMode ? 8 : 12)
        .padding(.horizontal, 16)
        .background(backgroundView)
        .overlay(selectionOverlay)
        .onTapGesture {
            handleTap()
        }
        .onChange(of: isCurrentlyEditing) { newValue in
            if !newValue && isEditing {
                cancelEdit()
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            swipeActions
        }
        .contextMenu {
            contextMenuActions
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(L("expense_row_accessibility_hint"))
    }

    // MARK: - View Components

    @ViewBuilder
    private var mainContent: some View {
        HStack(spacing: compactMode ? 8 : 12) {
            // Category icon with status indicator
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.2))
                    .frame(width: compactMode ? 32 : 40, height: compactMode ? 32 : 40)

                Image(systemName: categoryIcon)
                    .font(.system(size: compactMode ? 14 : 16, weight: .medium))
                    .foregroundColor(categoryColor)

                // Status indicator
                if expense.status != .confirmed {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                        .offset(x: 12, y: -12)
                }
            }

            // Expense details
            VStack(alignment: .leading, spacing: 2) {
                Text(subcategoryName)
                    .font(.system(size: compactMode ? 14 : 16, weight: .semibold, design: .rounded))
                    .foregroundColor(ThemeColors.textColor(for: colorScheme))
                    .lineLimit(1)

                Text(categoryName)
                    .font(.caption)
                    .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                    .lineLimit(1)

                if compactMode && !expense.description.isEmpty {
                    Text(expense.description)
                        .font(.caption2)
                        .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                        .lineLimit(1)
                }
            }

            Spacer()

            // Amount and date
            VStack(alignment: .trailing, spacing: 2) {
                Text(formattedAmount)
                    .font(.system(size: compactMode ? 14 : 16, weight: .bold, design: .rounded))
                    .foregroundColor(ThemeColors.textColor(for: colorScheme))

                Text(expense.date, style: .date)
                    .font(.caption)
                    .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

                if !compactMode && expense.hasReceipt {
                    Image(systemName: "paperclip")
                        .font(.caption2)
                        .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                }
            }
        }
    }

    @ViewBuilder
    private var progressBar: some View {
        HStack {
            // Daily expense ratio progress bar
            GeometryReader { geometry in
                Rectangle()
                    .fill(AppColors.primaryOrange.opacity(0.3))
                    .frame(height: 2)
                    .overlay(
                        Rectangle()
                            .fill(AppColors.primaryOrange)
                            .frame(width: geometry.size.width * min(dailyExpenseRatio, 1.0), height: 2)
                            .animation(.easeInOut(duration: 0.5), value: dailyExpenseRatio),
                        alignment: .leading
                    )
                    .cornerRadius(1)
            }
            .frame(height: 2)

            Spacer()
        }
        .padding(.leading, compactMode ? 40 : 52)
    }

    @ViewBuilder
    private var descriptionText: some View {
        if !expense.description.isEmpty {
            Text(expense.description)
                .font(.subheadline)
                .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                .padding(.leading, compactMode ? 40 : 52)
                .lineLimit(2)
        }
    }

    @ViewBuilder
    private var tagsView: some View {
        if expense.hasTags {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(expense.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(categoryColor.opacity(0.2))
                            .foregroundColor(categoryColor)
                            .clipShape(Capsule())
                    }
                }
                .padding(.leading, compactMode ? 40 : 52)
            }
        }
    }
            
    @ViewBuilder
    private var editingForm: some View {
        VStack(spacing: 12) {
            // Amount and currency
            HStack {
                TextField(L("amount"), text: $editedAmount)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .onChange(of: editedAmount) { newValue in
                        // Filter to allow only numbers and decimal separator
                        let filtered = newValue.filter { "0123456789.,".contains($0) }
                        let components = filtered.components(separatedBy: CharacterSet(charactersIn: ".,"))
                        if components.count > 2 {
                            editedAmount = components[0] + "." + components[1]
                        } else {
                            editedAmount = filtered.replacingOccurrences(of: ",", with: ".")
                        }
                    }

                TextField(L("currency"), text: $editedCurrency)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
            }

            // Description
            TextField(L("description"), text: $editedDescription)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            // Notes
            TextField(L("notes"), text: $editedNotes, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(2...4)

            // Status picker
            Picker(L("status"), selection: $editedStatus) {
                ForEach(ExpenseStatus.allCases) { status in
                    HStack {
                        Image(systemName: status.iconName)
                            .foregroundColor(status.color)
                        Text(status.displayName)
                    }
                    .tag(status)
                }
            }
            .pickerStyle(.menu)

            // Action buttons
            HStack(spacing: 12) {
                Button(action: saveChanges) {
                    Text(L("save"))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppColors.primaryGradient)
                        .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: cancelEdit) {
                    Text(L("cancel"))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(ThemeColors.textColor(for: colorScheme))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(ThemeColors.cardBackgroundColor(for: colorScheme))
                        .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(ThemeColors.cardBackgroundColor(for: colorScheme))
            .shadow(
                color: .black.opacity(0.1),
                radius: isSelected ? 3 : 1,
                x: 0,
                y: isSelected ? 2 : 1
            )
    }

    @ViewBuilder
    private var selectionOverlay: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.primaryOrange, lineWidth: 2)
        }
    }

    @ViewBuilder
    private var swipeActions: some View {
        // Edit action
        Button {
            startEditing()
        } label: {
            Label(L("edit"), systemImage: "pencil")
        }
        .tint(.blue)

        // Delete action
        Button(role: .destructive) {
            showingDeleteConfirmation = true
        } label: {
            Label(L("delete"), systemImage: "trash")
        }
        .tint(ThemeColors.deleteRedColor(for: colorScheme))
    }

    @ViewBuilder
    private var contextMenuActions: some View {
        Button {
            startEditing()
        } label: {
            Label(L("edit_expense"), systemImage: "pencil")
        }

        Button {
            // Duplicate expense
            var duplicatedExpense = expense
            duplicatedExpense = expense.updated(with: [
                "id": UUID().uuidString,
                "description": "\(expense.description) (\(L("copy")))",
                "date": Date(),
                "status": ExpenseStatus.pending
            ])
            onUpdate(duplicatedExpense)
        } label: {
            Label(L("duplicate_expense"), systemImage: "doc.on.doc")
        }

        if expense.status == .pending {
            Button {
                let confirmedExpense = expense.withStatus(.confirmed)
                onUpdate(confirmedExpense)
            } label: {
                Label(L("confirm_expense"), systemImage: "checkmark.circle")
            }
        }

        Divider()

        Button(role: .destructive) {
            showingDeleteConfirmation = true
        } label: {
            Label(L("delete_expense"), systemImage: "trash")
        }
    }

    // MARK: - Methods

    private func handleTap() {
        if !isEditing && !isCurrentlyEditing {
            startEditing()
        }
    }

    private func startEditing() {
        isEditing = true
        onEditingChanged(true)
    }

    private func saveChanges() {
        guard let amount = Double(editedAmount.replacingOccurrences(of: ",", with: ".")) else {
            return
        }

        let updatedExpense = expense.updated(with: [
            "amount": amount,
            "currency": editedCurrency,
            "subCategoryId": editedSubCategoryId,
            "description": editedDescription,
            "notes": editedNotes,
            "status": editedStatus
        ])

        onUpdate(updatedExpense)
        isEditing = false
        onEditingChanged(false)
    }

    private func cancelEdit() {
        // Reset form values
        editedAmount = String(format: "%.2f", expense.amount)
        editedCurrency = expense.currency
        editedSubCategoryId = expense.subCategoryId
        editedDescription = expense.description
        editedNotes = expense.notes
        editedStatus = expense.status

        isEditing = false
        onEditingChanged(false)
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        return L("expense_accessibility_label", formattedAmount, subcategoryName, categoryName)
    }

    private var accessibilityValue: String {
        var value = expense.formattedDate
        if expense.status != .confirmed {
            value += ", \(expense.status.displayName)"
        }
        if !expense.description.isEmpty {
            value += ", \(expense.description)"
        }
        return value
    }
}

// MARK: - Convenience Initializers

extension ExpenseRowView {
    /// Creates a compact expense row for lists
    static func compact(
        expense: Expense,
        onUpdate: @escaping (Expense) -> Void,
        onDelete: @escaping () -> Void,
        category: Category? = nil,
        subCategory: SubCategory? = nil
    ) -> ExpenseRowView {
        return ExpenseRowView(
            expense: expense,
            onUpdate: onUpdate,
            onEditingChanged: { _ in },
            onDelete: onDelete,
            category: category,
            subCategory: subCategory,
            compactMode: true
        )
    }

    /// Creates a selectable expense row for multi-selection
    static func selectable(
        expense: Expense,
        isSelected: Bool,
        onUpdate: @escaping (Expense) -> Void,
        onDelete: @escaping () -> Void,
        category: Category? = nil,
        subCategory: SubCategory? = nil
    ) -> ExpenseRowView {
        return ExpenseRowView(
            expense: expense,
            onUpdate: onUpdate,
            onEditingChanged: { _ in },
            onDelete: onDelete,
            category: category,
            subCategory: subCategory,
            isSelected: isSelected,
            showProgressBar: false
        )
    }
}

// MARK: - Preview Provider

#if DEBUG
struct ExpenseRowView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Normal expense row
                ExpenseRowView(
                    expense: Expense.mockExpense(),
                    onUpdate: { _ in },
                    onEditingChanged: { _ in },
                    onDelete: { },
                    dailyExpenseRatio: 0.7
                )

                // Compact mode
                ExpenseRowView.compact(
                    expense: Expense.mockExpense(),
                    onUpdate: { _ in },
                    onDelete: { }
                )

                // Selected state
                ExpenseRowView.selectable(
                    expense: Expense.mockExpense(),
                    isSelected: true,
                    onUpdate: { _ in },
                    onDelete: { }
                )

                // Pending status
                ExpenseRowView(
                    expense: Expense.mockPendingExpense(),
                    onUpdate: { _ in },
                    onEditingChanged: { _ in },
                    onDelete: { }
                )
            }
            .padding()
        }
        .background(ThemeColors.backgroundColor(for: .dark))
        .preferredColorScheme(.dark)
        .previewDisplayName("Expense Row Variations")
    }
}

// MARK: - Mock Data

extension Expense {
    static func mockExpense() -> Expense {
        return Expense(
            amount: 25.50,
            currency: "TRY",
            categoryId: "food",
            subCategoryId: "restaurant",
            description: "Lunch at downtown cafe",
            notes: "Business lunch with client",
            tags: ["business", "food"],
            location: "Downtown Cafe"
        )
    }

    static func mockPendingExpense() -> Expense {
        return Expense(
            amount: 150.00,
            currency: "TRY",
            categoryId: "shopping",
            subCategoryId: "clothing",
            description: "Online shopping order",
            status: .pending,
            tags: ["online", "clothing"]
        )
    }
}
#endif
