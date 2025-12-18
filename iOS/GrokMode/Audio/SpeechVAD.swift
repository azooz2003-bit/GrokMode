//
//  SpeechVAD.swift
//  GrokMode
//
//

import Speech
import AVFoundation
import OSLog

protocol SpeechVADDelegate: AnyObject {
    func speechVADDidDetectSpeech()
    func speechVADDidDetectSilence()
}

class SpeechVAD {
    weak var delegate: SpeechVADDelegate?

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    private(set) var isSpeaking = false // Expose as read-only
    private var silenceTimer: Timer?
    private let silenceTimeout: TimeInterval = 1.0 // Consider silence after 1 second of no speech

    init() {
        // Use device locale for best recognition
        speechRecognizer = SFSpeechRecognizer()

        // Request speech recognition permission if needed
        SFSpeechRecognizer.requestAuthorization { status in
            switch status {
            case .authorized:
                AppLogger.audio.info("✅ Speech recognition authorized")
            case .denied:
                AppLogger.audio.warning("❌ Speech recognition denied")
            case .restricted:
                AppLogger.audio.warning("⚠️ Speech recognition restricted")
            case .notDetermined:
                AppLogger.audio.info("Speech recognition not determined")
            @unknown default:
                break
            }
        }
    }

    func startDetection() {
        guard speechRecognizer?.isAvailable == true else {
            AppLogger.audio.error("Speech recognizer not available")
            return
        }

        // Create a new recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognitionRequest = recognitionRequest else {
            AppLogger.audio.error("Failed to create recognition request")
            return
        }

        // Don't store audio on device
        recognitionRequest.shouldReportPartialResults = true

        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                // Speech detected!
                self.handleSpeechDetected(result)
            }

            if error != nil {
                self.stopDetection()
            }
        }

        AppLogger.audio.info("🎤 Speech-based VAD started")
    }

    func stopDetection() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        silenceTimer?.invalidate()
        silenceTimer = nil
        isSpeaking = false

        AppLogger.audio.info("🛑 Speech-based VAD stopped")
    }

    func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        recognitionRequest?.append(buffer)
    }

    private func handleSpeechDetected(_ result: SFSpeechRecognitionResult) {
        // Check if we actually detected speech (not just silence)
        let hasText = !result.bestTranscription.formattedString.trimmingCharacters(in: .whitespaces).isEmpty

        if hasText && !isSpeaking {
            // User started speaking!
            isSpeaking = true
            delegate?.speechVADDidDetectSpeech()

            #if DEBUG
            AppLogger.audio.debug("🗣️ Speech detected: \"\(result.bestTranscription.formattedString)\"")
            #endif
        }

        if hasText {
            // Reset silence timer on any speech
            silenceTimer?.invalidate()
            silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceTimeout, repeats: false) { [weak self] _ in
                self?.handleSilenceDetected()
            }
        }
    }

    private func handleSilenceDetected() {
        if isSpeaking {
            isSpeaking = false
            delegate?.speechVADDidDetectSilence()

            #if DEBUG
            AppLogger.audio.debug("🤫 Silence detected")
            #endif
        }
    }

    deinit {
        stopDetection()
    }
}
