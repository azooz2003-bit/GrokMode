//
//  VoicePerformer.swift
//  GrokMode
//
//  Created by Claude on 12/7/25.
//

import Foundation

// MARK: - Errors

enum VoicePerformerError: LocalizedError {
    case emptyScript
    case generationFailed(String)
    case apiError(Error)
    case audioProcessingFailed
    case cancelled
    case noVoiceAvailable

    var errorDescription: String? {
        switch self {
        case .emptyScript:
            return "Script contains no segments to perform"
        case .generationFailed(let reason):
            return "Failed to generate voice performance: \(reason)"
        case .apiError(let error):
            return "API error: \(error.localizedDescription)"
        case .audioProcessingFailed:
            return "Failed to process audio data"
        case .cancelled:
            return "Performance generation was cancelled"
        case .noVoiceAvailable:
            return "No suitable voice found for character"
        }
    }
}

// MARK: - Voice Performer

/// Converts manga scripts into voice performances using Grok TTS API
class VoicePerformer {
    private let ttsEndpoint = URL(string: "https://api.x.ai/v1/audio/speech")!

    private var currentTask: Task<AudioPerformance, Error>?

    // Voice options from xAI API
    enum Voice: String, CaseIterable {
        case ara = "Ara"    // Female - Warm, friendly, balanced
        case rex = "Rex"    // Male - Confident, clear, professional
        case sal = "Sal"    // Neutral - Smooth, balanced, versatile
        case eve = "Eve"    // Female - Energetic, upbeat, enthusiastic
        case una = "Una"    // Female - Calm, measured, soothing
        case leo = "Leo"    // Male - Authoritative, strong, commanding
    }

    init() {
        // API key loaded from APIConfig
    }

    func perform(_ script: MangaScript) async throws -> AudioPerformance {
        print("🎭 Starting voice performance generation...")

        guard !script.segments.isEmpty else {
            throw VoicePerformerError.emptyScript
        }

        // Cancel any existing task
        cancelPerformance()

        // Create and store the performance task
        let task = Task<AudioPerformance, Error> {
            try await generatePerformance(for: script)
        }
        currentTask = task

        return try await task.value
    }

    func cancelPerformance() {
        currentTask?.cancel()
        currentTask = nil
    }

    private func generatePerformance(for script: MangaScript) async throws -> AudioPerformance {
        var audioChunks: [Data] = []
        var segmentTimings: [AudioPerformance.SegmentTiming] = []
        var currentTime: TimeInterval = 0.0

        print("📊 Generating audio for \(script.segments.count) segments...")

        for (index, segment) in script.segments.enumerated() {
            try Task.checkCancellation()

            print("  [\(index + 1)/\(script.segments.count)] \(segment.type.rawValue): \"\(segment.content.prefix(50))...\"")

            // Add pause before segment
            if let pauseBefore = segment.timing?.pauseBefore, pauseBefore > 0 {
                let silenceData = generateSilence(duration: pauseBefore)
                audioChunks.append(silenceData)
                currentTime += pauseBefore
            }

            // Generate audio for this segment
            let startTime = currentTime
            let segmentAudio: Data

            switch segment.type {
            case .dialogue, .thought:
                // Use TTS for dialogue and thoughts
                let voice = selectVoice(for: segment.character, emotion: segment.emotion)
                let text = formatSegmentForTTS(segment)
                segmentAudio = try await generateTTS(text: text, voice: voice)

            case .narration:
                // Use calm, neutral voice for narration
                let text = segment.content
                segmentAudio = try await generateTTS(text: text, voice: .ara)

            case .soundEffect:
                // Generate short tone for sound effects (or skip)
                // For now, we'll use a short pause
                segmentAudio = generateSilence(duration: 0.3)

            case .action:
                // Use subtle narration for actions
                let text = segment.content
                segmentAudio = try await generateTTS(text: text, voice: .sal)
            }

            let duration = calculateDuration(for: segmentAudio)
            audioChunks.append(segmentAudio)
            currentTime += duration

            segmentTimings.append(AudioPerformance.SegmentTiming(
                segmentId: segment.id,
                startTime: startTime,
                endTime: currentTime
            ))

            print("    ✓ Generated \(duration)s of audio")
        }

        // Combine all audio chunks
        let combinedAudio = audioChunks.reduce(Data(), +)

        print("✅ Voice performance generated: \(currentTime)s, \(combinedAudio.count) bytes")

        return AudioPerformance(
            script: script,
            audioData: combinedAudio,
            format: .standard,
            duration: currentTime,
            segmentTimings: segmentTimings
        )
    }

    // MARK: - TTS Generation

    private func generateTTS(text: String, voice: Voice, retryCount: Int = 0) async throws -> Data {
        var request = URLRequest(url: ttsEndpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(APIConfig.xAiApiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0

        let requestBody: [String: Any] = [
            "input": text,
            "voice": voice.rawValue,
            "response_format": "wav"  // WAV format for easy concatenation
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw VoicePerformerError.generationFailed("Invalid response")
            }

            guard httpResponse.statusCode == 200 else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"

                // Retry on rate limit or server errors
                if (httpResponse.statusCode == 429 || httpResponse.statusCode >= 500) && retryCount < 3 {
                    let delay = TimeInterval(pow(2.0, Double(retryCount))) // Exponential backoff
                    print("    ⚠️ TTS failed (HTTP \(httpResponse.statusCode)), retrying in \(delay)s...")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    return try await generateTTS(text: text, voice: voice, retryCount: retryCount + 1)
                }

                throw VoicePerformerError.generationFailed("HTTP \(httpResponse.statusCode): \(errorMessage)")
            }

            guard !data.isEmpty else {
                throw VoicePerformerError.audioProcessingFailed
            }

            // Extract PCM data from WAV file (skip 44-byte header)
            // WAV files from API have standard headers, we only want the raw audio data
            let pcmData: Data
            if data.count > 44 {
                pcmData = data.subdata(in: 44..<data.count)
            } else {
                pcmData = data
            }

            return pcmData

        } catch is CancellationError {
            throw VoicePerformerError.cancelled
        } catch {
            throw VoicePerformerError.apiError(error)
        }
    }

    // MARK: - Voice Selection

    private func selectVoice(for character: Character?, emotion: ScriptSegment.Emotion?) -> Voice {
        guard let character = character else {
            return .ara  // Default voice for narrator
        }

        let personality = character.personality

        // Voice selection based on character personality and emotion
        switch (personality.energy, personality.tone, personality.confidence) {
        case (.veryEnergetic, _, _), (_, .comedic, _):
            return .eve  // Energetic and enthusiastic

        case (.veryCalm, _, _), (_, _, .timid):
            return .una  // Calm and measured

        case (_, .serious, .domineering), (_, .serious, .veryConfident):
            return .leo  // Authoritative and commanding

        case (_, .serious, _), (.calm, _, _):
            return .rex  // Professional and clear

        case (.energetic, .playful, _):
            return .eve  // Energetic and enthusiastic

        default:
            // Default based on general energy level
            if personality.energy == .energetic || personality.energy == .veryEnergetic {
                return .eve
            } else if personality.energy == .calm || personality.energy == .veryCalm {
                return .una
            } else {
                return .ara  // Balanced default
            }
        }
    }

    private func formatSegmentForTTS(_ segment: ScriptSegment) -> String {
        // For TTS API, we just send the raw text
        // The emotion and character traits are handled through voice selection
        return segment.content
    }

    // MARK: - Helper Functions

    private func generateSilence(duration: TimeInterval) -> Data {
        let sampleRate = 24000
        let samples = Int(duration * Double(sampleRate))
        return Data(repeating: 0, count: samples * 2) // 16-bit = 2 bytes per sample
    }

    private func calculateDuration(for audioData: Data) -> TimeInterval {
        let sampleRate = 24000.0
        let bytesPerSample = 2 // 16-bit
        let sampleCount = audioData.count / bytesPerSample
        return Double(sampleCount) / sampleRate
    }
}
