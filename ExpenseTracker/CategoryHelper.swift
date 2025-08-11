//
//  CategoryHelper.swift
//  ExpenseTracker
//
//  Created by Akinalp Fidan on 11.08.2025.
//

import Foundation
import SwiftUI

// MARK: - Category Helper
struct CategoryHelper {
    
    // MARK: - Sub Categories
    static let subCategories: [ExpenseSubCategory] = [
        // Gıda ve İçecek
        ExpenseSubCategory(name: "Restoran", category: .food),
        ExpenseSubCategory(name: "Market alışverişi", category: .food),
        ExpenseSubCategory(name: "Kafeler", category: .food),
        ExpenseSubCategory(name: "Fast food", category: .food),
        ExpenseSubCategory(name: "Evde yemek (malzeme)", category: .food),
        ExpenseSubCategory(name: "Su ve içecek", category: .food),
        
        // Konut
        ExpenseSubCategory(name: "Kira", category: .housing),
        ExpenseSubCategory(name: "Mortgage ödemesi", category: .housing),
        ExpenseSubCategory(name: "Elektrik faturası", category: .housing),
        ExpenseSubCategory(name: "Su faturası", category: .housing),
        ExpenseSubCategory(name: "Isınma (doğalgaz, kalorifer)", category: .housing),
        ExpenseSubCategory(name: "İnternet ve telefon", category: .housing),
        ExpenseSubCategory(name: "Temizlik malzemeleri", category: .housing),
        
        // Ulaşım
        ExpenseSubCategory(name: "Benzin/Dizel", category: .transportation),
        ExpenseSubCategory(name: "Toplu taşıma", category: .transportation),
        ExpenseSubCategory(name: "Araç bakımı", category: .transportation),
        ExpenseSubCategory(name: "Oto kiralama", category: .transportation),
        ExpenseSubCategory(name: "Taksi/Uber", category: .transportation),
        ExpenseSubCategory(name: "Araç sigortası", category: .transportation),
        ExpenseSubCategory(name: "Park ücretleri", category: .transportation),
        
        // Sağlık
        ExpenseSubCategory(name: "Doktor randevusu", category: .health),
        ExpenseSubCategory(name: "İlaçlar", category: .health),
        ExpenseSubCategory(name: "Spor salonu üyeliği", category: .health),
        ExpenseSubCategory(name: "Cilt bakım ürünleri", category: .health),
        ExpenseSubCategory(name: "Diş bakımı", category: .health),
        ExpenseSubCategory(name: "Giyim ve aksesuar", category: .health),
        ExpenseSubCategory(name: "Parfüm", category: .health),
        
        // Eğlence
        ExpenseSubCategory(name: "Sinema ve tiyatro", category: .entertainment),
        ExpenseSubCategory(name: "Konser ve etkinlikler", category: .entertainment),
        ExpenseSubCategory(name: "Abonelikler (Netflix, Spotify vb.)", category: .entertainment),
        ExpenseSubCategory(name: "Kitaplar ve dergiler", category: .entertainment),
        ExpenseSubCategory(name: "Seyahat ve tatil", category: .entertainment),
        ExpenseSubCategory(name: "Oyunlar ve uygulamalar", category: .entertainment),
        
        // Eğitim
        ExpenseSubCategory(name: "Kurs ücretleri", category: .education),
        ExpenseSubCategory(name: "Kitaplar", category: .education),
        ExpenseSubCategory(name: "Eğitim materyalleri", category: .education),
        ExpenseSubCategory(name: "Seminerler", category: .education),
        ExpenseSubCategory(name: "Online kurslar", category: .education),
        
        // Alışveriş
        ExpenseSubCategory(name: "Elektronik", category: .shopping),
        ExpenseSubCategory(name: "Giysi", category: .shopping),
        ExpenseSubCategory(name: "Ayakkabı", category: .shopping),
        ExpenseSubCategory(name: "Ev eşyaları", category: .shopping),
        ExpenseSubCategory(name: "Hediyeler", category: .shopping),
        ExpenseSubCategory(name: "Takı ve aksesuar", category: .shopping),
        
        // Evcil Hayvan
        ExpenseSubCategory(name: "Mama ve oyuncaklar", category: .pets),
        ExpenseSubCategory(name: "Veteriner hizmetleri", category: .pets),
        ExpenseSubCategory(name: "Evcil hayvan sigortası", category: .pets),
        
        // İş
        ExpenseSubCategory(name: "İş yemekleri", category: .work),
        ExpenseSubCategory(name: "Ofis malzemeleri", category: .work),
        ExpenseSubCategory(name: "İş seyahatleri", category: .work),
        ExpenseSubCategory(name: "Eğitim ve seminerler", category: .work),
        ExpenseSubCategory(name: "Freelance iş ödemeleri", category: .work),
        
        // Vergi
        ExpenseSubCategory(name: "Vergi ödemeleri", category: .tax),
        ExpenseSubCategory(name: "Avukat ve danışman ücretleri", category: .tax),
        
        // Bağışlar
        ExpenseSubCategory(name: "Hayır kurumları", category: .donations),
        ExpenseSubCategory(name: "Yardımlar ve bağışlar", category: .donations),
        ExpenseSubCategory(name: "Çevre ve toplum projeleri", category: .donations)
    ]
    
    // MARK: - Category Mapping
    static func getCategoryForSubCategory(_ subCategory: String) -> ExpenseCategory {
        let mapping: [String: ExpenseCategory] = [
            // Gıda
            "Restoran": .food, "Market alışverişi": .food, "Kafeler": .food,
            "Fast food": .food, "Evde yemek (malzeme)": .food, "Su ve içecek": .food,
            // Konut
            "Kira": .housing, "Mortgage ödemesi": .housing, "Elektrik faturası": .housing,
            "Su faturası": .housing, "Isınma (doğalgaz, kalorifer)": .housing,
            "İnternet ve telefon": .housing, "Temizlik malzemeleri": .housing,
            // Ulaşım
            "Benzin/Dizel": .transportation, "Toplu taşıma": .transportation,
            "Araç bakımı": .transportation, "Oto kiralama": .transportation,
            "Taksi/Uber": .transportation, "Araç sigortası": .transportation,
            "Park ücretleri": .transportation,
            // Sağlık
            "Doktor randevusu": .health, "İlaçlar": .health, "Spor salonu üyeliği": .health,
            "Cilt bakım ürünleri": .health, "Diş bakımı": .health,
            "Giyim ve aksesuar": .health, "Parfüm": .health,
            // Eğlence
            "Sinema ve tiyatro": .entertainment, "Konser ve etkinlikler": .entertainment,
            "Abonelikler (Netflix, Spotify vb.)": .entertainment,
            "Kitaplar ve dergiler": .entertainment, "Seyahat ve tatil": .entertainment,
            "Oyunlar ve uygulamalar": .entertainment,
            // Eğitim
            "Kurs ücretleri": .education, "Kitaplar": .education,
            "Eğitim materyalleri": .education, "Seminerler": .education,
            "Online kurslar": .education,
            // Alışveriş
            "Elektronik": .shopping, "Giysi": .shopping, "Ayakkabı": .shopping,
            "Ev eşyaları": .shopping, "Hediyeler": .shopping, "Takı ve aksesuar": .shopping,
            // Evcil Hayvan
            "Mama ve oyuncaklar": .pets, "Veteriner hizmetleri": .pets,
            "Evcil hayvan sigortası": .pets,
            // İş
            "İş yemekleri": .work, "Ofis malzemeleri": .work, "İş seyahatleri": .work,
            "Eğitim ve seminerler": .work, "Freelance iş ödemeleri": .work,
            // Vergi
            "Vergi ödemeleri": .tax, "Avukat ve danışman ücretleri": .tax,
            // Bağışlar
            "Hayır kurumları": .donations, "Yardımlar ve bağışlar": .donations,
            "Çevre ve toplum projeleri": .donations
        ]
        
        return mapping[subCategory] ?? .food
    }
    
    // MARK: - Category Colors
    static func getCategoryColor(_ category: ExpenseCategory) -> Color {
        switch category {
        case .food: return .orange
        case .housing: return .blue
        case .transportation: return .green
        case .health: return .pink
        case .entertainment: return .purple
        case .education: return .indigo
        case .shopping: return .red
        case .pets: return .mint
        case .work: return .cyan
        case .tax: return .yellow
        case .donations: return .teal
        }
    }
    
    // MARK: - Category Icons
    static func getCategoryIcon(_ category: ExpenseCategory) -> String {
        switch category {
        case .food: return "fork.knife"
        case .housing: return "house.fill"
        case .transportation: return "car.fill"
        case .health: return "heart.fill"
        case .entertainment: return "gamecontroller.fill"
        case .education: return "book.fill"
        case .shopping: return "bag.fill"
        case .pets: return "pawprint.fill"
        case .work: return "briefcase.fill"
        case .tax: return "doc.text.fill"
        case .donations: return "gift.fill"
        }
    }
}
