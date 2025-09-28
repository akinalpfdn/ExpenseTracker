//
//  SubCategory.swift
//  ExpenseTracker
//
//  Created by migration from Android SubCategory.kt
//

import Foundation

struct SubCategory: Identifiable, Codable {
    let id: String
    let name: String
    let categoryId: String
    let isDefault: Bool
    let isCustom: Bool

    init(id: String = UUID().uuidString, name: String, categoryId: String, isDefault: Bool = false, isCustom: Bool = false) {
        self.id = id
        self.name = name
        self.categoryId = categoryId
        self.isDefault = isDefault
        self.isCustom = isCustom
    }

    static func getDefaultSubCategories() -> [SubCategory] {
        return [
            // Gıda ve İçecek
            SubCategory(name: "subcategory_restaurant".localized, categoryId: "food", isDefault: true),
            SubCategory(name: "subcategory_kitchen_shopping".localized, categoryId: "food", isDefault: true),

            // Konut
            SubCategory(name: "subcategory_rent".localized, categoryId: "housing", isDefault: true),
            SubCategory(name: "subcategory_dues".localized, categoryId: "housing", isDefault: true),
            SubCategory(name: "subcategory_mortgage".localized, categoryId: "housing", isDefault: true),
            SubCategory(name: "subcategory_electricity".localized, categoryId: "housing", isDefault: true),
            SubCategory(name: "subcategory_water".localized, categoryId: "housing", isDefault: true),
            SubCategory(name: "subcategory_heating".localized, categoryId: "housing", isDefault: true),
            SubCategory(name: "subcategory_internet_phone".localized, categoryId: "housing", isDefault: true),
            SubCategory(name: "subcategory_other_bills".localized, categoryId: "housing", isDefault: true),
            SubCategory(name: "subcategory_general_shopping".localized, categoryId: "housing", isDefault: true),

            // Ulaşım
            SubCategory(name: "subcategory_fuel".localized, categoryId: "transportation", isDefault: true),
            SubCategory(name: "subcategory_public_transport".localized, categoryId: "transportation", isDefault: true),
            SubCategory(name: "subcategory_car_maintenance".localized, categoryId: "transportation", isDefault: true),
            SubCategory(name: "subcategory_car_rental".localized, categoryId: "transportation", isDefault: true),
            SubCategory(name: "subcategory_taxi_uber".localized, categoryId: "transportation", isDefault: true),
            SubCategory(name: "subcategory_car_insurance".localized, categoryId: "transportation", isDefault: true),
            SubCategory(name: "subcategory_mtv".localized, categoryId: "transportation", isDefault: true),
            SubCategory(name: "subcategory_parking_fees".localized, categoryId: "transportation", isDefault: true),

            // Sağlık
            SubCategory(name: "subcategory_doctor_appointment".localized, categoryId: "health", isDefault: true),
            SubCategory(name: "subcategory_medicines".localized, categoryId: "health", isDefault: true),
            SubCategory(name: "subcategory_gym_membership".localized, categoryId: "health", isDefault: true),
            SubCategory(name: "subcategory_cosmetics".localized, categoryId: "health", isDefault: true),

            // Eğlence
            SubCategory(name: "subcategory_cinema_theater".localized, categoryId: "entertainment", isDefault: true),
            SubCategory(name: "subcategory_concerts_events".localized, categoryId: "entertainment", isDefault: true),
            SubCategory(name: "subcategory_subscriptions".localized, categoryId: "entertainment", isDefault: true),
            SubCategory(name: "subcategory_books_magazines".localized, categoryId: "entertainment", isDefault: true),
            SubCategory(name: "subcategory_travel_vacation".localized, categoryId: "entertainment", isDefault: true),
            SubCategory(name: "subcategory_games_apps".localized, categoryId: "entertainment", isDefault: true),

            // Eğitim
            SubCategory(name: "subcategory_course_fees".localized, categoryId: "education", isDefault: true),
            SubCategory(name: "subcategory_education_materials".localized, categoryId: "education", isDefault: true),
            SubCategory(name: "subcategory_seminars".localized, categoryId: "education", isDefault: true),
            SubCategory(name: "subcategory_online_courses".localized, categoryId: "education", isDefault: true),

            // Alışveriş
            SubCategory(name: "subcategory_electronics".localized, categoryId: "shopping", isDefault: true),
            SubCategory(name: "subcategory_clothing".localized, categoryId: "shopping", isDefault: true),
            SubCategory(name: "subcategory_home_goods".localized, categoryId: "shopping", isDefault: true),
            SubCategory(name: "subcategory_gifts".localized, categoryId: "shopping", isDefault: true),
            SubCategory(name: "subcategory_perfume".localized, categoryId: "shopping", isDefault: true),

            // Evcil Hayvan
            SubCategory(name: "subcategory_pet_food_toys".localized, categoryId: "pets", isDefault: true),
            SubCategory(name: "subcategory_vet_services".localized, categoryId: "pets", isDefault: true),
            SubCategory(name: "subcategory_pet_insurance".localized, categoryId: "pets", isDefault: true),

            // İş
            SubCategory(name: "subcategory_work_meals".localized, categoryId: "work", isDefault: true),
            SubCategory(name: "subcategory_office_supplies".localized, categoryId: "work", isDefault: true),
            SubCategory(name: "subcategory_business_travel".localized, categoryId: "work", isDefault: true),
            SubCategory(name: "subcategory_work_education".localized, categoryId: "work", isDefault: true),
            SubCategory(name: "subcategory_freelance_payments".localized, categoryId: "work", isDefault: true),

            // Vergi
            SubCategory(name: "subcategory_tax_payments".localized, categoryId: "tax", isDefault: true),
            // Diğer
            SubCategory(name: "subcategory_other_expenses".localized, categoryId: "others", isDefault: true)
        ]
    }
}