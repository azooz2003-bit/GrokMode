//
//  MangaScenePerformer.swift
//  GrokMode
//
//  Created by Claude on 12/7/25.
//

import Foundation
import UIKit
import Combine

// MARK: - Processing Progress

enum ProcessingProgress {
    case idle
    case parsing(progress: Double)
    case generating(progress: Double)
    case loading
    case ready
    case failed(Error)

    var description: String {
        switch self {
        case .idle:
            return "Idle"
        case .parsing(let progress):
            return "Parsing manga... \(Int(progress * 100))%"
        case .generating(let progress):
            return "Generating voice... \(Int(progress * 100))%"
        case .loading:
            return "Loading audio..."
        case .ready:
            return "Ready to play"
        case .failed(let error):
            return "Failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Manga Scene Performer

/// Orchestrates the manga-to-audio pipeline
class MangaScenePerformer {
    // MARK: - Dependencies

    private let parser = MangaParser()
    private let performer = VoicePerformer()
    private let player = AudioPlayer()

    // MARK: - State

    var playbackState: PlaybackState {
        player.playbackState
    }

    var playbackStatePublisher: AnyPublisher<PlaybackState, Never> {
        player.playbackStatePublisher
    }

    var progressPublisher: AnyPublisher<ProcessingProgress, Never> {
        progressSubject.eraseToAnyPublisher()
    }

    private let progressSubject = CurrentValueSubject<ProcessingProgress, Never>(.idle)

    private var currentScript: MangaScript?
    private var currentPerformance: AudioPerformance?
    private var processingTask: Task<Void, Error>?

    // MARK: - Public Methods

    func processPage(_ page: MangaPage) async throws {
        print("🎬 Starting manga scene performance pipeline...")
        progressSubject.send(.idle)

        // Cancel any existing processing
        cancel()

        // Create processing task
        processingTask = Task {
            do {
                // Step 1: Parse manga page
                print("📖 Step 1: Parsing manga page...")
                progressSubject.send(.parsing(progress: 0.0))

                let script = try await parser.parse(page)
                currentScript = script

                progressSubject.send(.parsing(progress: 1.0))
                print("✅ Parsing complete: \(script.segments.count) segments")

                // Step 2: Generate voice performance
                print("🎭 Step 2: Generating voice performance...")
                progressSubject.send(.generating(progress: 0.0))

                let performance = try await performer.perform(script)
                currentPerformance = performance

                progressSubject.send(.generating(progress: 1.0))
                print("✅ Voice generation complete: \(performance.duration)s")

                // Step 3: Load audio into player
                print("🔊 Step 3: Loading audio...")
                progressSubject.send(.loading)

                try await player.load(performance)

                progressSubject.send(.ready)
                print("✅ Pipeline complete! Ready to play.")

            } catch is CancellationError {
                print("🚫 Processing cancelled")
                progressSubject.send(.idle)
            } catch {
                print("❌ Pipeline failed: \(error)")
                progressSubject.send(.failed(error))
                throw error
            }
        }

        try await processingTask?.value
    }

    func play() throws {
        try player.play()
    }

    func pause() {
        player.pause()
    }

    func stop() {
        player.stop()
    }

    func cancel() {
        processingTask?.cancel()
        processingTask = nil

        parser.cancelParsing()
        performer.cancelPerformance()

        progressSubject.send(.idle)
    }

    // MARK: - Additional Features

    /// Get the parsed script from the last processed page
    func getCurrentScript() -> MangaScript? {
        return currentScript
    }

    /// Get the current audio performance
    func getCurrentPerformance() -> AudioPerformance? {
        return currentPerformance
    }

    /// Get the segment currently being played
    func getCurrentSegment() -> ScriptSegment? {
        return player.currentSegment()
    }
}
