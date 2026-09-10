//
//  TourTarget.swift
//  ExpenseTracker
//
//  How a view says "the tour can point at me".
//
//  A target reports its bounds upward as an anchor preference. The overlay at the
//  root resolves the anchor for whichever step is showing and cuts the spotlight
//  there. Views know nothing about the tour beyond this one modifier; the tour knows
//  nothing about the views beyond the id they registered.
//

import SwiftUI

/// The outline the spotlight follows.
enum TourTargetShape: Equatable {
    case rounded(CGFloat)
    case circle

    static let card = TourTargetShape.rounded(16)

    func cornerRadius(for rect: CGRect) -> CGFloat {
        switch self {
        case .rounded(let radius): return radius
        case .circle: return min(rect.width, rect.height) / 2
        }
    }
}

struct TourTargetInfo: Equatable {
    let bounds: Anchor<CGRect>
    let shape: TourTargetShape
}

struct TourTargetsKey: PreferenceKey {
    static var defaultValue: [TourStepID: TourTargetInfo] = [:]

    static func reduce(value: inout [TourStepID: TourTargetInfo], nextValue: () -> [TourStepID: TourTargetInfo]) {
        value.merge(nextValue()) { $1 }
    }
}

extension View {
    /// Registers this view as the thing step `id` points at.
    func tourTarget(_ id: TourStepID, shape: TourTargetShape = .card) -> some View {
        anchorPreference(key: TourTargetsKey.self, value: .bounds) { anchor in
            [id: TourTargetInfo(bounds: anchor, shape: shape)]
        }
    }
}
