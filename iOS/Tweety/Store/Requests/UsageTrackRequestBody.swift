//
//  UsageTrackRequestBody.swift
//  Tweety
//
//  Created by Abdulaziz Albahar on 12/28/25.
//

import Foundation

nonisolated
struct UsageTrackRequestBody: Codable {
    let service: String
    let usage: UsageDetails
}
