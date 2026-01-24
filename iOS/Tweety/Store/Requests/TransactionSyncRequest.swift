//
//  TransactionSyncRequest.swift
//  Tweety
//
//  Created by Abdulaziz Albahar on 12/28/25.
//

import Foundation

nonisolated
struct TransactionSyncRequest: Codable {
    let transactionId: String
    let originalTransactionId: String
    let productId: String
    let purchaseDateMs: String
    let isTrialPeriod: String
    let expirationDateMs: String?
    let revocationDateMs: String?
    let revocationReason: String?
    let ownershipType: String?

    enum CodingKeys: String, CodingKey {
        case transactionId = "transaction_id"
        case originalTransactionId = "original_transaction_id"
        case productId = "product_id"
        case purchaseDateMs = "purchase_date_ms"
        case isTrialPeriod = "is_trial_period"
        case expirationDateMs = "expiration_date_ms"
        case revocationDateMs = "revocation_date_ms"
        case revocationReason = "revocation_reason"
        case ownershipType = "ownership_type"
    }
}
