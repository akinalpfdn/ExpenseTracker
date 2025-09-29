//
//  CategoryManagementView.swift
//  ExpenseTracker
//
//  Created by migration from Android CategoryManagementScreen.kt
//

import SwiftUI

struct CategoryManagementView: View {
    @EnvironmentObject var viewModel: ExpenseViewModel
    let isDarkTheme: Bool

    @State private var expandedCategories: Set<String> = []
    @State private var showAddMainCategoryDialog = false
    @State private var showAddSubcategoryDialog = false
    @State private var selectedCategoryForSubcategory: Category?
    @State private var showEditCategoryDialog = false
    @State private var showDeleteConfirmationDialog = false
    @State private var selectedCategory: Category?
    @State private var selectedSubcategory: SubCategory?

    init(isDarkTheme: Bool = true) {
        self.isDarkTheme = isDarkTheme
    }

    var body: some View {
        VStack(spacing: 20) {
            categoryTreeView
            addButtonsSection
        }
        .padding(20)
        .sheet(isPresented: $showAddMainCategoryDialog) {
            AddMainCategoryDialog(
                onDismiss: { showAddMainCategoryDialog = false },
                onConfirm: { categoryName, iconName, colorHex in
                    viewModel.createCustomCategory(
                        name: categoryName,
                        colorHex: colorHex,
                        iconName: iconName
                    )
                    showAddMainCategoryDialog = false
                },
                isDarkTheme: isDarkTheme
            )
        }
        .sheet(isPresented: $showAddSubcategoryDialog) {
            AddSubcategoryDialog(
                selectedCategory: selectedCategoryForSubcategory,
                onDismiss: {
                    showAddSubcategoryDialog = false
                    selectedCategoryForSubcategory = nil
                },
                onConfirm: { subcategoryName in
                    if let category = selectedCategoryForSubcategory {
                        viewModel.createCustomSubCategory(
                            name: subcategoryName,
                            categoryId: category.id
                        )
                    }
                    showAddSubcategoryDialog = false
                    selectedCategoryForSubcategory = nil
                },
                isDarkTheme: isDarkTheme
            )
        }
        .sheet(isPresented: $showEditCategoryDialog) {
            EditCategoryDialog(
                category: selectedCategory,
                subcategory: selectedSubcategory,
                onDismiss: {
                    showEditCategoryDialog = false
                    selectedCategory = nil
                    selectedSubcategory = nil
                },
                onConfirm: { newName, iconName, colorHex in
                    if let subcat = selectedSubcategory {
                        let updatedSubCategory = SubCategory(
                            id: subcat.id,
                            name: newName, categoryId: subcat.categoryId,
                            isCustom: subcat.isCustom
                        )
                        viewModel.updateSubCategory(updatedSubCategory)
                    } else if let cat = selectedCategory, let icon = iconName, let color = colorHex {
                        let updatedCategory = Category(
                            id: cat.id,
                            name: newName,
                            colorHex: color, iconName: icon,
                            isCustom: cat.isCustom
                        )
                        viewModel.updateCategory(updatedCategory)
                    }
                    showEditCategoryDialog = false
                    selectedCategory = nil
                    selectedSubcategory = nil
                },
                isDarkTheme: isDarkTheme
            )
        }
        .alert("delete_confirmation".localized, isPresented: $showDeleteConfirmationDialog) {
            Button("delete".localized, role: .destructive) {
                if let subcat = selectedSubcategory {
                    viewModel.deleteSubCategory(subcat)
                } else if let cat = selectedCategory {
                    viewModel.deleteCategory(cat)
                }
                selectedCategory = nil
                selectedSubcategory = nil
            }
            Button("cancel".localized, role: .cancel) {
                selectedCategory = nil
                selectedSubcategory = nil
            }
        } message: {
            let itemName = selectedSubcategory?.name ?? selectedCategory?.name ?? ""
            Text("delete_item_confirmation".localized.replacingOccurrences(of: "%@", with: itemName))
        }
    }
}

// MARK: - View Components
extension CategoryManagementView {
    private var categoryTreeView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.categories, id: \.id) { category in
                    CategoryTreeItem(
                        category: category,
                        isExpanded: expandedCategories.contains(category.id),
                        onToggleExpanded: {
                            if expandedCategories.contains(category.id) {
                                expandedCategories.remove(category.id)
                            } else {
                                expandedCategories.insert(category.id)
                            }
                        },
                        onEdit: {
                            selectedCategory = category
                            selectedSubcategory = nil
                            showEditCategoryDialog = true
                        },
                        onDelete: {
                            selectedCategory = category
                            selectedSubcategory = nil
                            showDeleteConfirmationDialog = true
                        },
                        onEditSubcategory: { subcategory in
                            selectedSubcategory = subcategory
                            selectedCategory = nil
                            showEditCategoryDialog = true
                        },
                        onDeleteSubcategory: { subcategory in
                            selectedSubcategory = subcategory
                            selectedCategory = nil
                            showDeleteConfirmationDialog = true
                        },
                        onAddSubcategory: { category in
                            selectedCategoryForSubcategory = category
                            showAddSubcategoryDialog = true
                        },
                        allSubcategories: viewModel.subCategories,
                        isDarkTheme: isDarkTheme
                    )
                }
            }
        }
    }

    private var addButtonsSection: some View {
        VStack(spacing: 12) {
            Button(action: { showAddMainCategoryDialog = true }) {
                HStack {
                    Image(systemName: "plus")
                        .font(.system(size: 20))

                    Text("add_new_main_category".localized)
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(AppColors.primaryOrange)
                .cornerRadius(16)
            }
        }
    }
}

struct CategoryTreeItem: View {
    let category: Category
    let isExpanded: Bool
    let onToggleExpanded: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onEditSubcategory: (SubCategory) -> Void
    let onDeleteSubcategory: (SubCategory) -> Void
    let onAddSubcategory: (Category) -> Void
    let allSubcategories: [SubCategory]
    let isDarkTheme: Bool

    private var subCategories: [SubCategory] {
        allSubcategories.filter { $0.categoryId == category.id }
    }

    var body: some View {
        VStack(spacing: 0) {
            mainCategoryRow

            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(subCategories, id: \.id) { subCategory in
                        SubCategoryItem(
                            subCategory: subCategory,
                            onEdit: { onEditSubcategory(subCategory) },
                            onDelete: { onDeleteSubcategory(subCategory) },
                            isDarkTheme: isDarkTheme
                        )
                        .padding(.leading, 48)
                        .padding(.trailing, 16)
                        .padding(.bottom, 8)
                    }

                    addSubcategoryButton
                }
            }
        }
        .background(ThemeColors.getInputBackgroundColor(isDarkTheme: isDarkTheme))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme).opacity(0.2), lineWidth: 1)
        )
    }

    private var mainCategoryRow: some View {
        HStack {
            Button(action: onToggleExpanded) {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                    .font(.system(size: 20))
            }

            Spacer().frame(width: 12)

            categoryIcon

            Spacer().frame(width: 12)

            Text(category.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            Spacer()

            actionButtons
        }
        .padding(16)
    }

    private var categoryIcon: some View {
        ZStack {
            Circle()
                .fill(category.getColor().opacity(0.2))
                .frame(width: 32, height: 32)

            Image(systemName: category.getIcon())
                .foregroundColor(category.getColor())
                .font(.system(size: 20))
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .foregroundColor(AppColors.primaryOrange)
                    .font(.system(size: 16))
            }
            .frame(width: 32, height: 32)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .font(.system(size: 16))
            }
            .frame(width: 32, height: 32)
        }
    }

    private var addSubcategoryButton: some View {
        Button(action: { onAddSubcategory(category) }) {
            HStack {
                Image(systemName: "plus")
                    .font(.system(size: 16))

                Text("add_subcategory".localized)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(AppColors.primaryOrange)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.primaryOrange, lineWidth: 1)
            )
        }
        .padding(.horizontal, 48)
        .padding(.bottom, 8)
    }
}

struct SubCategoryItem: View {
    let subCategory: SubCategory
    let onEdit: () -> Void
    let onDelete: () -> Void
    let isDarkTheme: Bool

    var body: some View {
        HStack {
            Circle()
                .fill(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                .frame(width: 6, height: 6)

            Spacer().frame(width: 12)

            Text(subCategory.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            Spacer()

            HStack(spacing: 4) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(AppColors.primaryOrange)
                        .font(.system(size: 14))
                }
                .frame(width: 28, height: 28)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.system(size: 14))
                }
                .frame(width: 28, height: 28)
            }
        }
        .padding(12)
        .background(ThemeColors.getBackgroundColor(isDarkTheme: isDarkTheme))
        .cornerRadius(8)
    }
}

// MARK: - Preview
struct CategoryManagementView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleViewModel = ExpenseViewModel()

        CategoryManagementView(isDarkTheme: true)
            .environmentObject(sampleViewModel)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
