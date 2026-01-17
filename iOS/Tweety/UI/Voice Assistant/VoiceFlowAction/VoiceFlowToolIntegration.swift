//
//  VoiceFlowToolIntegration.swift
//  Tweety
//
//  Created by Abdulaziz Albahar on 1/16/26.
//

import Foundation
import JSONSchema

struct VoiceFlowToolIntegration {

    static var actions: [VoiceFlowAction] {
        VoiceFlowAction.allCases
    }

    static func getToolDefinitions() -> [VoiceToolDefinition] {
        actions.map { action in
            let parametersDict: [String: Any]
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(action.jsonSchema)
                if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    parametersDict = dict
                } else {
                    parametersDict = ["type": "object", "properties": [:]]
                }
            } catch {
                parametersDict = ["type": "object", "properties": [:]]
            }

            return VoiceToolDefinition(
                type: "function",
                name: action.rawValue,
                description: action.description,
                parameters: parametersDict
            )
        }
    }
}
