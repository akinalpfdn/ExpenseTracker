//
//  CategoryRepository.swift
//  ExpenseTracker
//
//  Created by migration from Android CategoryRepository.kt
//

import Foundation

class CategoryRepository:ObservableObject {
    private let categoryDataAccess: CategoryDataAccess

    init(categoryDataAccess: CategoryDataAccess = CategoryDataAccess()) {
        self.categoryDataAccess = categoryDataAccess
    }

    // MARK: - Category Operations

    func getAllCategories() async throws -> [Category] {
        return try await categoryDataAccess.getAllCategories()
    }

    func insertCategory(_ category: Category) async throws {
        try await categoryDataAccess.insertCategory(category)
    }

    func updateCategory(_ category: Category) async throws {
        try await categoryDataAccess.updateCategory(category)
    }

    func deleteCategory(_ category: Category) async throws {
        try await categoryDataAccess.deleteCategory(category)
    }

    // MARK: - SubCategory Operations

    func getAllSubCategories() async throws -> [SubCategory] {
        return try await categoryDataAccess.getAllSubCategories()
    }

    func insertSubCategory(_ subCategory: SubCategory) async throws {
        try await categoryDataAccess.insertSubCategory(subCategory)
    }

    func updateSubCategory(_ subCategory: SubCategory) async throws {
        try await categoryDataAccess.updateSubCategory(subCategory)
    }

    func deleteSubCategory(_ subCategory: SubCategory) async throws {
        try await categoryDataAccess.deleteSubCategory(subCategory)
    }

    // MARK: - Helper Methods

    func createCustomCategory(name: String, colorHex: String, iconName: String) async throws -> Category {
        let category = Category(
            id: UUID().uuidString,
            name: name,
            colorHex: colorHex,
            iconName: iconName,
            isDefault: false,
            isCustom: true
        )
        try await insertCategory(category)
        return category
    }

    func createCustomSubCategory(name: String, categoryId: String) async throws -> SubCategory {
        let subCategory = SubCategory(
            name: name,
            categoryId: categoryId,
            isDefault: false,
            isCustom: true
        )
        try await insertSubCategory(subCategory)
        return subCategory
    }

    // MARK: - Initialization

    func isDefaultDataInitialized() async throws -> Bool {
        let categoriesCount = try await categoryDataAccess.getDefaultCategoriesCount()
        let subCategoriesCount = try await categoryDataAccess.getDefaultSubCategoriesCount()
        return categoriesCount > 0 && subCategoriesCount > 0
    }

    func initializeDefaultDataIfNeeded() async throws {
        if try await !isDefaultDataInitialized() {
            try await categoryDataAccess.insertCategories(Category.getDefaultCategories())
            try await categoryDataAccess.insertSubCategories(SubCategory.getDefaultSubCategories())
        }
    }
}
