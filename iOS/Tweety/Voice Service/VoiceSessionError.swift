//
//  VoiceSessionError.swift
//  Tweety
//
//  Created by Abdulaziz Albahar on 1/17/26.
//

import Foundation

/// Errors that occur during an active voice session
/// These are reported via the onError callback and interrupt an active session
enum VoiceSessionError: LocalizedError {
    case insufficientCredits(balance: Double)
    case usageTrackingFailed(Error)
    case websocketError(Error)

    var errorDescription: String? {
        switch self {
        case .insufficientCredits(let balance):
            return "Insufficient credits ($\(balance))"
        case .usageTrackingFailed(let error):
            return "Usage tracking failed: \(error.localizedDescription)"
        case .websocketError(let error):
            return "WebSocket error: \(error.localizedDescription)"
        }
    }
}
