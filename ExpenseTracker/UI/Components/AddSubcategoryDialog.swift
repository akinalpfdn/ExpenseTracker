//
//  AddSubcategoryDialog.swift
//  ExpenseTracker
//
//  Created by migration from Android CategoryManagementScreen.kt
//

import SwiftUI

struct AddSubcategoryDialog: View {
    let selectedCategory: Category?
    let onDismiss: () -> Void
    let onConfirm: (String) -> Void
    let isDarkTheme: Bool

    @State private var subcategoryName = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                mainCategorySection
                subcategoryNameSection
                Spacer()
            }
            .padding(24)
            .navigationTitle("add_subcategory".localized)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("cancel".localized, action: onDismiss),
                trailing: Button("add_button".localized) {
                    onConfirm(subcategoryName)
                }
                .disabled(subcategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
    }

    private var mainCategorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("main_category".localized)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            Text(selectedCategory?.name ?? "select_category".localized)
                .font(.system(size: 14))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(ThemeColors.getInputBackgroundColor(isDarkTheme: isDarkTheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme), lineWidth: 1)
                )
                .cornerRadius(12)
        }
    }

    private var subcategoryNameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("subcategory_name".localized)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            TextField("subcategory_name_hint".localized, text: $subcategoryName)
                .textFieldStyle(CustomTextFieldStyle(isDarkTheme: isDarkTheme))

            Text("unique_subcategory_name_note".localized)
                .font(.system(size: 14))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
        }
    }
}

// MARK: - Preview
struct AddSubcategoryDialog_Previews: PreviewProvider {
    static var previews: some View {
        let sampleCategory = Category.getDefaultCategories()[0]

        AddSubcategoryDialog(
            selectedCategory: sampleCategory,
            onDismiss: { },
            onConfirm: { _ in },
            isDarkTheme: true
        )
    }
}