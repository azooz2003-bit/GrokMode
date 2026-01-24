//
//  UsageDetails.swift
//  Tweety
//
//  Created by Abdulaziz Albahar on 12/28/25.
//

import Foundation

nonisolated
enum UsageDetails: Codable {
    case openAI(OpenAIUsageDetails)
    case grokVoice(GrokVoiceUsageDetails)
    case xAPI(XAPIUsageDetails)

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .openAI(let details):
            try container.encode(details)
        case .grokVoice(let details):
            try container.encode(details)
        case .xAPI(let details):
            try container.encode(details)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let openAI = try? container.decode(OpenAIUsageDetails.self) {
            self = .openAI(openAI)
        } else if let grokVoice = try? container.decode(GrokVoiceUsageDetails.self) {
            self = .grokVoice(grokVoice)
        } else if let xAPI = try? container.decode(XAPIUsageDetails.self) {
            self = .xAPI(xAPI)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unable to decode UsageDetails"
            )
        }
    }
}
