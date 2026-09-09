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

    /// Counts use over a trailing window rather than all history, so the order tracks
    /// what someone is spending on now instead of what they were spending on a year
    /// ago. The trade-off is that the order can shift with no user action, when an
    /// expense ages out of the window — visible only among near-ties.
    ///
    /// Future-dated rows are excluded, and that exclusion is load-bearing: recurring
    /// expenses are stored as individual occurrences up to a year ahead, so counting
    /// them would let one subscription outrank a category picked by hand every week.
    init(
        expenses: [Expense],
        now: Date = Date(),
        windowMonths: Int = 3,
        calendar: Calendar = .current
    ) {
        let cutoff = calendar.date(byAdding: .month, value: -windowMonths, to: now) ?? now

        var subCounts: [String: Int] = [:]
        var catCounts: [String: Int] = [:]

        for expense in expenses where expense.date >= cutoff && expense.date <= now {
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
