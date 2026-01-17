//
//  VoiceToolOutput.swift
//  Tweety
//
//  Created by Abdulaziz Albahar on 1/16/26.
//

import Foundation

/// Result of sending a tool output
struct VoiceToolOutput {
    let toolCallId: String
    let output: String
    let success: Bool
    let previousItemId: String?
}
