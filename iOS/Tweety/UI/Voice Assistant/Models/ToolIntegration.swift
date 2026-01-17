//
//  ToolIntegration.swift
//  Tweety
//
//  Created by Matt Steele on 12/7/25.
//

import Foundation
import JSONSchema

struct ToolIntegration {
    static func getToolDefinitions() -> [VoiceToolDefinition] {
        // Combine API endpoints and flow control actions
        XAPIToolIntegration.getToolDefinitions() + VoiceFlowToolIntegration.getToolDefinitions()
    }
}
