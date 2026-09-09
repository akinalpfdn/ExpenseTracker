//
//  CategoryUsageRanking.swift
//  ExpenseTracker
//
//  Orders the add-expense picker by how often each entry actually gets used, so the
//  handful of categories someone reaches for daily are not scattered through the
//  alphabet.
//

import Foundation

struct CategoryUsageRanking {

    /// Number of expenses filed under each subcategory id.
    private let subCategoryCounts: [String: Int]

    /// Number of expenses filed under each category id, summed across its
    /// subcategories.
    private let categoryCounts: [String: Int]

    /// Counts every expense in history rather than a recent window. Predictable — the
    /// order only moves when you actually use something — at the cost of adapting
    /// slowly if spending habits change.
    init(expenses: [Expense]) {
        var subCounts: [String: Int] = [:]
        var catCounts: [String: Int] = [:]

        for expense in expenses {
            subCounts[expense.subCategoryId, default: 0] += 1
            catCounts[expense.categoryId, default: 0] += 1
        }

        self.subCategoryCounts = subCounts
        self.categoryCounts = catCounts
    }

    // MARK: - Ordering

    /// Most-used first. Alphabetical among equals, so the order is stable and an
    /// untouched list still reads sensibly.
    func sorted(_ categories: [Category]) -> [Category] {
        return categories.sorted { left, right in
            let leftCount = categoryCounts[left.id] ?? 0
            let rightCount = categoryCounts[right.id] ?? 0

            if leftCount != rightCount {
                return leftCount > rightCount
            }
            return left.name.localizedCaseInsensitiveCompare(right.name) == .orderedAscending
        }
    }

    func sorted(_ subCategories: [SubCategory]) -> [SubCategory] {
        return subCategories.sorted { left, right in
            let leftCount = subCategoryCounts[left.id] ?? 0
            let rightCount = subCategoryCounts[right.id] ?? 0

            if leftCount != rightCount {
                return leftCount > rightCount
            }
            return left.name.localizedCaseInsensitiveCompare(right.name) == .orderedAscending
        }
    }

    // MARK: - Inspection

    func usageCount(forCategory id: String) -> Int {
        return categoryCounts[id] ?? 0
    }

    func usageCount(forSubCategory id: String) -> Int {
        return subCategoryCounts[id] ?? 0
    }
}
