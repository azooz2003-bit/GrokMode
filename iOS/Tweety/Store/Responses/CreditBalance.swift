//
//  CreditBalance.swift
//  Tweety
//
//  Created by Abdulaziz Albahar on 12/28/25.
//

import Foundation

nonisolated
struct CreditBalance: Codable {
    let userId: String
    let spent: Double
    let total: Double
    let remaining: Double

    enum CodingKeys: String, CodingKey {
        case userId
        case spent
        case total
        case remaining
    }
}
