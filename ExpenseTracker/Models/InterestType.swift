//
//  InterestType.swift
//  ExpenseTracker
//
//  Created by migration from Android InterestType.kt
//

import Foundation

enum InterestType: String, Codable {
    case simple = "SIMPLE"    // Simple interest: P * r * t
    case compound = "COMPOUND"   // Compound interest: P * (1 + r)^t - P
}