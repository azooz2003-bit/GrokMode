//
//  VoiceServiceType.swift
//  GrokMode
//
//  Created by Abdulaziz Albahar on 12/18/25.
//

import Foundation

/// Enumeration of available voice service providers
enum VoiceServiceType: String, CaseIterable, Identifiable {
    case xai = "xAI"
    case openai = "OpenAI"

    var id: String { rawValue }

    /// Display name for the service (model name)
    var displayName: String {
        switch self {
        case .xai:
            return "Grok"
        case .openai:
            return "GPT-Realtime"
        }
    }

    /// Assistant name shown to users (same as display name)
    var assistantName: String {
        displayName
    }

    /// Icon name for the service
    var iconName: String {
        switch self {
        case .xai:
            return "Grok" // Uses existing grok image asset
        case .openai:
            return "OpenAI" // SF Symbol for OpenAI
        }
    }

    /// Creates the appropriate voice service instance
    func createService(sessionState: SessionState, appAttestService: AppAttestService, storeManager: StoreKitManager, usageTracker: UsageTracker) -> VoiceService {
        switch self {
        case .xai:
            return XAIVoiceService(sessionState: sessionState, appAttestService: appAttestService, sampleRate: .twentyFourKHz)
        case .openai:
            return OpenAIVoiceService(sessionState: sessionState, appAttestService: appAttestService, storeManager: storeManager, usageTracker: usageTracker, sampleRate: 24000)
        }
    }
}
