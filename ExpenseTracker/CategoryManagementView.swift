//
//  CategoryManagementView.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import SwiftUI

struct CategoryManagementView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var expenseViewModel: ExpenseViewModel

    @State private var showingAddCategory = false
    @State private var showingAddSubcategory = false
    @State private var editingCategory: Category? = nil
    @State private var editingSubcategory: SubCategory? = nil
    @State private var selectedCategoryForSubcategory: String? = nil
    @State private var searchText = ""
    @State private var showingDeleteConfirmation = false
    @State private var itemToDelete: Any? = nil

    private var filteredCategories: [Category] {
        if searchText.isEmpty {
            return expenseViewModel.availableCategories
        } else {
            return expenseViewModel.availableCategories.filter { category in
                category.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerView

                if filteredCategories.isEmpty {
                    emptyStateView
                } else {
                    categoryListView
                }
            }
            .background(ThemeColors.backgroundColor(for: colorScheme))
            .navigationBarHidden(true)
            .searchable(text: $searchText, prompt: L("search_categories"))
        }
        .sheet(isPresented: $showingAddCategory) {
            CategoryFormSheet(
                expenseViewModel: expenseViewModel,
                editingCategory: editingCategory
            )
        }
        .sheet(isPresented: $showingAddSubcategory) {
            SubcategoryFormSheet(
                expenseViewModel: expenseViewModel,
                categoryId: selectedCategoryForSubcategory ?? "",
                editingSubcategory: editingSubcategory
            )
        }
        .confirmationDialog(
            L("delete_confirmation"),
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(L("delete"), role: .destructive) {
                deleteItem()
            }
        }
        .onAppear {
            // Load categories if needed
        }
    }

    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Button(L("close")) {
                    dismiss()
                }
                .foregroundColor(AppColors.primaryRed)

                Spacer()

                Text(L("manage_categories"))
                    .font(AppTypography.navigationTitle)
                    .foregroundColor(ThemeColors.textColor(for: colorScheme))

                Spacer()

                Button(action: {
                    editingCategory = nil
                    showingAddCategory = true
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(AppColors.primaryOrange)
                }
            }

            HStack {
                Text(L("categories_and_subcategories"))
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

                Spacer()

                Text("\(filteredCategories.count) \(L("categories"))")
                    .font(AppTypography.labelMedium)
                    .foregroundColor(AppColors.primaryOrange)
            }
        }
        .padding()
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

            VStack(spacing: 8) {
                Text(searchText.isEmpty ? L("no_categories") : L("no_categories_found"))
                    .font(AppTypography.titleSmall)
                    .foregroundColor(ThemeColors.textColor(for: colorScheme))

                Text(searchText.isEmpty ? L("add_first_category") : L("try_different_search"))
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                    .multilineTextAlignment(.center)
            }

            if searchText.isEmpty {
                Button(L("add_category")) {
                    editingCategory = nil
                    showingAddCategory = true
                }
                .font(AppTypography.buttonText)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(AppColors.primaryGradient)
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var categoryListView: some View {
        List {
            ForEach(filteredCategories, id: \.id) { category in
                CategoryRow(
                    category: category,
                    subcategories: getSubcategories(for: category.id),
                    colorScheme: colorScheme,
                    onEditCategory: {
                        editingCategory = category
                        showingAddCategory = true
                    },
                    onDeleteCategory: {
                        itemToDelete = category
                        showingDeleteConfirmation = true
                    },
                    onAddSubcategory: {
                        selectedCategoryForSubcategory = category.id
                        editingSubcategory = nil
                        showingAddSubcategory = true
                    },
                    onEditSubcategory: { subcategory in
                        selectedCategoryForSubcategory = category.id
                        editingSubcategory = subcategory
                        showingAddSubcategory = true
                    },
                    onDeleteSubcategory: { subcategory in
                        itemToDelete = subcategory
                        showingDeleteConfirmation = true
                    }
                )
            }
            .onMove(perform: moveCategories)
        }
        .listStyle(PlainListStyle())
    }

    // MARK: - Helper Methods

    private func getSubcategories(for categoryId: String) -> [SubCategory] {
        return expenseViewModel.availableSubCategories.filter { $0.categoryId == categoryId }
    }

    private func moveCategories(from source: IndexSet, to destination: Int) {
        // Handle category reordering
    }

    private func deleteItem() {
        if let category = itemToDelete as? Category {
            deleteCategory(category)
        } else if let subcategory = itemToDelete as? SubCategory {
            deleteSubcategory(subcategory)
        }
        itemToDelete = nil
    }

    private func deleteCategory(_ category: Category) {
        // Implementation would delete category
    }

    private func deleteSubcategory(_ subcategory: SubCategory) {
        // Implementation would delete subcategory
    }
}

// MARK: - CategoryRow

struct CategoryRow: View {
    let category: Category
    let subcategories: [SubCategory]
    let colorScheme: ColorScheme
    let onEditCategory: () -> Void
    let onDeleteCategory: () -> Void
    let onAddSubcategory: () -> Void
    let onEditSubcategory: (SubCategory) -> Void
    let onDeleteSubcategory: (SubCategory) -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Category header
            HStack(spacing: 12) {
                // Drag handle
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

                // Category info
                HStack(spacing: 8) {
                    Circle()
                        .fill(getCategoryColor())
                        .frame(width: 16, height: 16)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.name)
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(ThemeColors.textColor(for: colorScheme))

                        Text("\(subcategories.count) \(L("subcategories"))")
                            .font(AppTypography.labelSmall)
                            .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                    }
                }

                Spacer()

                // Actions
                HStack(spacing: 8) {
                    Button(action: onAddSubcategory) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AppColors.successGreen)
                    }

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                    }

                    Menu {
                        Button(L("edit")) {
                            onEditCategory()
                        }
                        Button(L("delete"), role: .destructive) {
                            onDeleteCategory()
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                    }
                }
            }
            .padding(.vertical, 12)
            .background(ThemeColors.cardBackgroundColor(for: colorScheme))

            // Subcategories (when expanded)
            if isExpanded && !subcategories.isEmpty {
                VStack(spacing: 0) {
                    ForEach(subcategories, id: \.id) { subcategory in
                        SubcategoryRow(
                            subcategory: subcategory,
                            colorScheme: colorScheme,
                            onEdit: {
                                onEditSubcategory(subcategory)
                            },
                            onDelete: {
                                onDeleteSubcategory(subcategory)
                            }
                        )
                    }
                }
                .transition(.slide)
            }
        }
        .background(ThemeColors.cardBackgroundColor(for: colorScheme))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }

    private func getCategoryColor() -> Color {
        let colors: [Color] = [
            AppColors.primaryOrange,
            AppColors.primaryRed,
            AppColors.successGreen,
            .blue,
            .purple,
            .pink
        ]
        let hash = category.id.hashValue
        return colors[abs(hash) % colors.count]
    }
}

// MARK: - SubcategoryRow

struct SubcategoryRow: View {
    let subcategory: SubCategory
    let colorScheme: ColorScheme
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Indent indicator
            Rectangle()
                .fill(ThemeColors.textGrayColor(for: colorScheme).opacity(0.3))
                .frame(width: 2, height: 20)

            // Subcategory info
            HStack(spacing: 8) {
                Circle()
                    .fill(getSubcategoryColor())
                    .frame(width: 12, height: 12)

                Text(subcategory.name)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(ThemeColors.textColor(for: colorScheme))
            }

            Spacer()

            // Actions
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(AppColors.primaryOrange)
                        .font(AppTypography.labelMedium)
                }

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(AppColors.primaryRed)
                        .font(AppTypography.labelMedium)
                }
            }
        }
        .padding(.leading, 20)
        .padding(.trailing, 12)
        .padding(.vertical, 8)
        .background(ThemeColors.backgroundColor(for: colorScheme).opacity(0.5))
    }

    private func getSubcategoryColor() -> Color {
        let colors: [Color] = [
            AppColors.primaryOrange.opacity(0.7),
            AppColors.primaryRed.opacity(0.7),
            AppColors.successGreen.opacity(0.7),
            Color.blue.opacity(0.7),
            Color.purple.opacity(0.7),
            Color.pink.opacity(0.7)
        ]
        let hash = subcategory.id.hashValue
        return colors[abs(hash) % colors.count]
    }
}

// MARK: - Form Sheets

struct CategoryFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var expenseViewModel: ExpenseViewModel

    let editingCategory: Category?

    @State private var name = ""
    @State private var description = ""
    @State private var isLoading = false

    private var isEditing: Bool {
        editingCategory != nil
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                FormField(
                    title: L("category_name"),
                    text: $name,
                    placeholder: L("enter_category_name")
                )

                FormField(
                    title: L("description"),
                    text: $description,
                    placeholder: L("enter_description"),
                    isMultiline: true
                )

                Spacer()
            }
            .padding()
            .navigationTitle(isEditing ? L("edit_category") : L("add_category"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? L("save") : L("add")) {
                        saveCategory()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }
            }
        }
        .onAppear {
            if let category = editingCategory {
                name = category.name
                description = category.description ?? ""
            }
        }
    }

    private func saveCategory() {
        isLoading = true
        // Implementation would save category
        dismiss()
    }
}

struct SubcategoryFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var expenseViewModel: ExpenseViewModel

    let categoryId: String
    let editingSubcategory: SubCategory?

    @State private var name = ""
    @State private var description = ""
    @State private var isLoading = false

    private var isEditing: Bool {
        editingSubcategory != nil
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                FormField(
                    title: L("subcategory_name"),
                    text: $name,
                    placeholder: L("enter_subcategory_name")
                )

                FormField(
                    title: L("description"),
                    text: $description,
                    placeholder: L("enter_description"),
                    isMultiline: true
                )

                Spacer()
            }
            .padding()
            .navigationTitle(isEditing ? L("edit_subcategory") : L("add_subcategory"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? L("save") : L("add")) {
                        saveSubcategory()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }
            }
        }
        .onAppear {
            if let subcategory = editingSubcategory {
                name = subcategory.name
                description = subcategory.description ?? ""
            }
        }
    }

    private func saveSubcategory() {
        isLoading = true
        // Implementation would save subcategory
        dismiss()
    }
}

// MARK: - FormField Component

struct FormField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var isMultiline: Bool = false
    var error: String? = nil

    @Binding var value: Double
    var isPercentage: Bool = false

    init(title: String, text: Binding<String>, placeholder: String, isMultiline: Bool = false, error: String? = nil) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.isMultiline = isMultiline
        self.error = error
        self._value = .constant(0)
    }

    init(title: String, value: Binding<Double>, placeholder: String, isPercentage: Bool = false, error: String? = nil) {
        self.title = title
        self._value = value
        self.placeholder = placeholder
        self.isPercentage = isPercentage
        self.error = error
        self._text = .constant("")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppTypography.fieldLabel)

            if isMultiline {
                TextEditor(text: $text)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            } else if _value.wrappedValue != 0 || _text.wrappedValue.isEmpty {
                TextField(placeholder, value: $value, format: .number)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            if let error = error {
                Text(error)
                    .font(AppTypography.errorText)
                    .foregroundColor(.red)
            }
        }
    }
}

#if DEBUG
struct CategoryManagementView_Previews: PreviewProvider {
    static var previews: some View {
        CategoryManagementView(
            expenseViewModel: ExpenseViewModel.preview
        )
    }
}
#endif