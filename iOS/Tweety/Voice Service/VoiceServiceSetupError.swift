//
//  VoiceServiceSetupError.swift
//  Tweety
//
//  Created by Abdulaziz Albahar on 1/17/26.
//

import Foundation

/// Errors that occur during voice service setup (connect/configure)
/// These are thrown from setup methods and prevent the session from starting
enum VoiceServiceSetupError: LocalizedError {
    case configurationFailed
    case notConnected

    var errorDescription: String? {
        switch self {
        case .configurationFailed:
            return "Failed to configure voice service"
        case .notConnected:
            return "Voice service is not connected"
        }
    }
}
