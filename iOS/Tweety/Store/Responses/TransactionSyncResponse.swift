//
//  TransactionSyncResponse.swift
//  Tweety
//
//  Created by Abdulaziz Albahar on 12/28/25.
//

import Foundation

nonisolated
struct TransactionSyncResponse: Codable {
    let success: Bool
    let userId: String
    let processedCount: Int
    let skippedCount: Int
    let newCreditsAdded: Double
    let spent: Double
    let total: Double
    let remaining: Double

    enum CodingKeys: String, CodingKey {
        case success
        case userId
        case processedCount
        case skippedCount
        case newCreditsAdded
        case spent
        case total
        case remaining
    }
}
