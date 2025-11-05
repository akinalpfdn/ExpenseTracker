//
//  StoreManager.swift
//  ExpenseTracker
//
//  StoreKit 2 manager for handling in-app purchases
//

import Foundation
import StoreKit

@MainActor
class StoreManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchaseState: PurchaseState = .idle

    // Product IDs matching Android version
    private let productIds: [String] = [
        "su_donation",
        "tea_donation",
        "bagel_donation",
        "coffee_donation",
        "wrap_donation",
        "burger_donation",
        "doner_donation",
        "max_donation"
    ]

    private var updateListenerTask: Task<Void, Error>?

    enum PurchaseState: Equatable {
        case idle
        case loading
        case success(productId: String)
        case failed(error: String)
        case cancelled
    }

    init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()

        Task {
            await loadProducts()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // Load products from App Store
    func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: productIds)
            products = storeProducts.sorted { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    // Purchase a product
    func purchase(_ product: Product) async {
        purchaseState = .loading

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // Check verification
                let transaction = try StoreManager.checkVerified(verification)

                // Deliver content
                await transaction.finish()

                purchaseState = .success(productId: product.id)

                // Auto-reset after 3 seconds
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                purchaseState = .idle

            case .userCancelled:
                purchaseState = .cancelled

                // Auto-reset after 3 seconds
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                purchaseState = .idle

            case .pending:
                purchaseState = .loading

            @unknown default:
                purchaseState = .failed(error: "Unknown purchase state")

                // Auto-reset after 3 seconds
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed(error: error.localizedDescription)

            // Auto-reset after 3 seconds
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            purchaseState = .idle
        }
    }

    // Purchase by product ID (for convenience)
    func purchase(productId: String) async {
        guard let product = products.first(where: { $0.id == productId }) else {
            purchaseState = .failed(error: "Product not found")

            // Auto-reset after 3 seconds
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            purchaseState = .idle
            return
        }

        await purchase(product)
    }

    // Listen for transaction updates
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await StoreManager.checkVerified(result)
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }

    // Verify transaction (static to avoid @MainActor issues)
    private static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
