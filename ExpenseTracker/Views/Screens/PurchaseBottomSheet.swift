//
//  PurchaseBottomSheet.swift
//  ExpenseTracker
//
//  Created by migration from Android PurchaseBottomSheet.kt
//

import SwiftUI

struct PurchaseOption: Identifiable {
    let id = UUID()
    let title: String
    let price: String
    let icon: String  // SF Symbol name
    let productId: String
}

struct PurchaseBottomSheet: View {
    let isDarkTheme: Bool
    let onDismiss: () -> Void

    @StateObject private var storeManager = StoreManager()
    @State private var displayText = ""
    @State private var isAnimationComplete = false
    @State private var pressedCardId: UUID?
    @State private var animationTask: Task<Void, Never>?
    @State private var showPurchaseAlert = false
    @State private var purchaseAlertMessage = ""

    private let fullText = "no_add_text".localized

    private let purchaseOptions = [
        PurchaseOption(
            title: "buy_water".localized,
            price: "water_price".localized,
            icon: "drop.fill",
            productId: "su_donation"
        ),
        PurchaseOption(
            title: "buy_tea".localized,
            price: "tea_price".localized,
            icon: "cup.and.saucer.fill",
            productId: "tea_donation"
        ),
        PurchaseOption(
            title: "buy_bagel".localized,
            price: "bagel_price".localized,
            icon: "circle.fill",  // placeholder
            productId: "bagel_donation"
        ),
        PurchaseOption(
            title: "buy_coffee".localized,
            price: "coffee_price".localized,
            icon: "cup.and.saucer.fill",
            productId: "coffee_donation"
        ),
        PurchaseOption(
            title: "buy_wrap".localized,
            price: "wrap_price".localized,
            icon: "takeoutbag.and.cup.and.straw.fill",
            productId: "wrap_donation"
        ),
        PurchaseOption(
            title: "buy_burger".localized,
            price: "burger_price".localized,
            icon: "fork.knife",
            productId: "burger_donation"
        ),
        PurchaseOption(
            title: "buy_doner".localized,
            price: "doner_price".localized,
            icon: "takeoutbag.and.cup.and.straw.fill",
            productId: "doner_donation"
        ),
        PurchaseOption(
            title: "max_donation".localized,
            price: "max_price".localized,
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
                purchaseOptionsGrid
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

    private var purchaseOptionsGrid: some View {
        VStack(spacing: 12) {
            // First row (2 cards)
            HStack(spacing: 12) {
                PurchaseOptionCard(
                    option: purchaseOptions[0],
                    isDarkTheme: isDarkTheme,
                    isPressed: pressedCardId == purchaseOptions[0].id,
                    onTap: { handlePurchase(purchaseOptions[0]) }
                )
                PurchaseOptionCard(
                    option: purchaseOptions[1],
                    isDarkTheme: isDarkTheme,
                    isPressed: pressedCardId == purchaseOptions[1].id,
                    onTap: { handlePurchase(purchaseOptions[1]) }
                )
            }

            // Second row (2 cards)
            HStack(spacing: 12) {
                PurchaseOptionCard(
                    option: purchaseOptions[2],
                    isDarkTheme: isDarkTheme,
                    isPressed: pressedCardId == purchaseOptions[2].id,
                    onTap: { handlePurchase(purchaseOptions[2]) }
                )
                PurchaseOptionCard(
                    option: purchaseOptions[3],
                    isDarkTheme: isDarkTheme,
                    isPressed: pressedCardId == purchaseOptions[3].id,
                    onTap: { handlePurchase(purchaseOptions[3]) }
                )
            }

            // Third row (2 cards)
            HStack(spacing: 12) {
                PurchaseOptionCard(
                    option: purchaseOptions[4],
                    isDarkTheme: isDarkTheme,
                    isPressed: pressedCardId == purchaseOptions[4].id,
                    onTap: { handlePurchase(purchaseOptions[4]) }
                )
                PurchaseOptionCard(
                    option: purchaseOptions[5],
                    isDarkTheme: isDarkTheme,
                    isPressed: pressedCardId == purchaseOptions[5].id,
                    onTap: { handlePurchase(purchaseOptions[5]) }
                )
            }

            // Fourth row (2 cards)
            HStack(spacing: 12) {
                PurchaseOptionCard(
                    option: purchaseOptions[6],
                    isDarkTheme: isDarkTheme,
                    isPressed: pressedCardId == purchaseOptions[6].id,
                    onTap: { handlePurchase(purchaseOptions[6]) }
                )
                PurchaseOptionCard(
                    option: purchaseOptions[7],
                    isDarkTheme: isDarkTheme,
                    isPressed: pressedCardId == purchaseOptions[7].id,
                    onTap: { handlePurchase(purchaseOptions[7]) }
                )
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
                try? await Task.sleep(nanoseconds: 50_000_000) // 30ms per character
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

                // Price
                Text(option.price)
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

// MARK: - Preview
struct PurchaseBottomSheet_Previews: PreviewProvider {
    static var previews: some View {
        PurchaseBottomSheet(
            isDarkTheme: true,
            onDismiss: {}
        )
    }
}
