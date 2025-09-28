//
//  CategoryDataAccess.swift
//  ExpenseTracker
//
//  Created by migration from Android CategoryDao.kt
//

import Foundation
import CoreData

class CategoryDataAccess {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = CoreDataStack.shared.context) {
        self.context = context
    }

    // MARK: - Category Operations

    func getAllCategories() async throws -> [Category] {
        let request: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        let entities = try context.fetch(request)
        return entities.map { Category(from: $0) }
    }

    func getCategoryById(_ categoryId: String) async throws -> Category? {
        let request: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", categoryId)
        request.fetchLimit = 1

        let entities = try context.fetch(request)
        return entities.first.map { Category(from: $0) }
    }

    func getDefaultCategories() async throws -> [Category] {
        let request: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isDefault == YES")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        let entities = try context.fetch(request)
        return entities.map { Category(from: $0) }
    }

    func getCustomCategories() async throws -> [Category] {
        let request: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isCustom == YES")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        let entities = try context.fetch(request)
        return entities.map { Category(from: $0) }
    }

    func insertCategory(_ category: Category) async throws {
        let entity = category.toCoreData(context: context)
        try context.save()
    }

    func insertCategories(_ categories: [Category]) async throws {
        for category in categories {
            _ = category.toCoreData(context: context)
        }
        try context.save()
    }

    func updateCategory(_ category: Category) async throws {
        let request: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", category.id)
        request.fetchLimit = 1

        let entities = try context.fetch(request)
        if let entity = entities.first {
            entity.name = category.name
            entity.colorHex = category.colorHex
            entity.iconName = category.iconName
            entity.isDefault = category.isDefault
            entity.isCustom = category.isCustom
            try context.save()
        }
    }

    func deleteCategory(_ category: Category) async throws {
        let request: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", category.id)

        let entities = try context.fetch(request)
        for entity in entities {
            context.delete(entity)
        }
        try context.save()
    }

    func deleteCategoryById(_ categoryId: String) async throws {
        let request: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", categoryId)

        let entities = try context.fetch(request)
        for entity in entities {
            context.delete(entity)
        }
        try context.save()
    }

    // MARK: - SubCategory Operations

    func getAllSubCategories() async throws -> [SubCategory] {
        let request: NSFetchRequest<SubCategoryEntity> = SubCategoryEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        let entities = try context.fetch(request)
        return entities.map { SubCategory(from: $0) }
    }

    func getSubCategoriesByCategoryId(_ categoryId: String) async throws -> [SubCategory] {
        let request: NSFetchRequest<SubCategoryEntity> = SubCategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "categoryId == %@", categoryId)
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        let entities = try context.fetch(request)
        return entities.map { SubCategory(from: $0) }
    }

    func getSubCategoryById(_ subCategoryId: String) async throws -> SubCategory? {
        let request: NSFetchRequest<SubCategoryEntity> = SubCategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", subCategoryId)
        request.fetchLimit = 1

        let entities = try context.fetch(request)
        return entities.first.map { SubCategory(from: $0) }
    }

    func getDefaultSubCategories() async throws -> [SubCategory] {
        let request: NSFetchRequest<SubCategoryEntity> = SubCategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isDefault == YES")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        let entities = try context.fetch(request)
        return entities.map { SubCategory(from: $0) }
    }

    func getCustomSubCategories() async throws -> [SubCategory] {
        let request: NSFetchRequest<SubCategoryEntity> = SubCategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isCustom == YES")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        let entities = try context.fetch(request)
        return entities.map { SubCategory(from: $0) }
    }

    func insertSubCategory(_ subCategory: SubCategory) async throws {
        let entity = subCategory.toCoreData(context: context)
        try context.save()
    }

    func insertSubCategories(_ subCategories: [SubCategory]) async throws {
        for subCategory in subCategories {
            _ = subCategory.toCoreData(context: context)
        }
        try context.save()
    }

    func updateSubCategory(_ subCategory: SubCategory) async throws {
        let request: NSFetchRequest<SubCategoryEntity> = SubCategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", subCategory.id)
        request.fetchLimit = 1

        let entities = try context.fetch(request)
        if let entity = entities.first {
            entity.name = subCategory.name
            entity.categoryId = subCategory.categoryId
            entity.isDefault = subCategory.isDefault
            entity.isCustom = subCategory.isCustom
            try context.save()
        }
    }

    func deleteSubCategory(_ subCategory: SubCategory) async throws {
        let request: NSFetchRequest<SubCategoryEntity> = SubCategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", subCategory.id)

        let entities = try context.fetch(request)
        for entity in entities {
            context.delete(entity)
        }
        try context.save()
    }

    func deleteSubCategoryById(_ subCategoryId: String) async throws {
        let request: NSFetchRequest<SubCategoryEntity> = SubCategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", subCategoryId)

        let entities = try context.fetch(request)
        for entity in entities {
            context.delete(entity)
        }
        try context.save()
    }

    // MARK: - Combined Operations

    func getCategoriesWithSubCategories() async throws -> [Category: [SubCategory]] {
        let categoryRequest: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
        categoryRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        let categoryEntities = try context.fetch(categoryRequest)
        var result: [Category: [SubCategory]] = [:]

        for categoryEntity in categoryEntities {
            let category = Category(from: categoryEntity)

            let subCategoryRequest: NSFetchRequest<SubCategoryEntity> = SubCategoryEntity.fetchRequest()
            subCategoryRequest.predicate = NSPredicate(format: "categoryId == %@", category.id)
            subCategoryRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

            let subCategoryEntities = try context.fetch(subCategoryRequest)
            let subCategories = subCategoryEntities.map { SubCategory(from: $0) }

            result[category] = subCategories
        }

        return result
    }

    // MARK: - Check Operations

    func getDefaultCategoriesCount() async throws -> Int {
        let request: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isDefault == YES")

        return try context.count(for: request)
    }

    func getDefaultSubCategoriesCount() async throws -> Int {
        let request: NSFetchRequest<SubCategoryEntity> = SubCategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isDefault == YES")

        return try context.count(for: request)
    }
}

// MARK: - Core Data Error Handling
enum CoreDataError: Error {
    case contextNotAvailable
    case entityNotFound
    case saveError(Error)
}

