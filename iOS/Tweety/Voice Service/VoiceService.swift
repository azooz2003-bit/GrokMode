//
//  VoiceService.swift
//  Tweety
//
//  Created by Abdulaziz Albahar on 12/18/25.
//

import Foundation
internal import os

/// Protocol defining the interface for voice service implementations
protocol VoiceService: AnyObject, URLSessionWebSocketDelegate {
    // Service-specific sample rate requirement
    var requiredSampleRate: Int { get }

    // Callbacks - use abstracted VoiceEvent instead of service-specific types
    var onConnected: (() -> Void)? { get set }
    var onDisconnected: ((URLSessionWebSocketTask.CloseCode) -> Void)? { get set }
    var onEvent: ((VoiceEvent) -> Void)? { get set }
    var onError: ((VoiceSessionError) -> Void)? { get set }

    // Connection management
    func connect() async throws
    func disconnect()

    // Session configuration - use abstracted types
    func configureSession(config: VoiceSessionConfig, tools: [VoiceToolDefinition]?) throws

    // Audio streaming
    func sendAudioChunk(_ audioData: Data) throws
    func commitAudioBuffer() throws
    func createResponse() throws

    // Tool handling - use abstracted types
    func sendToolOutput(_ output: VoiceToolOutput) throws

    // Response control
    func truncateResponse() throws
}
