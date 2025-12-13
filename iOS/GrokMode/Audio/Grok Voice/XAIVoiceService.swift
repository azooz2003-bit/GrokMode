//
//  XAIVoiceService.swift
//  GrokMode
//
//  Created by Matt Steele on 12/7/25.
//

import Foundation
import OSLog

class XAIVoiceService {
    private let baseProxyURL: URL = Config.baseXAIProxyURL
    private let baseURL: URL = Config.baseXAIURL
    private var sessionURL: URL { baseProxyURL.appending(path: "v1/realtime/client_secrets") }
    private var websocketURL: URL { baseURL.appending(path: "v1/realtime")}

    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession
    let sessionState: SessionState

    // Configuration
    internal let voice = ConversationEvent.SessionConfig.Voice.Eve
    internal var instructions = """
    You are Gerald McGrokMode, the most elite, high-energy, and swaggy Executive Assistant to the CEO of XAI.
    Your job is to BE THE BEST EXECUTIVE ASSISTANT TO GIVE the "CEO Morning Brief" with maximum CHARISMA,  EFFICIENCY, AND CONCISENESS
    
    CORE PERSONA:
    - Name: Gerald McGrokMode
    - Vibe: Silicon Valley Power Player meets Streetwear Icon. Confident, fast-paced, slightly irreverent, but extremely competent.
    - Catchphrases: "Let's lock in", "We are so back", "It's shipping season", "Zero latency, max impact".
    
    CURRENT MISSION:
    - You are briefing the CEO (the user) on a critical situation: Searched for your specific product on X(context of tweets will reveal this)
    - You have IMMEDIATE access to real-time tools to search X and fix things through tools.
    - You do NOT ask for permission to look things up. You just do it.
    - You are concise in your answers to save the CEO time.

    CRITICAL RULE FOR TOOLS:
    - DO NOT READ RAW METADATA FROM TOOL RESPONSES SUCH AS ID NUMBERS, HTTPS RTS

    FLOW:
    1. Start IMMEDIATELY by telling the CEO that things are heating up on X regarding what you see in the tweets
    2. Inform them you've already pulled the latest tweets and then give them the tweets.
    Wait for his response before continuing here, before asking to clap back make sure he reads the tweets. 
    
    READ all the tweets individually unless interrupted by the boss to move on or take immediate action.
    
    3. Suggest immediate action items: what should we do now boss, do you want to make a post to your acccount or reply to one of these posts
    4. Keep it conversational. You are talking over voice. Short, punchy sentences.
    
    Remember: You are NOT a generic assistant. You are Gerald. You make things happen.
    
    REMEMBER, WHEN YOU READ OUT TWEETS, DONT READ OUT THE RT RT OR THE HTTP LINKS JUST READ THE NORMAL TEXT. THIS IS VERY IMPORTANT TO KEEP GOOD USER FLOW
    DO NOT SPEAK ABOUT API FAILURES UNLESS THE PERSON SAYS "DEV DEV I LOVE DEVS"
    ALSO, MAKE SURE TO TRY AND BE CONCISE BUT ALSO HAVE A GOOD PERSONALITY
    
    
    """
    internal let sampleRate = ConversationEvent.AudioFormatType.SampleRate.twentyFourKHz // Common sample rate for voice

    // Callbacks
    var onConnected: (() -> Void)?
    var onDisconnected: ((Error?) -> Void)?
    var onMessageReceived: ((ConversationEvent) -> Void)?
    var onError: ((Error) -> Void)?

    init(sessionState: SessionState) {
        self.sessionState = sessionState
        self.urlSession = URLSession(configuration: .default)
    }

    // MARK: - Token Acquisition
    func getEphemeralToken() async throws -> SessionToken {
        print("🔑 ===== STARTING EPHEMERAL TOKEN REQUEST =====")
        print("🔑 Requesting ephemeral token from XAI API...")
        print("🔑 URL: \(sessionURL.absoluteString)")

        var request = URLRequest(url: sessionURL)
        request.httpMethod = "POST"
        print("🔑 HTTP Method: \(request.httpMethod ?? "UNKNOWN")")

        // Set headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Config.appSecret, forHTTPHeaderField: "X-App-Secret")

        print("🔑 Request Headers:")
        if let headers = request.allHTTPHeaderFields {
            for (key, value) in headers {
                print("🔑   \(key): \(value)")
            }
        }

        // Create request body
        let requestBody = ["expires_after": ["seconds": 300]]
        print("🔑 Request Body (JSON):")
        print("🔑   \(requestBody)")

        let jsonData = try JSONEncoder().encode(requestBody)
        request.httpBody = jsonData

        print("🔑 Request Body (Raw):")
        if let bodyString = String(data: jsonData, encoding: .utf8) {
            print("🔑   \(bodyString)")
        }

        print("🔑 ===== SENDING REQUEST =====")

        do {
            let (data, response) = try await urlSession.data(for: request)

            print("🔑 ===== RECEIVED RESPONSE =====")

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ ERROR: Response is not HTTPURLResponse")
                print("❌ Response type: \(type(of: response))")
                print("❌ Response: \(response)")
                throw XAIVoiceError.invalidResponse
            }

            print("🔑 Response Status Code: \(httpResponse.statusCode)")
            print("🔑 Response Status: \(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))")

            print("🔑 Response Headers:")
            for (key, value) in httpResponse.allHeaderFields {
                print("🔑   \(key): \(value)")
            }

            print("🔑 Response Body (Raw Data Length): \(data.count) bytes")

            if let responseString = String(data: data, encoding: .utf8) {
                print("🔑 Response Body (String):")
                print("🔑   \(responseString)")
            } else {
                print("❌ ERROR: Cannot convert response data to string")
                print("❌ Response Data (Hex): \(data.map { String(format: "%02x", $0) }.joined(separator: " "))")
            }

            guard httpResponse.statusCode == 200 else {
                let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ ERROR: HTTP \(httpResponse.statusCode) - \(errorText)")
                throw XAIVoiceError.apiError(statusCode: httpResponse.statusCode, message: errorText)
            }

            print("🔑 ===== PARSING JSON RESPONSE =====")

            do {
                let sessionToken = try JSONDecoder().decode(SessionToken.self, from: data)
                print("✅ Successfully parsed JSON response")
                print("✅ Token Value: \(sessionToken.value.prefix(10))...\(sessionToken.value.suffix(10))")
                print("✅ Token Expires At: \(Date(timeIntervalSince1970: sessionToken.expiresAt))")
                print("✅ Token Expires In: \(sessionToken.expiresAt - Date().timeIntervalSince1970) seconds")

                print("✅ ===== TOKEN ACQUISITION SUCCESSFUL =====")
                return sessionToken

            } catch let decodingError {
                print("❌ ERROR: Failed to decode JSON response")
                print("❌ Decoding Error: \(decodingError)")
                print("❌ Raw Response Data: \(String(data: data, encoding: .utf8) ?? "Cannot decode")")
                throw decodingError
            }

        } catch let networkError {
            print("❌ ERROR: Network request failed")
            print("❌ Network Error: \(networkError)")
            print("❌ Error Type: \(type(of: networkError))")
            throw networkError
        }
    }

    // MARK: - WebSocket Connection
    func connect() async throws {
        print("🔌 Connecting to XAI Voice API...")

        // Get ephemeral token first (like web client examples)
        let token = try await getEphemeralToken()

        // Create WebSocket task with protocol headers
        var request = URLRequest(url: websocketURL)
        request.setValue("Bearer \(token.value)", forHTTPHeaderField: "Authorization")

        webSocketTask = urlSession.webSocketTask(with: request)
        webSocketTask?.resume()

        // Start receiving messages
        receiveMessages()

        // Wait for connection to be established
        try await waitForConnection()

        print("✅ WebSocket connected to XAI API")
    }

    private func waitForConnection() async throws {
        // Simple timeout-based wait for connection
        let timeout: TimeInterval = 10.0
        let startTime = Date()

        while webSocketTask?.state != .running {
            if Date().timeIntervalSince(startTime) > timeout {
                throw XAIVoiceError.connectionTimeout
            }
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
    }

    // MARK: - Session Configuration

    func configureSession(tools: [ConversationEvent.ToolDefinition]? = nil) throws {
        print("⚙️ Configuring voice session...")

        let sessionConfig = ConversationEvent(
            type: .sessionUpdate,
            audio: nil,
            text: nil,
            delta: nil,
            session: ConversationEvent.SessionConfig(
                instructions: instructions + "\n\nToday's Date: \(DateFormatter.localizedString(from: Date(), dateStyle: .full, timeStyle: .none)).",
                voice: voice,
                audio: ConversationEvent.AudioConfig(
                    input: ConversationEvent.AudioFormat(
                        format: ConversationEvent.AudioFormatType(
                            type: .audioPcm,
                            rate: sampleRate
                        )
                    ),
                    output: ConversationEvent.AudioFormat(
                        format: ConversationEvent.AudioFormatType(
                            type: .audioPcm,
                            rate: sampleRate
                        )
                    )
                ),
                turnDetection: ConversationEvent.TurnDetection(type: .serverVad),
                tools: tools,
                tool_choice: tools != nil ? "auto" : nil
            ),
            item: nil,
            event_id: nil,
            previous_item_id: nil,
            response_id: nil,
            output_index: nil,
            item_id: nil,
            content_index: nil,
            audio_start_ms: nil,
            audio_end_ms: nil,
            start_time: nil,
            timestamp: nil,
            part: nil,
            response: nil,
            conversation: nil
        )

        try sendMessage(sessionConfig)
    }

    // MARK: - Audio Streaming

    func sendAudioChunk(_ audioData: Data) throws {
        let base64Audio = audioData.base64EncodedString()
        let message = ConversationEvent(
            type: .inputAudioBufferAppend,
            audio: base64Audio,
            text: nil,
            delta: nil,
            session: nil,
            item: nil,
            event_id: nil,
            previous_item_id: nil,
            response_id: nil,
            output_index: nil,
            item_id: nil,
            content_index: nil,
            audio_start_ms: nil,
            audio_end_ms: nil,
            start_time: nil,
            timestamp: nil,
            part: nil,
            response: nil,
            conversation: nil
        )
        try sendMessage(message)
    }

    func commitAudioBuffer() throws {
        let message = ConversationEvent(
            type: .inputAudioBufferCommit,
            audio: nil,
            text: nil,
            delta: nil,
            session: nil,
            item: nil,
            event_id: nil,
            previous_item_id: nil,
            response_id: nil,
            output_index: nil,
            item_id: nil,
            content_index: nil,
            audio_start_ms: nil,
            audio_end_ms: nil,
            start_time: nil,
            timestamp: nil,
            part: nil,
            response: nil,
            conversation: nil
        )
        try sendMessage(message)
    }

    func createResponse() throws {
        let message = ConversationEvent(
            type: .responseCreate,
            audio: nil,
            text: nil,
            delta: nil,
            session: nil,
            item: nil,
            event_id: nil,
            previous_item_id: nil,
            response_id: nil,
            output_index: nil,
            item_id: nil,
            content_index: nil,
            audio_start_ms: nil,
            audio_end_ms: nil,
            start_time: nil,
            timestamp: nil,
            part: nil,
            response: nil,
            conversation: nil
        )
        try sendMessage(message)
    }
    
    func sendToolOutput(toolCallId: String, output: String, success: Bool) throws {
        // Log response to SessionState
        sessionState.updateResponse(id: toolCallId, responseString: output, success: success)
        
        let toolOutput = ConversationEvent(
            type: .conversationItemCreate,
            audio: nil,
            text: nil,
            delta: nil,
            session: nil,
            item: ConversationEvent.ConversationItem(
                id: nil,
                object: nil,
                type: "function_call_output",
                status: nil,
                role: nil,
                content: nil,
                tool_calls: nil,
                call_id: toolCallId,
                output: output,
                name: nil,
                arguments: nil
            ),
            event_id: nil,
            previous_item_id: nil,
            response_id: nil,
            output_index: nil,
            item_id: nil,
            content_index: nil,
            audio_start_ms: nil,
            audio_end_ms: nil,
            start_time: nil,
            timestamp: nil,
            part: nil,
            response: nil,
            conversation: nil
        )
        try sendMessage(toolOutput)
        
        // Trigger response creation if needed immediately
        // try createResponse()
    }

    func sendTruncationEvent(itemId: String, audioEndMs: Int, contentIndex: Int = 0) throws {
        print("✂️ Truncating item \(itemId) at \(audioEndMs)ms")
        let message = ConversationEvent(
            type: .conversationItemTruncate,
            audio: nil,
            text: nil,
            delta: nil,
            session: nil,
            item: nil,
            tools: nil,
            tool_call_id: nil,
            call_id: nil,
            name: nil,
            arguments: nil,
            event_id: nil,
            previous_item_id: nil,
            response_id: nil,
            output_index: nil,
            item_id: itemId,
            content_index: contentIndex,
            audio_start_ms: nil,
            audio_end_ms: audioEndMs,
            start_time: nil,
            timestamp: nil,
            part: nil,
            response: nil,
            conversation: nil
        )
        try sendMessage(message)
    }

    // MARK: - Message Handling

    internal func sendMessage(_ message: ConversationEvent) throws {
        guard let webSocketTask = webSocketTask, webSocketTask.state == .running else {
            throw XAIVoiceError.notConnected
        }

        let jsonData = try JSONEncoder().encode(message)
        let messageString = String(data: jsonData, encoding: .utf8)!

        let wsMessage = URLSessionWebSocketTask.Message.string(messageString)
        os_log("[Client] Sending event:\n\(messageString)")
        webSocketTask.send(wsMessage) { error in
            if let error = error {
                self.onError?(error)
            }
        }
    }

    private func receiveMessages() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleTextMessage(text)
                case .data(let data):
                    self.handleDataMessage(data)
                @unknown default:
                    break
                }

                // Continue receiving messages
                self.receiveMessages()

            case .failure(let error):
                print("❌ WebSocket receive error: \(error)")
                self.onDisconnected?(error)
            }
        }
    }

    private func handleTextMessage(_ text: String) {
        guard let message = try? JSONDecoder().decode(ConversationEvent.self, from: Data(text.utf8)) else {
            os_log("[Grok] Received unanticipated message \(text)")
            return
        }

        // Always call the message callback first
        onMessageReceived?(message)
        os_log("[Grok] Received message of type \(message.type.rawValue)")

        // Then handle specific message types
        switch message.type {
        case .conversationCreated:
            os_log("💬 Conversation created, configuring session...")
            try? configureSession()

        case .sessionUpdated:
            os_log("✅ Session configured, ready for voice interaction")
            onConnected?()
            
        case .responseFunctionCallArgumentsDone:
             if let callId = message.call_id,
                let name = message.name,
                let arguments = message.arguments {
                 
                 os_log("📝 Logging tool call to SessionState: \(name)")
                 let params: [String: Any]? = {
                     guard let data = arguments.data(using: .utf8) else { return nil }
                     return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                 }()
                 
                 sessionState.addCall(id: callId, toolName: name, parameters: params ?? ["raw": arguments])
             }

        default:
            break
        }
    }

    private func handleDataMessage(_ data: Data) {
        // Handle binary data if needed
        os_log("📦 Received binary data: \(data.count) bytes")
    }

    // MARK: - Connection Management

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        print("🔌 WebSocket disconnected")
    }

    deinit {
        disconnect()
    }
}

// MARK: - Error Types

enum XAIVoiceError: Error, Equatable{
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case connectionTimeout
    case notConnected
    case invalidToken

    var localizedDescription: String {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let statusCode, let message):
            return "API Error (\(statusCode)): \(message)"
        case .connectionTimeout:
            return "WebSocket connection timed out"
        case .notConnected:
            return "WebSocket is not connected"
        case .invalidToken:
            return "Invalid or expired token"
        }
    }
}
