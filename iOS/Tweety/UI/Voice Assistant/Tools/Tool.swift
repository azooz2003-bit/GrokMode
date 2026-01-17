//
//  Tool.swift
//  Tweety
//
//  Created by Abdulaziz Albahar on 1/16/26.
//

import Foundation

/// Unified routing enum for all tool types (API endpoints and flow control actions)
enum Tool {
    case apiEndpoint(XAPIEndpoint)
    case flowAction(VoiceFlowAction)

    /// Initialize from a raw string value (tool name)
    init?(rawValue: String) {
        if let endpoint = XAPIEndpoint(rawValue: rawValue) {
            self = .apiEndpoint(endpoint)
        } else if let action = VoiceFlowAction(rawValue: rawValue) {
            self = .flowAction(action)
        } else {
            return nil
        }
    }

    /// The raw string value (tool name)
    var rawValue: String {
        switch self {
        case .apiEndpoint(let endpoint): return endpoint.rawValue
        case .flowAction(let action): return action.rawValue
        }
    }

    /// Human-readable display name
    var displayName: String {
        switch self {
        case .apiEndpoint(let endpoint): return endpoint.displayName
        case .flowAction(let action): return action.displayName
        }
    }
}
