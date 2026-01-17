//
//  VoiceUsageClock.swift
//  Tweety
//
//  Created by Abdulaziz Albahar on 1/17/26.
//

import Foundation
import OSLog

/// Manages session timing and usage tracking for voice sessions
@MainActor
final class VoiceUsageClock {
    // MARK: - Properties

    private var sessionElapsedTime: TimeInterval = 0
    private(set) var sessionStartTime: Date?
    private var sessionTimer: Timer?
    private var trackedMinutes: Int = 0

    private let usageTracker: UsageTracker
    private let authService: XAuthService

    // MARK: - Callbacks

    var onInsufficientCredits: (() -> Void)?
    var onTrackingError: ((Error) -> Void)?

    // MARK: - Initialization

    init(usageTracker: UsageTracker, authService: XAuthService) {
        self.usageTracker = usageTracker
        self.authService = authService
    }

    // MARK: - Public Methods

    /// Starts the session timer for the specified service type
    /// - Parameter serviceType: The voice service type (only xAI requires per-minute tracking)
    func startTimer(for serviceType: VoiceServiceType) {
        sessionStartTime = Date()
        sessionElapsedTime = 0
        trackedMinutes = 0

        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in

                guard let self = self, let startTime = self.sessionStartTime else { return }
                self.sessionElapsedTime = Date().timeIntervalSince(startTime)

                // Track usage every complete minute for xAI sessions
                if serviceType == .xai {
                    let currentMinute = Int(self.sessionElapsedTime / 60)
                    if currentMinute > self.trackedMinutes {
                        self.trackedMinutes = currentMinute

                        await self.trackMinuteUsage()
                    }
                }
            }
        }
    }

    /// Stops the timer and cleans up resources
    func stopTimer() {
        sessionTimer?.invalidate()
        sessionTimer = nil
        sessionStartTime = nil
        sessionElapsedTime = 0
        trackedMinutes = 0
    }

    /// Tracks any untracked partial usage for xAI sessions
    /// Called when app backgrounds or session stops
    func trackPartialUsageIfNeeded(for serviceType: VoiceServiceType) {
        guard serviceType == .xai, sessionElapsedTime > 0 else { return }

        let remainingSeconds = sessionElapsedTime.truncatingRemainder(dividingBy: 60)
        if remainingSeconds > 0 {
            Task { @MainActor in
                do {
                    let userId = try await authService.requiredUserId
                    let minutes = remainingSeconds / 60.0
                    _ = await usageTracker.trackAndRegisterXAIUsage(
                        minutes: minutes,
                        userId: userId
                    )
                    // Don't stop session on failure here - this is a checkpoint, not critical
                } catch {
                    AppLogger.voice.error("Failed to track partial usage: \(error)")
                }
            }
        }
    }

    // MARK: - Private Methods

    private func trackMinuteUsage() async {
        do {
            let userId = try await authService.requiredUserId
            let result = await usageTracker.trackAndRegisterXAIUsage(
                minutes: 1.0,
                userId: userId
            )

            switch result {
            case .success(let balance):
                if balance.remaining <= 0 {
                    AppLogger.voice.error("xAI usage depleted credits")
                    onInsufficientCredits?()
                }
            case .failure(let error):
                AppLogger.voice.error("xAI usage tracking failed: \(error)")
                onTrackingError?(error)
            }
        } catch {
            AppLogger.voice.error("Failed to get user ID: \(error)")
            onTrackingError?(error)
        }
    }
}
