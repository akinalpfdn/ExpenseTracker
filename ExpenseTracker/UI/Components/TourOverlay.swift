//
//  TourOverlay.swift
//  ExpenseTracker
//
//  The spotlight. Everything on screen dims except the one control the current step
//  is about; a callout sits beside it with an arrow pointing at it.
//
//  The two kinds of step look different because they are different:
//
//  - An information step blocks every touch. The only controls are in the callout.
//  - An action step lets touches through the spotlight and nowhere else, has no Next
//    button, and pulses the spotlight so there is no doubt about what to tap.
//
//  Rendered once, at the root, via `overlayPreferenceValue`. It is never placed
//  inside a sheet; while a sheet is up the tour is suspended and draws nothing.
//

import SwiftUI

// MARK: - Host

/// Resolves the current step's target and hands the overlay concrete geometry.
struct TourOverlayHost: View {
    @ObservedObject var tour: TourController
    let targets: [TourStepID: TourTargetInfo]
    let isDarkTheme: Bool

    var body: some View {
        GeometryReader { proxy in
            if let step = tour.current, !tour.isSuspended {
                let cutout = resolveCutout(for: step, in: proxy)

                TourOverlay(
                    tour: tour,
                    step: step,
                    cutout: cutout,
                    screen: proxy.size,
                    isDarkTheme: isDarkTheme
                )
                // A spotlight that glides between targets reads as one thing moving;
                // one that jumps reads as the screen glitching.
                .animation(.easeInOut(duration: 0.3), value: cutout?.rect)
            }
        }
        .ignoresSafeArea()
    }

    /// Nil when the target is not on screen — mid tab-swipe, or a chart that has not
    /// rendered because there is no data yet. The overlay then dims everything and
    /// centres the callout instead of drawing a hole around nothing.
    private func resolveCutout(for step: TourStep, in proxy: GeometryProxy) -> TourCutout? {
        guard let target = targets[step.id] else { return nil }

        let rect = proxy[target.bounds].insetBy(dx: -8, dy: -8)
        let screen = CGRect(origin: .zero, size: proxy.size)

        guard rect.width > 0, rect.height > 0, screen.intersects(rect) else { return nil }

        return TourCutout(rect: rect, cornerRadius: target.shape.cornerRadius(for: rect))
    }
}

struct TourCutout: Equatable {
    let rect: CGRect
    let cornerRadius: CGFloat
}

// MARK: - Overlay

struct TourOverlay: View {
    @ObservedObject var tour: TourController
    let step: TourStep
    let cutout: TourCutout?
    let screen: CGSize
    let isDarkTheme: Bool

    @State private var calloutSize: CGSize = .zero

    var body: some View {
        ZStack {
            dim
            if step.requiresAction, let cutout = cutout {
                pulse(around: cutout)
            }
            callout
        }
    }
}

// MARK: - Dim Layer

private extension TourOverlay {

    /// One shape does both jobs. Filled even-odd, it paints everything except the
    /// hole. As the hit-test shape, even-odd only for action steps, so the hole lets
    /// touches through to the real control and the rest of the screen absorbs them.
    var dim: some View {
        SpotlightShape(cutout: cutout)
            .fill(Color.black.opacity(0.72), style: FillStyle(eoFill: true))
            .contentShape(.interaction, SpotlightShape(cutout: cutout), eoFill: step.requiresAction)
            .onTapGesture { }
    }

    func pulse(around cutout: TourCutout) -> some View {
        SpotlightPulse(cutout: cutout)
            .id(step.id)
    }
}

/// Full screen minus a rounded hole. With `eoFill` the hole is empty; without it the
/// two paths wind the same way and the shape covers everything.
struct SpotlightShape: Shape {
    let cutout: TourCutout?

    func path(in rect: CGRect) -> Path {
        var path = Path(rect)
        if let cutout = cutout {
            path.addPath(Path(roundedRect: cutout.rect, cornerRadius: cutout.cornerRadius))
        }
        return path
    }
}

/// A ring that expands and fades from the spotlight's edge. Exists only while an
/// action step is showing, so the repeating animation lives and dies with it — no
/// animated shadow, no state left running after the step moves on.
private struct SpotlightPulse: View {
    let cutout: TourCutout

    @State private var expanded = false

    var body: some View {
        RoundedRectangle(cornerRadius: cutout.cornerRadius)
            .stroke(AppColors.primaryOrange, lineWidth: 3)
            .frame(width: cutout.rect.width, height: cutout.rect.height)
            .position(x: cutout.rect.midX, y: cutout.rect.midY)
            .scaleEffect(expanded ? 1.18 : 1.0)
            .opacity(expanded ? 0 : 0.9)
            .onAppear {
                withAnimation(.easeOut(duration: 1.3).repeatForever(autoreverses: false)) {
                    expanded = true
                }
            }
    }
}

// MARK: - Callout

private extension TourOverlay {

    var placement: CalloutPlacement {
        CalloutPlacement(cutout: cutout, calloutSize: calloutSize, screen: screen)
    }

    var callout: some View {
        VStack(spacing: 0) {
            if placement.arrowSide == .top { arrow(pointingUp: true) }
            card
            if placement.arrowSide == .bottom { arrow(pointingUp: false) }
        }
        .frame(width: placement.width)
        .background(sizeReader)
        .position(placement.center)
    }

    var sizeReader: some View {
        GeometryReader { proxy in
            Color.clear.preference(key: CalloutSizeKey.self, value: proxy.size)
        }
        .onPreferenceChange(CalloutSizeKey.self) { calloutSize = $0 }
    }

    func arrow(pointingUp: Bool) -> some View {
        CalloutArrow(pointingUp: pointingUp)
            .fill(ThemeColors.getDialogBackgroundColor(isDarkTheme: isDarkTheme))
            .frame(width: 18, height: 9)
            .offset(x: placement.arrowOffset)
    }

    var card: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(step.title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

                Spacer(minLength: 12)

                Text("\(tour.stepNumber)/\(tour.totalSteps)")
                    .font(.system(size: 12, weight: .medium))
                    .monospacedDigit()
                    .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
            }

            Text(step.message)
                .font(.system(size: 14))
                .lineSpacing(3)
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                .fixedSize(horizontal: false, vertical: true)

            controls
                .padding(.top, 4)
        }
        .padding(18)
        .background(ThemeColors.getDialogBackgroundColor(isDarkTheme: isDarkTheme))
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.35), radius: 16, y: 6)
    }

    @ViewBuilder
    var controls: some View {
        if step.requiresAction {
            HStack {
                Label("tour_tap_hint".localized, systemImage: "hand.tap.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.primaryOrange)

                Spacer()

                secondaryButton("tour_skip_step".localized) { tour.skipStep() }
            }
        } else {
            HStack(spacing: 14) {
                secondaryButton("tour_skip".localized) { tour.skipTour() }

                Spacer()

                if tour.canGoBack {
                    secondaryButton("tour_back".localized) { tour.back() }
                }

                primaryButton(tour.isLastStep ? "tour_done".localized : "tour_next".localized) {
                    tour.next()
                }
            }
        }
    }

    func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.textWhite)
                .padding(.horizontal, 16)
                .frame(height: 34)
                .background(AppColors.primaryOrange)
                .cornerRadius(10)
        }
    }

    func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
        }
    }
}

private struct CalloutSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) { value = nextValue() }
}

// MARK: - Placement

/// Where the callout goes relative to the spotlight: below it when there is room,
/// above it otherwise, centred when there is no spotlight at all.
struct CalloutPlacement {
    enum ArrowSide { case top, bottom, none }

    let width: CGFloat
    let center: CGPoint
    let arrowSide: ArrowSide

    /// Horizontal nudge so the arrow tip lines up with the target even when the card
    /// has been pushed sideways to stay on screen.
    let arrowOffset: CGFloat

    private static let margin: CGFloat = 16
    private static let gap: CGFloat = 12

    init(cutout: TourCutout?, calloutSize: CGSize, screen: CGSize) {
        let width = min(screen.width - Self.margin * 2, 360)
        self.width = width

        guard let cutout = cutout, calloutSize.height > 0 else {
            center = CGPoint(x: screen.width / 2, y: screen.height / 2)
            arrowSide = .none
            arrowOffset = 0
            return
        }

        // Horizontal: centre on the target, then keep the whole card on screen.
        let minX = Self.margin + width / 2
        let maxX = screen.width - Self.margin - width / 2
        let x = min(max(cutout.rect.midX, minX), maxX)

        // Vertical: below if it fits, else above. A target near the middle of the
        // screen fits either way and goes below, which reads as the natural next line.
        let neededBelow = cutout.rect.maxY + Self.gap + calloutSize.height + Self.margin
        let fitsBelow = neededBelow <= screen.height

        if fitsBelow {
            center = CGPoint(x: x, y: cutout.rect.maxY + Self.gap + calloutSize.height / 2)
            arrowSide = .top
        } else {
            center = CGPoint(x: x, y: cutout.rect.minY - Self.gap - calloutSize.height / 2)
            arrowSide = .bottom
        }

        // Arrow tracks the target's centre but stays clear of the card's corners.
        let inset = 28.0
        let rawOffset = cutout.rect.midX - x
        arrowOffset = min(max(rawOffset, -width / 2 + inset), width / 2 - inset)
    }
}

/// The little triangle between the card and the target.
private struct CalloutArrow: Shape {
    let pointingUp: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        if pointingUp {
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        } else {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        }
        path.closeSubpath()
        return path
    }
}
