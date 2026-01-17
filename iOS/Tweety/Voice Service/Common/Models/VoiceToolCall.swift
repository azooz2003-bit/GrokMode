//
//  VoiceToolCall.swift
//  Tweety
//
//  Created by Abdulaziz Albahar on 1/16/26.
//

import Foundation

/// Represents a tool call from the assistant
struct VoiceToolCall {
    let id: String
    let name: String
    let arguments: String
    let itemId: String?
}
