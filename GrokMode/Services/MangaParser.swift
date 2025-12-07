//
//  MangaParser.swift
//  GrokMode
//
//  Created by Claude on 12/7/25.
//

import Foundation
import UIKit

// MARK: - Errors

enum MangaParserError: LocalizedError {
    case invalidImage
    case parsingFailed(String)
    case apiError(Error)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid manga page image"
        case .parsingFailed(let reason):
            return "Failed to parse manga: \(reason)"
        case .apiError(let error):
            return "API error: \(error.localizedDescription)"
        case .cancelled:
            return "Parsing was cancelled"
        }
    }
}

// MARK: - Manga Parser

/// Parses manga pages using Grok Vision API
class MangaParser {
    private let endpoint = URL(string: "https://api.x.ai/v1/chat/completions")!
    private var currentTask: Task<MangaScript, Error>?

    init() {
        // API key loaded from Config
    }

    func parse(_ page: MangaPage) async throws -> MangaScript {
        print("📖 Starting manga page parsing...")

        // Cancel any existing parsing task
        cancelParsing()

        // Create and store the parsing task
        let task = Task<MangaScript, Error> {
            try await performParsing(page)
        }
        currentTask = task

        return try await task.value
    }

    func cancelParsing() {
        currentTask?.cancel()
        currentTask = nil
    }

    private func performParsing(_ page: MangaPage) async throws -> MangaScript {
        // Convert image to base64
        guard let imageData = page.image.jpegData(compressionQuality: 0.8) else {
            throw MangaParserError.invalidImage
        }

        let base64Image = imageData.base64EncodedString()
        let dataURL = "data:image/jpeg;base64,\(base64Image)"

        // Create the structured output schema
        let responseSchema = createResponseSchema()

        // Create the API request with structured output
        let requestBody: [String: Any] = [
            "model": "grok-4-0709",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image_url",
                            "image_url": ["url": dataURL]
                        ],
                        [
                            "type": "text",
                            "text": """
                            Analyze this manga page and extract a detailed script for voice acting performance.

                            Read panels from RIGHT to LEFT (manga style) and TOP to BOTTOM.
                            Extract ALL dialogue, sound effects, and action descriptions.
                            Infer character personalities from visual cues and dialogue.
                            Note pauses between dramatic moments and character emotions based on facial expressions.
                            """
                        ]
                    ]
                ]
            ],
            "temperature": 0.7,
            "max_tokens": 4000,
            "response_format": [
                "type": "json_schema",
                "json_schema": responseSchema
            ]
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(APIConfig.xAiApiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // Check for cancellation
        try Task.checkCancellation()

        // Make the request
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MangaParserError.parsingFailed("Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw MangaParserError.parsingFailed("HTTP \(httpResponse.statusCode): \(errorMessage)")
        }

        // Parse the response
        let script = try parseGrokResponse(data, pageNumber: page.pageNumber)

        print("✅ Manga page parsed successfully: \(script.segments.count) segments")
        return script
    }

    private func createResponseSchema() -> [String: Any] {
        return [
            "name": "manga_script",
            "strict": true,
            "schema": [
                "type": "object",
                "properties": [
                    "sceneDescription": [
                        "type": "string",
                        "description": "Brief description of what's happening in the manga page"
                    ],
                    "mood": [
                        "type": "string",
                        "enum": ["action", "comedy", "dramatic", "romantic", "suspenseful", "calm"],
                        "description": "Overall mood of the scene"
                    ],
                    "characters": [
                        "type": "array",
                        "items": [
                            "type": "object",
                            "properties": [
                                "name": [
                                    "type": "string",
                                    "description": "Character name"
                                ],
                                "personality": [
                                    "type": "object",
                                    "properties": [
                                        "energy": [
                                            "type": "string",
                                            "enum": ["veryCalm", "calm", "moderate", "energetic", "veryEnergetic"]
                                        ],
                                        "tone": [
                                            "type": "string",
                                            "enum": ["serious", "neutral", "playful", "comedic"]
                                        ],
                                        "confidence": [
                                            "type": "string",
                                            "enum": ["timid", "reserved", "confident", "veryConfident", "domineering"]
                                        ],
                                        "speech": [
                                            "type": "string",
                                            "enum": ["formal", "polite", "neutral", "casual", "slang"]
                                        ]
                                    ],
                                    "required": ["energy", "tone", "confidence", "speech"],
                                    "additionalProperties": false
                                ]
                            ],
                            "required": ["name", "personality"],
                            "additionalProperties": false
                        ]
                    ],
                    "segments": [
                        "type": "array",
                        "items": [
                            "type": "object",
                            "properties": [
                                "type": [
                                    "type": "string",
                                    "enum": ["dialogue", "narration", "soundEffect", "action", "thought"]
                                ],
                                "content": [
                                    "type": "string",
                                    "description": "The actual text or description"
                                ],
                                "characterName": [
                                    "type": ["string", "null"],
                                    "description": "Name of speaking character (null if not applicable)"
                                ],
                                "emotion": [
                                    "type": "string",
                                    "enum": ["neutral", "happy", "sad", "angry", "surprised", "scared", "excited", "confused", "disgusted", "determined", "worried", "none"],
                                    "description": "Character emotion (use 'none' if not applicable)"
                                ],
                                "pauseBefore": [
                                    "type": "number",
                                    "description": "Pause in seconds before this segment",
                                    "minimum": 0.0
                                ]
                            ],
                            "required": ["type", "content", "pauseBefore"],
                            "additionalProperties": false
                        ]
                    ]
                ],
                "required": ["sceneDescription", "mood", "characters", "segments"],
                "additionalProperties": false
            ]
        ]
    }

    private func parseGrokResponse(_ data: Data, pageNumber: Int?) throws -> MangaScript {
        // Parse the Grok API response with structured output
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let choices = json?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw MangaParserError.parsingFailed("Invalid API response structure")
        }

        // With structured output, the content is already valid JSON
        guard let contentData = content.data(using: .utf8),
              let scriptJSON = try JSONSerialization.jsonObject(with: contentData) as? [String: Any] else {
            throw MangaParserError.parsingFailed("Invalid structured output JSON")
        }

        // Parse characters
        let characters = try parseCharacters(from: scriptJSON)

        // Parse segments
        let segments = try parseSegments(from: scriptJSON, characters: characters)

        // Create metadata
        let metadata = MangaScript.ScriptMetadata(
            parsedAt: Date(),
            sceneDescription: scriptJSON["sceneDescription"] as? String,
            mood: parseMood(from: scriptJSON),
            estimatedDuration: estimateDuration(for: segments)
        )

        return MangaScript(
            pageNumber: pageNumber,
            segments: segments,
            characters: characters,
            metadata: metadata
        )
    }

    private func parseCharacters(from json: [String: Any]) throws -> [Character] {
        guard let charactersArray = json["characters"] as? [[String: Any]] else {
            return []
        }

        return charactersArray.compactMap { charDict in
            guard let name = charDict["name"] as? String,
                  let personalityDict = charDict["personality"] as? [String: String] else {
                return nil
            }

            let personality = Character.PersonalityTraits(
                energy: Character.PersonalityTraits.EnergyLevel(rawValue: personalityDict["energy"] ?? "moderate") ?? .moderate,
                tone: Character.PersonalityTraits.EmotionalTone(rawValue: personalityDict["tone"] ?? "neutral") ?? .neutral,
                confidence: Character.PersonalityTraits.ConfidenceLevel(rawValue: personalityDict["confidence"] ?? "confident") ?? .confident,
                speech: Character.PersonalityTraits.SpeechStyle(rawValue: personalityDict["speech"] ?? "neutral") ?? .neutral
            )

            // Infer voice characteristics from personality
            let voiceCharacteristics = inferVoiceCharacteristics(from: personality)

            return Character(
                name: name,
                personality: personality,
                voiceCharacteristics: voiceCharacteristics
            )
        }
    }

    private func parseSegments(from json: [String: Any], characters: [Character]) throws -> [ScriptSegment] {
        guard let segmentsArray = json["segments"] as? [[String: Any]] else {
            throw MangaParserError.parsingFailed("No segments found")
        }

        return segmentsArray.compactMap { segDict in
            guard let typeString = segDict["type"] as? String,
                  let type = ScriptSegment.SegmentType(rawValue: typeString),
                  let content = segDict["content"] as? String else {
                return nil
            }

            let characterName = segDict["characterName"] as? String
            let character = characters.first { $0.name == characterName }

            let emotionString = segDict["emotion"] as? String
            let emotion = emotionString.flatMap { $0 == "none" ? nil : ScriptSegment.Emotion(rawValue: $0) }

            let pauseBefore = segDict["pauseBefore"] as? Double ?? 0.0

            let timing = ScriptSegment.TimingInfo(
                pauseBefore: pauseBefore,
                duration: nil
            )

            return ScriptSegment(
                type: type,
                content: content,
                character: character,
                emotion: emotion,
                timing: timing
            )
        }
    }

    private func parseMood(from json: [String: Any]) -> MangaScript.ScriptMetadata.SceneMood? {
        guard let moodString = json["mood"] as? String else { return nil }
        return MangaScript.ScriptMetadata.SceneMood(rawValue: moodString)
    }

    private func estimateDuration(for segments: [ScriptSegment]) -> TimeInterval {
        // Rough estimation: ~3 words per second for dialogue
        let totalWords = segments.reduce(0) { count, segment in
            count + segment.content.split(separator: " ").count
        }
        let baseDuration = Double(totalWords) / 3.0

        // Add pauses
        let totalPauses = segments.reduce(0.0) { total, segment in
            total + (segment.timing?.pauseBefore ?? 0.0)
        }

        return baseDuration + totalPauses
    }

    private func inferVoiceCharacteristics(from personality: Character.PersonalityTraits) -> Character.VoiceCharacteristics {
        // Infer voice pitch from personality
        let pitch: Character.VoiceCharacteristics.VoicePitch
        switch personality.energy {
        case .veryCalm, .calm:
            pitch = .low
        case .moderate:
            pitch = .medium
        case .energetic, .veryEnergetic:
            pitch = .high
        }

        // Infer speech speed
        let speed: Character.VoiceCharacteristics.SpeechSpeed
        switch personality.energy {
        case .veryCalm:
            speed = .verySlow
        case .calm:
            speed = .slow
        case .moderate:
            speed = .normal
        case .energetic:
            speed = .fast
        case .veryEnergetic:
            speed = .veryFast
        }

        // Infer emphasis
        let emphasis: Character.VoiceCharacteristics.EmphasisStyle
        switch personality.tone {
        case .serious:
            emphasis = .subtle
        case .neutral:
            emphasis = .moderate
        case .playful:
            emphasis = .dramatic
        case .comedic:
            emphasis = .theatrical
        }

        return Character.VoiceCharacteristics(
            pitch: pitch,
            speed: speed,
            emphasis: emphasis
        )
    }
}
