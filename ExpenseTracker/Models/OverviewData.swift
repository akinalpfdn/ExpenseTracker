//
//  OverviewData.swift
//  ExpenseTracker
//
//  Value types backing the overview screen's three charts.
//

import Foundation

/// How far back the spending trend chart looks. The forecast and cumulative charts
/// are always twelve months and are not affected by this.
enum TrendRange: Int, CaseIterable, Identifiable {
    case threeMonths = 3
    case sixMonths = 6
    case oneYear = 12

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .threeMonths:
            return "range_3_months".localized
        case .sixMonths:
            return "range_6_months".localized
        case .oneYear:
            return "range_1_year".localized
        }
    }
}

/// One bar in either the trend or the forecast chart.
struct MonthlyAmountPoint: Identifiable, Equatable {
    let id = UUID()

    /// First day of the month this point covers. Kept so the axis can label it and
    /// so callers can tell past from future without re-deriving it.
    let month: Date
    let amount: Double

    static func == (lhs: MonthlyAmountPoint, rhs: MonthlyAmountPoint) -> Bool {
        return lhs.month == rhs.month && lhs.amount == rhs.amount
    }
}

/// One point on the cumulative balance line.
struct CumulativeBalancePoint: Identifiable, Equatable {
    let id = UUID()
    let month: Date

    /// Running total of (income − forecast) from the first projected month up to and
    /// including this one.
    let balance: Double

    static func == (lhs: CumulativeBalancePoint, rhs: CumulativeBalancePoint) -> Bool {
        return lhs.month == rhs.month && lhs.balance == rhs.balance
    }
}
