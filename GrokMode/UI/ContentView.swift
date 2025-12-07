//
//  ContentView.swift
//  GrokMode
//
//  Created by Abdulaziz Albahar on 12/6/25.
//

import SwiftUI
import PhotosUI
import Combine

struct ContentView: View {
    @StateObject private var viewModel = MangaReaderViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Main content area
                ZStack {
                    if viewModel.selectedImage == nil {
                        // Empty state
                        emptyStateView
                    } else {
                        // Manga reader interface
                        mangaReaderView
                    }
                }

                // Playback controls (always visible when processing or ready)
                if viewModel.selectedImage != nil {
                    Divider()
                    playbackControlsView
                        .padding()
                        .background(Color(.systemBackground))
                }
            }
            .navigationTitle("GrokMode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    PhotosPicker(selection: $viewModel.selectedPhotoItem,
                                matching: .images) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.title3)
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "book.pages")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                Text("Welcome to GrokMode")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Transform manga pages into dramatic voice performances")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            PhotosPicker(selection: $viewModel.selectedPhotoItem,
                        matching: .images) {
                Label("Select Manga Page", systemImage: "photo.badge.plus")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Manga Reader View

    private var mangaReaderView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Manga image
                if let image = viewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                        .shadow(radius: 5)
                        .padding()
                }

                // Processing status
                processingStatusView

                // Transcript view
                if let script = viewModel.currentScript {
                    transcriptView(script: script)
                }
            }
            .padding(.bottom, 20)
        }
    }

    // MARK: - Processing Status

    private var processingStatusView: some View {
        Group {
            switch viewModel.processingProgress {
            case .idle:
                EmptyView()

            case .parsing(let progress):
                progressCard(
                    icon: "doc.text.magnifyingglass",
                    title: "Analyzing Manga Page",
                    description: "Reading panels and extracting dialogue...",
                    progress: progress,
                    color: .blue
                )

            case .generating(let progress):
                progressCard(
                    icon: "waveform",
                    title: "Generating Voice Performance",
                    description: "Creating character voices...",
                    progress: progress,
                    color: .purple
                )

            case .loading:
                progressCard(
                    icon: "arrow.down.circle",
                    title: "Loading Audio",
                    description: "Preparing playback...",
                    progress: nil,
                    color: .green
                )

            case .ready:
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ready to Play")
                            .font(.headline)
                        Text("Tap play to start the performance")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)

            case .failed(let error):
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Processing Failed")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Retry") {
                        viewModel.processCurrentImage()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }

    private func progressCard(icon: String, title: String, description: String, progress: Double?, color: Color) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(color)
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if progress == nil {
                    ProgressView()
                }
            }

            if let progress = progress {
                VStack(spacing: 8) {
                    ProgressView(value: progress)
                        .tint(color)

                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - Transcript View

    private func transcriptView(script: MangaScript) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "text.bubble")
                    .foregroundStyle(.secondary)
                Text("Script")
                    .font(.headline)
                Spacer()
                Text("\(script.segments.count) segments")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            Divider()

            // Segments
            ForEach(script.segments) { segment in
                segmentRow(segment: segment, isPlaying: viewModel.isCurrentSegment(segment))
            }
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private func segmentRow(segment: ScriptSegment, isPlaying: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Indicator
            Circle()
                .fill(isPlaying ? Color.accentColor : Color.secondary.opacity(0.3))
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 6) {
                // Header
                HStack(spacing: 8) {
                    // Type badge
                    Text(segment.type.rawValue.capitalized)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(colorForSegmentType(segment.type))
                        .cornerRadius(4)

                    // Character name
                    if let character = segment.character {
                        Text(character.name)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }

                    // Emotion
                    if let emotion = segment.emotion {
                        Text("• \(emotion.rawValue)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                // Content
                Text(segment.content)
                    .font(.body)
                    .foregroundStyle(isPlaying ? .primary : .secondary)
            }
        }
        .padding()
        .background(isPlaying ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .padding(.horizontal)
    }

    private func colorForSegmentType(_ type: ScriptSegment.SegmentType) -> Color {
        switch type {
        case .dialogue: return .blue
        case .narration: return .purple
        case .soundEffect: return .orange
        case .action: return .green
        case .thought: return .cyan
        }
    }

    // MARK: - Playback Controls

    private var playbackControlsView: some View {
        VStack(spacing: 16) {
            // Timeline
            if case .playing(let currentTime) = viewModel.playbackState,
               let duration = viewModel.currentScript?.metadata.estimatedDuration {
                VStack(spacing: 8) {
                    Slider(value: .constant(currentTime), in: 0...duration)
                        .disabled(true)

                    HStack {
                        Text(formatTime(currentTime))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(formatTime(duration))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else if case .paused(let currentTime) = viewModel.playbackState,
                      let duration = viewModel.currentScript?.metadata.estimatedDuration {
                VStack(spacing: 8) {
                    Slider(value: .constant(currentTime), in: 0...duration)
                        .disabled(true)

                    HStack {
                        Text(formatTime(currentTime))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(formatTime(duration))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Control buttons
            HStack(spacing: 32) {
                // Process/Reprocess button
                Button {
                    viewModel.processCurrentImage()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .disabled(viewModel.isProcessing)

                Spacer()

                // Play/Pause button
                Button {
                    viewModel.togglePlayback()
                } label: {
                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(viewModel.canPlay ? .primary : .secondary)
                }
                .disabled(!viewModel.canPlay)

                Spacer()

                // Stop button
                Button {
                    viewModel.stop()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .disabled(!viewModel.canPlay)
            }
        }
    }

    // MARK: - Helpers

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - View Model

@MainActor
class MangaReaderViewModel: ObservableObject {
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var selectedImage: UIImage?
    @Published var processingProgress: ProcessingProgress = .idle
    @Published var playbackState: PlaybackState = .idle
    @Published var currentScript: MangaScript?
    @Published var currentSegment: ScriptSegment?
    @Published var showError = false
    @Published var errorMessage: String?

    private let performer = MangaScenePerformer()
    private var cancellables = Set<AnyCancellable>()

    var isProcessing: Bool {
        switch processingProgress {
        case .parsing, .generating, .loading:
            return true
        default:
            return false
        }
    }

    var isPlaying: Bool {
        if case .playing = playbackState {
            return true
        }
        return false
    }

    var canPlay: Bool {
        if case .ready = processingProgress {
            return true
        }
        if case .playing = playbackState {
            return true
        }
        if case .paused = playbackState {
            return true
        }
        return false
    }

    init() {
        setupObservers()
    }

    private func setupObservers() {
        // Observe photo selection
        $selectedPhotoItem
            .receive(on: DispatchQueue.main)
            .sink { [weak self] item in
                guard let item = item else { return }
                self?.loadImage(from: item)
            }
            .store(in: &cancellables)

        // Observe processing progress
        performer.progressPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.processingProgress = progress
            }
            .store(in: &cancellables)

        // Observe playback state
        performer.playbackStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.playbackState = state
                self?.updateCurrentSegment()
            }
            .store(in: &cancellables)
    }

    private func loadImage(from item: PhotosPickerItem) {
        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    throw NSError(domain: "ImageLoading", code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "Failed to load image"])
                }

                await MainActor.run {
                    self.selectedImage = image
                    self.currentScript = nil
                    self.processingProgress = .idle
                    self.playbackState = .idle
                }

                // Auto-process the image
                processCurrentImage()

            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }

    func processCurrentImage() {
        guard let image = selectedImage else { return }

        Task {
            do {
                let page = MangaPage(image: image)
                try await performer.processPage(page)

                await MainActor.run {
                    self.currentScript = performer.getCurrentScript()
                }

            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }

    func togglePlayback() {
        do {
            if isPlaying {
                performer.pause()
            } else {
                try performer.play()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func stop() {
        performer.stop()
    }

    func isCurrentSegment(_ segment: ScriptSegment) -> Bool {
        return currentSegment?.id == segment.id
    }

    private func updateCurrentSegment() {
        currentSegment = performer.getCurrentSegment()
    }
}

#Preview {
    ContentView()
}
