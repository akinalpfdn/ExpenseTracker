//
//  Expense.swift
//  ExpenseTracker
//
//  Created by Akinalp Fidan on 11.08.2025.
//

import Foundation

// MARK: - Expense Category
enum ExpenseCategory: String, CaseIterable {
    case food = "Gıda ve İçecek"
    case housing = "Konut"
    case transportation = "Ulaşım"
    case health = "Sağlık ve Kişisel Bakım"
    case entertainment = "Eğlence ve Hobiler"
    case education = "Eğitim"
    case shopping = "Alışveriş"
    case pets = "Evcil Hayvan"
    case work = "İş ve Profesyonel Harcamalar"
    case tax = "Vergi ve Hukuki Harcamalar"
    case donations = "Bağışlar ve Yardımlar"
}

// MARK: - Expense Sub Category
struct ExpenseSubCategory {
    let name: String
    let category: ExpenseCategory
}

// MARK: - Expense Model
struct Expense: Identifiable {
    let id = UUID()
    var amount: Double
    var currency: String
    var subCategory: String
    var description: String
    var date: Date
    
    var category: ExpenseCategory {
        return CategoryHelper.getCategoryForSubCategory(subCategory)
    }
}
