//
//  UsageTrackResponse.swift
//  Tweety
//
//  Created by Abdulaziz Albahar on 12/28/25.
//

import Foundation

nonisolated
struct UsageTrackResponse: Codable {
    let success: Bool
    let cost: Double
    let spent: Double
    let total: Double
    let remaining: Double
    let exceeded: Bool
}
