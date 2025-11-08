//
//  PurchaseBottomSheet.swift
//  ExpenseTracker
//
//  StoreKit 2 integration for in-app donations
//  Prices are fetched directly from App Store Connect
//

import SwiftUI
import StoreKit

struct PurchaseOption: Identifiable {
    var id: String { productId }
    let title: String
    let icon: String
    let productId: String
}

struct PurchaseBottomSheet: View {
    let isDarkTheme: Bool
    let onDismiss: () -> Void

    @StateObject private var storeManager = StoreManager()
    @State private var displayText = ""
    @State private var isAnimationComplete = false
    @State private var pressedCardId: String?
    @State private var animationTask: Task<Void, Never>?
    @State private var showPurchaseAlert = false
    @State private var purchaseAlertMessage = ""

    private let fullText = "no_add_text".localized

    // Product metadata (titles and icons) - prices come from StoreKit
    private let purchaseOptionsMetadata = [
        PurchaseOption(
            title: "buy_water".localized,
            icon: "drop.fill",
            productId: "su_donation"
        ),
        PurchaseOption(
            title: "buy_tea".localized,
            icon: "cup.and.saucer.fill",
            productId: "tea_donation"
        ),
        PurchaseOption(
            title: "buy_bagel".localized,
            icon: "circle.fill",
            productId: "bagel_donation"
        ),
        PurchaseOption(
            title: "buy_coffee".localized,
            icon: "cup.and.saucer.fill",
            productId: "coffee_donation"
        ),
        PurchaseOption(
            title: "buy_wrap".localized,
            icon: "takeoutbag.and.cup.and.straw.fill",
            productId: "wrap_donation"
        ),
        PurchaseOption(
            title: "buy_burger".localized,
            icon: "fork.knife",
            productId: "burger_donation"
        ),
        PurchaseOption(
            title: "buy_doner".localized,
            icon: "takeoutbag.and.cup.and.straw.fill",
            productId: "doner_donation"
        ),
        PurchaseOption(
            title: "max_donation".localized,
            icon: "star.fill",
            productId: "max_donation"
        )
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Typewriter text
                typewriterText

                // Purchase options grid
                if !storeManager.products.isEmpty {
                    purchaseOptionsGrid
                } else {
                    loadingView
                }
            }
            .padding(24)
        }
        .background(ThemeColors.getBackgroundColor(isDarkTheme: isDarkTheme))
        .overlay {
            if case .loading = storeManager.purchaseState {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)

                        Text("purchase_loading".localized)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(32)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(ThemeColors.getCardBackgroundColor(isDarkTheme: isDarkTheme))
                    )
                }
            }
        }
        .alert(isPresented: $showPurchaseAlert) {
            Alert(
                title: Text(getPurchaseAlertTitle()),
                message: Text(purchaseAlertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onChange(of: storeManager.purchaseState) { newState in
            switch newState {
            case .success(let productId):
                purchaseAlertMessage = String(format: "purchase_success".localized, productId)
                showPurchaseAlert = true
            case .failed(let error):
                purchaseAlertMessage = String(format: "purchase_error".localized, error)
                showPurchaseAlert = true
            case .cancelled:
                purchaseAlertMessage = "purchase_cancelled".localized
                showPurchaseAlert = true
            default:
                break
            }
        }
        .onAppear {
            startTypewriterAnimation()
        }
        .onDisappear {
            animationTask?.cancel()
        }
    }

    private func getPurchaseAlertTitle() -> String {
        switch storeManager.purchaseState {
        case .success:
            return "🎉"
        case .failed:
            return "⚠️"
        case .cancelled:
            return "❌"
        default:
            return ""
        }
    }

    private var typewriterText: some View {
        Text(displayText + ((!isAnimationComplete && !displayText.isEmpty) ? "|" : ""))
            .font(.system(size: 14))
            .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryOrange))
            Text("loading_products".localized)
                .font(.system(size: 14))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
            Spacer()
        }
        .padding(40)
    }

    private var purchaseOptionsGrid: some View {
        VStack(spacing: 12) {
            // Create rows of 2 cards each
            ForEach(0..<4, id: \.self) { rowIndex in
                HStack(spacing: 12) {
                    ForEach(0..<2, id: \.self) { columnIndex in
                        let index = rowIndex * 2 + columnIndex
                        if index < purchaseOptionsMetadata.count {
                            let option = purchaseOptionsMetadata[index]
                            if let product = storeManager.products.first(where: { $0.id == option.productId }) {
                                PurchaseOptionCard(
                                    option: option,
                                    product: product,
                                    isDarkTheme: isDarkTheme,
                                    isPressed: pressedCardId == option.id,
                                    onTap: { handlePurchase(option) }
                                )
                            } else {
                                // Fallback if product not found
                                EmptyCardPlaceholder()
                            }
                        }
                    }
                }
            }
        }
    }

    private func startTypewriterAnimation() {
        displayText = ""
        isAnimationComplete = false

        animationTask?.cancel()

        animationTask = Task {
            for character in fullText {
                if Task.isCancelled { return }

                displayText.append(character)

                // Use Task.sleep for smooth animation
                try? await Task.sleep(nanoseconds: 50_000_000) // 50ms per character
            }

            if !Task.isCancelled {
                isAnimationComplete = true
            }
        }
    }

    private func handlePurchase(_ option: PurchaseOption) {
        pressedCardId = option.id

        Task {
            await storeManager.purchase(productId: option.productId)

            await MainActor.run {
                pressedCardId = nil
            }
        }
    }
}

struct PurchaseOptionCard: View {
    let option: PurchaseOption
    let product: Product
    let isDarkTheme: Bool
    let isPressed: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Icon background
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.primaryOrange.opacity(0.1))
                        .frame(width: 40, height: 40)

                    Image(systemName: option.icon)
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.primaryOrange)
                }

                // Title
                Text(option.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                // Price from StoreKit
                Text(product.displayPrice)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.primaryOrange)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(Color.clear)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isPressed ? AppColors.primaryOrange : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmptyCardPlaceholder: View {
    var body: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryOrange))
        }
        .frame(maxWidth: .infinity)
        .padding(12)
    }
}

// MARK: - Preview
struct PurchaseBottomSheet_Previews: PreviewProvider {
    static var previews: some View {
        PurchaseBottomSheet(
            isDarkTheme: true,
            onDismiss: {}
        )
    }
}
