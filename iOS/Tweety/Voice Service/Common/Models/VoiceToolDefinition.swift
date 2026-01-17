//
//  VoiceToolDefinition.swift
//  Tweety
//
//  Created by Abdulaziz Albahar on 1/16/26.
//

/// Tool definition for voice session
struct VoiceToolDefinition {
    let type: String
    let name: String
    let description: String
    let parameters: [String: Any]

    init(type: String, name: String, description: String, parameters: [String: Any]) {
        self.type = type
        self.name = name
        self.description = description
        self.parameters = parameters
    }
}
