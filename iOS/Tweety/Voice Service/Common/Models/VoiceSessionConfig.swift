//
//  VoiceSessionConfig.swift
//  Tweety
//
//  Created by Abdulaziz Albahar on 1/16/26.
//

/// Configuration for initializing a voice session
struct VoiceSessionConfig {
    let instructions: String
    let tools: [VoiceToolDefinition]?
    let sampleRate: Int
}
