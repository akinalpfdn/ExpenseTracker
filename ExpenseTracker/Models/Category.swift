//
//  Category.swift
//  ExpenseTracker
//
//  Created by migration from Android Category.kt
//

import Foundation
import SwiftUI

struct Category: Identifiable, Codable {
    let id: String
    let name: String
    let colorHex: String
    let iconName: String
    let isDefault: Bool
    let isCustom: Bool

    init(id: String, name: String, colorHex: String, iconName: String, isDefault: Bool = false, isCustom: Bool = false) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
        self.isDefault = isDefault
        self.isCustom = isCustom
    }

    func getColor() -> Color {
        return Color(hex: colorHex) ?? .blue
    }

    func getIcon() -> String {
        switch iconName {
        case "restaurant": return "fork.knife"
        case "home": return "house"
        case "directions_car": return "car"
        case "local_hospital": return "cross.case"
        case "movie": return "tv"
        case "school": return "graduationcap"
        case "shopping_cart": return "cart"
        case "pets": return "pawprint"
        case "work": return "briefcase"
        case "account_balance": return "building.columns"
        case "favorite": return "heart"
        case "category": return "square.grid.2x2"
        case "sports": return "sportscourt"
        case "music_note": return "music.note"
        case "flight": return "airplane"
        case "hotel": return "bed.double"
        case "restaurant_menu": return "menucard"
        case "local_gas_station": return "fuelpump"
        case "phone": return "phone"
        case "computer": return "laptopcomputer"
        case "book": return "book"
        case "cake": return "birthday.cake"
        case "coffee": return "cup.and.saucer"
        case "directions_bus": return "bus"
        case "directions_walk": return "figure.walk"
        case "eco": return "leaf"
        case "fitness_center": return "dumbbell"
        case "gavel": return "hammer"
        case "healing": return "plus.circle"
        case "kitchen": return "oven"
        case "local_laundry_service": return "washer"
        case "local_pharmacy": return "pills"
        case "local_pizza": return "pizzaslice"
        case "local_shipping": return "shippingbox"
        case "lunch_dining": return "takeoutbag.and.cup.and.straw"
        case "monetization_on": return "dollarsign.circle"
        case "palette": return "paintpalette"
        case "park": return "tree"
        case "pool": return "figure.pool.swim"
        case "psychology": return "brain.head.profile"
        case "receipt": return "receipt"
        case "security": return "shield"
        case "spa": return "sparkles"
        case "star": return "star"
        case "theater_comedy": return "theatermasks"
        case "toys": return "teddybear"
        case "volunteer_activism": return "hands.sparkles"
        case "water_drop": return "drop"
        case "wifi": return "wifi"
        default: return "square.grid.2x2"
        }
    }

    static func getDefaultCategories() -> [Category] {
        return [
            Category(
                id: "food",
                name: "category_food".localized,
                colorHex: "#FF9500",
                iconName: "restaurant",
                isDefault: true
            ),
            Category(
                id: "housing",
                name: "category_housing".localized,
                colorHex: "#007AFF",
                iconName: "home",
                isDefault: true
            ),
            Category(
                id: "transportation",
                name: "category_transportation".localized,
                colorHex: "#34C759",
                iconName: "directions_car",
                isDefault: true
            ),
            Category(
                id: "health",
                name: "category_health".localized,
                colorHex: "#FF2D92",
                iconName: "local_hospital",
                isDefault: true
            ),
            Category(
                id: "entertainment",
                name: "category_entertainment".localized,
                colorHex: "#9D73E3",
                iconName: "movie",
                isDefault: true
            ),
            Category(
                id: "education",
                name: "category_education".localized,
                colorHex: "#5856D6",
                iconName: "school",
                isDefault: true
            ),
            Category(
                id: "shopping",
                name: "category_shopping".localized,
                colorHex: "#FF3B30",
                iconName: "shopping_cart",
                isDefault: true
            ),
            Category(
                id: "pets",
                name: "category_pets".localized,
                colorHex: "#64D2FF",
                iconName: "pets",
                isDefault: true
            ),
            Category(
                id: "work",
                name: "category_work".localized,
                colorHex: "#5AC8FA",
                iconName: "work",
                isDefault: true
            ),
            Category(
                id: "tax",
                name: "category_tax".localized,
                colorHex: "#FFD60A",
                iconName: "account_balance",
                isDefault: true
            ),
            Category(
                id: "others",
                name: "category_others".localized,
                colorHex: "#3F51B5",
                iconName: "category",
                isDefault: true
            )
        ]
    }
}

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}