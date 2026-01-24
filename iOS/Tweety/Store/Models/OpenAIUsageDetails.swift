//
//  OpenAIUsageDetails.swift
//  Tweety
//
//  Created by Abdulaziz Albahar on 12/28/25.
//

import Foundation

nonisolated
struct OpenAIUsageDetails: Codable {
    let audioInputTokens: Int
    let audioOutputTokens: Int
    let textInputTokens: Int
    let textOutputTokens: Int
    let cachedTextInputTokens: Int
}
