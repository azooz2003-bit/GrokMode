//
//  VoiceFlowAction+Display.swift
//  Tweety
//
//  Created by Abdulaziz Albahar on 1/16/26.
//

import Foundation

extension VoiceFlowAction {
    /// User-friendly display name for the action, shown in conversation UI
    var displayName: String {
        switch self {
        case .confirmAction: return "Confirm Action"
        case .cancelAction: return "Cancel Action"
        }
    }
}
