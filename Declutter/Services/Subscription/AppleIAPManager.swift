//
//  AppleIAPManager.swift
//  Declutter
//
//  Created for user-auth-subscription feature
//

import Foundation
import StoreKit

class AppleIAPManager {
    private var updateListenerTask: Task<Void, Never>?
    private let backendAPIClient: BackendAPIClient
    
    init(backendAPIClient: BackendAPIClient = .shared) {
        self.backendAPIClient = backendAPIClient
        startTransactionListener()
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    /// Start listening for transaction updates
    func startTransactionListener() {
        updateListenerTask = Task.detached { [weak self] in
            for await result in Transaction.updates {
                await self?.handleTransaction(result)
            }
        }
    }
    
    /// Fetch products from App Store
    func fetchProducts(productIds: [String]) async throws -> [Product] {
        let products = try await Product.products(for: productIds)
        return products
    }
    
    /// Purchase a product
    func purchase(_ product: Product) async throws -> Transaction {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            return transaction
            
        case .userCancelled:
            throw SubscriptionError.userCancelled
            
        case .pending:
            throw SubscriptionError.purchaseFailed(reason: "Purchase pending")
            
        @unknown default:
            throw SubscriptionError.unknownError(NSError(domain: "IAP", code: -1))
        }
    }
    
    /// Verify receipt with backend server
    func verifyReceipt(_ transaction: Transaction) async throws -> SubscriptionVerificationResponse {
        // StoreKit 2 handles Apple-side verification automatically
        // Now we verify with our backend for subscription management
        
        // Get auth token
        guard let authToken = try? SecureStorage.shared.getCredentials()?.authToken.accessToken else {
            throw SubscriptionError.verificationFailed
        }
        
        do {
            let response = try await backendAPIClient.verifyAppleReceipt(transaction, authToken: authToken)
            return response
        } catch {
            print("Backend verification failed: \(error)")
            throw SubscriptionError.verificationFailed
        }
    }
    
    /// Listen for transactions
    func listenForTransactions() -> Task<Void, Never> {
        return Task.detached {
            for await result in Transaction.updates {
                await self.handleTransaction(result)
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func handleTransaction(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else {
            // Handle unverified transaction
            print("Unverified transaction: \(result)")
            return
        }
        
        // Process the verified transaction
        print("Verified transaction: \(transaction.productID)")
        
        // Verify with backend
        do {
            let verificationResponse = try await verifyReceipt(transaction)
            if verificationResponse.success {
                print("Backend verification successful for transaction: \(transaction.id)")
                // Finish the transaction only after backend verification
                await transaction.finish()
            } else {
                print("Backend verification failed: \(verificationResponse.message ?? "Unknown error")")
            }
        } catch {
            print("Failed to verify transaction with backend: \(error)")
            // Still finish the transaction to avoid repeated processing
            await transaction.finish()
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
}
