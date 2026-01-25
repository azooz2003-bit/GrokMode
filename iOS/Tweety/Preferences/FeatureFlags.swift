//
//  FeatureFlags.swift
//  Tweety
//
//  Created by Abdulaziz Albahar on 1/24/26.
//

import Foundation

@Observable
final class FeatureFlags {
    static let shared = FeatureFlags()

    // MARK: - Voice Mode Action Confirmations

    private(set) var confirmationPreferences: [String: Bool] = [:]

    private init() {
        for endpoint in XAPIEndpoint.confirmationSensitiveEndpoints {
            let key = "requireConfirmation_\(endpoint.rawValue)"
            confirmationPreferences[endpoint.rawValue] = UserDefaults.standard.object(forKey: key) as? Bool ?? true
        }
    }

    /// Check if confirmation is required for a specific endpoint
    func shouldRequireConfirmation(for endpoint: XAPIEndpoint) -> Bool {
        guard endpoint.previewBehavior == .requiresConfirmation else {
            return false
        }

        return confirmationPreferences[endpoint.rawValue] ?? true
    }

    /// Set confirmation requirement for a specific endpoint
    func setRequiresConfirmation(_ requires: Bool, for endpoint: XAPIEndpoint) {
        guard endpoint.previewBehavior == .requiresConfirmation else {
            return
        }

        confirmationPreferences[endpoint.rawValue] = requires

        let key = "requireConfirmation_\(endpoint.rawValue)"
        UserDefaults.standard.set(requires, forKey: key)
    }
}
