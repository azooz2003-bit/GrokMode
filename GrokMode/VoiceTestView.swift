//
//  VoiceTestView.swift
//  GrokMode
//
//  Created by Elon Musk's AI Assistant on 12/7/25.
//

import SwiftUI
import AVFoundation
import Combine


struct VoiceTestView: View {
    @StateObject private var viewModel = VoiceTestViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Title
                    Text("🎙️ XAI Voice Test")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    // Permission Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Microphone Permission")
                            .font(.headline)
                        
                        HStack {
                            Image(systemName: viewModel.micPermissionGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(viewModel.micPermissionGranted ? .green : .red)
                            Text(viewModel.micPermissionStatus)
                            Spacer()
                            if !viewModel.micPermissionGranted {
                                Button("Request Access") {
                                    viewModel.requestMicrophonePermission()
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    
                    // Connection Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Connection Status")
                            .font(.headline)
                        
                        HStack {
                            Circle()
                                .fill(viewModel.connectionStateColor)
                                .frame(width: 12, height: 12)
                            Text(viewModel.connectionStateText)
                            Spacer()
                            Text(viewModel.lastActivityText)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Text("Session:")
                            Image(systemName: viewModel.sessionConfigured ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(viewModel.sessionConfigured ? .green : .gray)
                            Text(viewModel.sessionConfigured ? "Configured" : "Not Configured")
                        }
                        
                        HStack {
                            Text("Audio:")
                            Image(systemName: viewModel.isAudioStreaming ? "waveform.circle.fill" : "waveform.circle")
                                .foregroundColor(viewModel.isAudioStreaming ? .blue : .gray)
                            Text(viewModel.isAudioStreaming ? "Streaming" : "Not Streaming")
                        }

                        HStack {
                            Text("Gerald:")
                            Image(systemName: viewModel.isGeraldSpeaking ? "speaker.wave.3.fill" : "speaker.slash.fill")
                                .foregroundColor(viewModel.isGeraldSpeaking ? .green : .gray)
                            Text(viewModel.isGeraldSpeaking ? "Speaking" : "Silent")
                        }
                        
                        VStack(spacing: 10) {
                            Button(action: viewModel.connect) {
                                Text(viewModel.isConnecting ? "Connecting..." : "Connect")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(!viewModel.canConnect || viewModel.isConnecting)
                            
                            Button(action: viewModel.disconnect) {
                                Text("Disconnect")
                            }
                            .buttonStyle(.bordered)
                            .disabled(viewModel.connectionState == .disconnected)
                            
                            Button(action: viewModel.clearLog) {
                                Text("Clear Log")
                            }
                            .buttonStyle(.bordered)
                            
                            Button(action: viewModel.sendTestAudio) {
                                Text("Send Test Audio")
                            }
                            .buttonStyle(.bordered)
                            .disabled(viewModel.connectionState != .connected)
                            
                            Button(action: {
                                if viewModel.isAudioStreaming {
                                    viewModel.stopAudioStreaming()
                                } else {
                                    viewModel.startAudioStreaming()
                                }
                            }) {
                                Text(viewModel.isAudioStreaming ? "Stop Streaming" : "Start Streaming")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(viewModel.connectionState != .connected)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                    
                    // Message Log
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Message Log")
                                .font(.headline)
                            Spacer()
                            Text("\(viewModel.messageLog.count) messages")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        ScrollViewReader { scrollView in
                            ScrollView {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(viewModel.messageLog) { message in
                                        MessageRow(message: message)
                                            .id(message.id)
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                            .frame(height: 300)
                            .background(Color.black.opacity(0.05))
                            .cornerRadius(8)
                            .onChange(of: viewModel.messageLog.count) { _ in
                                if let lastMessage = viewModel.messageLog.last {
                                    scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
                    
                    Spacer()
                }
                .padding()
                .onAppear {
                    viewModel.checkPermissions()
                }
            }
            .navigationViewStyle(.stack)
        }
    }
}

struct MessageRow: View {
    let message: DebugMessage

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(message.timestampString)
                .font(.caption2)
                .foregroundColor(.gray)
                .frame(width: 60, alignment: .leading)

            Text(message.directionArrow)
                .font(.caption)
                .foregroundColor(message.directionColor)

            Text(message.typeIcon)
                .font(.caption)

            VStack(alignment: .leading, spacing: 2) {
                Text(message.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(message.typeColor)

                if !message.details.isEmpty {
                    Text(message.details)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }
}

struct DebugMessage: Identifiable {
    let id = UUID()
    let timestamp: Date
    let type: MessageType
    let direction: MessageDirection
    let title: String
    let details: String

    var timestampString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }

    var directionArrow: String {
        switch direction {
        case .sent: return "→"
        case .received: return "←"
        case .system: return "⚙️"
        }
    }

    var directionColor: Color {
        switch direction {
        case .sent: return .blue
        case .received: return .green
        case .system: return .orange
        }
    }

    var typeIcon: String {
        switch type {
        case .websocket: return "🔗"
        case .audio: return "🎵"
        case .system: return "⚙️"
        case .error: return "❌"
        }
    }

    var typeColor: Color {
        switch type {
        case .websocket: return .blue
        case .audio: return .purple
        case .system: return .orange
        case .error: return .red
        }
    }
}

enum MessageType {
    case websocket, audio, system, error
}

enum MessageDirection {
    case sent, received, system
}

class VoiceTestViewModel: NSObject, ObservableObject, AudioStreamerDelegate {
    // Permissions
    @Published var micPermissionGranted = false
    @Published var micPermissionStatus = "Checking..."

    // Connection
    @Published var connectionState: ConnectionState = .disconnected
    @Published var isConnecting = false
    @Published var sessionConfigured = false
    @Published var lastActivity: Date?
    @Published var isAudioStreaming = false


    // Audio streaming
    @Published var isGeraldSpeaking = false
    @Published var messageLog: [DebugMessage] = []


    // Audio playback properties removed (audioQueue, currentAudioPlayer)


    // XAI Service
    private var xaiService: XAIVoiceService?
    
    // Audio Streamer
    private var audioStreamer: AudioStreamer!

    override init() {
        super.init()
        // Initialize AudioStreamer
        audioStreamer = AudioStreamer()
        audioStreamer.delegate = self
        
        checkPermissions()
    }

    var canConnect: Bool {
        return micPermissionGranted && connectionState == .disconnected && !isConnecting
    }

    var connectionStateColor: Color {
        switch connectionState {
        case .disconnected: return .gray
        case .connecting: return .yellow
        case .connected: return .green
        case .error: return .red
        }
    }

    var connectionStateText: String {
        switch connectionState {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .error: return "Connection Error"
        }
    }

    var lastActivityText: String {
        guard let lastActivity = lastActivity else { return "No activity" }
        let seconds = Int(Date().timeIntervalSince(lastActivity))
        if seconds < 60 {
            return "\(seconds)s ago"
        } else {
            return "1m+ ago"
        }
    }

    func checkPermissions() {
        let permissionStatus = AVAudioSession.sharedInstance().recordPermission

        switch permissionStatus {
        case .granted:
            micPermissionGranted = true
            micPermissionStatus = "Granted"
            logMessage(.system, .system, "Microphone permission granted", "")
        case .denied:
            micPermissionGranted = false
            micPermissionStatus = "Denied"
            logMessage(.system, .system, "Microphone permission denied", "")
        case .undetermined:
            micPermissionGranted = false
            micPermissionStatus = "Not requested"
            logMessage(.system, .system, "Microphone permission not requested", "")
        @unknown default:
            micPermissionGranted = false
            micPermissionStatus = "Unknown"
        }
    }

    func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.micPermissionGranted = granted
                self?.micPermissionStatus = granted ? "Granted" : "Denied"
                let status = granted ? "granted" : "denied"
                self?.logMessage(.system, .system, "Microphone permission \(status)", "")
            }
        }
    }

    func connect() {
        guard canConnect else { return }

        isConnecting = true
        connectionState = .connecting
        sessionConfigured = false

        logMessage(.system, .system, "Starting XAI connection", "")

        // Initialize XAI service
        xaiService = XAIVoiceService(apiKey: "xai-6ab6MBdEeM26TVCX17g11UGQDT34sA0b5CBff0f9leY23WXzUeQWugxZB0ukgolPllZkXKVsD6VPd8lQ")

        // Initialize audio streamer
        // setupAudioSessionForPlayback is called internally by AudioStreamer
        
        // Setup audio session for playback/recording
        // setupAudioSessionForPlayback() - REMOVED (AudioStreamer handles this)
        
        // Set up callbacks
        xaiService?.onConnected = { [weak self] in
            DispatchQueue.main.async {
                self?.connectionState = .connected
                self?.isConnecting = false
                self?.lastActivity = Date()
                self?.logMessage(.system, .system, "XAI connection established", "")
            }
        }

        xaiService?.onMessageReceived = { [weak self] message in
            DispatchQueue.main.async {
                self?.handleXAIMessage(message)
            }
        }

        xaiService?.onError = { [weak self] error in
            DispatchQueue.main.async {
                self?.connectionState = .error
                self?.isConnecting = false
                self?.logMessage(.error, .system, "XAI Error", error.localizedDescription)
            }
        }


        // Start connection
        Task {
            do {
                try await xaiService!.connect()

                // Configure session with Gerald McGrokMode personality
                try xaiService!.configureSantaSession()

                await MainActor.run {
                    logMessage(.system, .system, "Session configured for Gerald McGrokMode", "")
                }

            } catch {
                await MainActor.run {
                    self.connectionState = .error
                    self.isConnecting = false
                    self.logMessage(.error, .system, "Connection failed", error.localizedDescription)
                }
            }
        }
    }

    func disconnect() {
        xaiService?.disconnect()
        audioStreamer.stopStreaming()
        isGeraldSpeaking = false

        connectionState = .disconnected
        isConnecting = false
        sessionConfigured = false
        isAudioStreaming = false
        logMessage(.system, .system, "Disconnected from XAI", "")
    }

    func clearLog() {
        messageLog.removeAll()
    }

    func sendTestAudio() {
        logMessage(.system, .system, "Sending test audio to XAI", "")

        // Create a simple test audio buffer (1 second of silence at 24kHz, 16-bit PCM)
        let sampleRate = 24000
        let duration = 1.0 // 1 second
        let samples = Int(Float(sampleRate) * Float(duration))
        let audioData = Data(repeating: 0, count: samples * 2) // 16-bit samples = 2 bytes each

        do {
            try xaiService?.sendAudioChunk(audioData)
            try xaiService?.commitAudioBuffer()
            logMessage(.audio, .sent, "Test audio sent", "\(audioData.count) bytes")
        } catch {
            logMessage(.error, .system, "Failed to send test audio", error.localizedDescription)
        }
    }

    func startAudioStreaming() {
        guard connectionState == .connected else {
            logMessage(.error, .system, "Cannot start audio streaming", "Not connected to XAI")
            return
        }
        audioStreamer.startStreaming()
        isAudioStreaming = true
        logMessage(.system, .system, "Audio streaming started", "")
    }

    func stopAudioStreaming() {
        audioStreamer.stopStreaming()
        isAudioStreaming = false
        logMessage(.system, .system, "Audio streaming stopped", "")
    }


    private func handleXAIMessage(_ message: VoiceMessage) {
        // Print to console for debugging
        print("🔊 XAI WebSocket Message: \(message.type)")
        if let text = message.text {
            print("🔊 Text: \(text)")
        }
        if let audio = message.audio {
            print("🔊 Audio: \(audio.prefix(50))... (\(audio.count) chars)")
        }

        // ALL UI updates must be on main thread
        DispatchQueue.main.async {
            self.lastActivity = Date()

            // Log to UI
            let title: String
            var details = ""

            switch message.type {
            case "conversation.created":
                title = "Conversation Created"
                details = "XAI session initialized"
                self.sessionConfigured = true

            case "session.updated":
                title = "Session Updated"
                details = "Voice session configured"
                self.sessionConfigured = true

            case "response.created":
                title = "Response Started"
                details = "Gerald is speaking"

            case "response.done":
                title = "Response Complete"
                details = "Gerald finished speaking"

            case "input_audio_buffer.speech_started":
                title = "Speech Detected"
                details = "User started speaking"

            case "input_audio_buffer.speech_stopped":
                title = "Speech Ended"
                details = "User stopped speaking"

            case "input_audio_buffer.committed":
                title = "Audio Committed"
                details = "Audio sent for processing"

            case "response.output_audio.delta":
                if let delta = message.delta, let audioData = Data(base64Encoded: delta) {
                    self.audioStreamer.playAudio(audioData) 
                    self.isGeraldSpeaking = true
                }
                title = "Audio Chunk"
                details = "Gerald speaking (\(message.delta?.count ?? 0) chars)"

            case "error":
                title = "XAI Error"
                details = message.text ?? "Unknown error"
                self.logMessage(.error, .received, title, details)
                return

            default:
                title = message.type
                if let text = message.text {
                    details = text
                } else if let audio = message.audio {
                    details = "Audio data (\(audio.count) chars)"
                }
            }

            self.logMessage(.websocket, .received, title, details)
        }
    }

    // MARK: - AudioStreamerDelegate

    func audioStreamerDidReceiveAudioData(_ data: Data) {
        // Send to XAI
        do {
            try xaiService?.sendAudioChunk(data)
            // Log occasionally
            if arc4random_uniform(50) == 0 {
               DispatchQueue.main.async {
                   self.logMessage(.audio, .sent, "Audio chunk sent", "\(data.count) bytes")
               }
            }
        } catch {
            print("Failed to send audio chunk: \(error)")
        }
    }
    
    func audioStreamerDidDetectSpeechStart() {
        DispatchQueue.main.async {
            self.logMessage(.audio, .system, "🎤 Speech detected", "Streaming to XAI")
        }
    }
    
    func audioStreamerDidDetectSpeechEnd() {
        DispatchQueue.main.async {
            self.logMessage(.audio, .system, "🤫 Speech ended", "Committing audio")
            try? self.xaiService?.commitAudioBuffer()
        }
    }



    private func logMessage(_ type: MessageType, _ direction: MessageDirection, _ title: String, _ details: String) {
        let message = DebugMessage(
            timestamp: Date(),
            type: type,
            direction: direction,
            title: title,
            details: details
        )
        DispatchQueue.main.async {
            self.messageLog.append(message)

            // Keep only last 100 messages
            if self.messageLog.count > 100 {
                self.messageLog.removeFirst()
            }
        }
        // Debug print to console
        print("\(message.directionArrow) \(title): \(details)")
    }
}

enum ConnectionState {
    case disconnected, connecting, connected, error
}

// MARK: - Extensions

extension FixedWidthInteger {
    var littleEndianBytes: [UInt8] {
        withUnsafeBytes(of: self.littleEndian) { Array($0) }
    }
}

