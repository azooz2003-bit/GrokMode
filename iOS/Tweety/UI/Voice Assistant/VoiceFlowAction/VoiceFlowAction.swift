//
//  VoiceFlowAction.swift
//  Tweety
//
//  Created by Abdulaziz Albahar on 1/16/26.
//

import Foundation
import JSONSchema
internal import OrderedCollections

nonisolated
enum VoiceFlowAction: String, CaseIterable, Identifiable {
    // MARK: - Voice Confirmation
    case confirmAction = "confirm_action"
    case cancelAction = "cancel_action"

    var id: String { rawValue }
    var name: String { rawValue }

    var description: String {
        switch self {
        case .confirmAction: return "Confirms and executes the pending action when the user says 'yes', 'confirm', 'do it', or similar affirmations"
        case .cancelAction: return "Cancels the pending action when the user says 'no', 'cancel', 'don't', or similar rejections"
        }
    }

    var jsonSchema: JSONSchema {
        switch self {
        case .confirmAction:
            return .object(
                properties: [
                    "tool_call_id": .string(description: "The ID of the original tool call that is being confirmed")
                ],
                required: ["tool_call_id"]
            )

        case .cancelAction:
            return .object(
                properties: [
                    "tool_call_id": .string(description: "The ID of the original tool call that is being cancelled")
                ],
                required: ["tool_call_id"]
            )
        }
    }

    static func getActionByName(_ name: String) -> VoiceFlowAction? {
        return VoiceFlowAction.allCases.first { $0.name == name }
    }
}
