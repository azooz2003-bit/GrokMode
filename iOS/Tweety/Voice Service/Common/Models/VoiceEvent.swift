//
//  VoiceEvent.swift
//  Tweety
//
//  Created by Abdulaziz Albahar on 1/16/26.
//

import Foundation

/// Events that can be received from a voice service
enum VoiceEvent {
    case sessionCreated
    case sessionConfigured
    case userSpeechStarted
    case userSpeechStopped
    case assistantSpeaking(itemId: String?)
    case audioDelta(data: Data)
    case toolCall(VoiceToolCall)
    case error(String)
    case other // For events we don't specifically handle
}
