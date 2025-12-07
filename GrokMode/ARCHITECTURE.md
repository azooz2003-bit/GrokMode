# GrokMode Architecture

## Overview

GrokMode is a manga-to-audio performance app that transforms manga pages into dramatic voice acted scenes. The architecture is built with three decoupled layers that can be composed together.

## Architecture Diagram

```
┌─────────────┐
│ Manga Page  │ (UIImage)
└──────┬──────┘
       │
       ▼
┌─────────────────────────────┐
│   Layer 1: MangaParser      │
│   (Image → Structured Text)  │
└──────────┬──────────────────┘
           │ MangaScript
           ▼
┌─────────────────────────────┐
│  Layer 2: VoicePerformer    │
│  (Text → Audio Performance) │
└──────────┬──────────────────┘
           │ AudioPerformance
           ▼
┌─────────────────────────────┐
│   Layer 3: AudioPlayer      │
│   (Audio → Playback)        │
└─────────────────────────────┘
```

## Core Components

### 1. Data Models (`Models/MangaScript.swift`)

**MangaPage**
- Input: UIImage of manga page
- Metadata: page number (optional)

**MangaScript**
- Structured representation of manga content
- Contains: segments, characters, metadata
- Output from parsing, input to voice generation

**ScriptSegment**
- Individual pieces of script (dialogue, narration, sound effects)
- Includes: type, content, character, emotion, timing

**Character**
- Character definition with personality traits
- Voice characteristics (pitch, speed, emphasis)

**AudioPerformance**
- Generated audio with metadata
- Contains: audio data, format, duration, segment timings

**PlaybackState**
- Enum representing current playback status
- States: idle, loading, ready, playing, paused, completed, failed

### 2. Layer 1: Image-to-Text (`Services/MangaParser.swift`)

**Protocol: MangaParser**
```swift
protocol MangaParser {
    func parse(_ page: MangaPage) async throws -> MangaScript
    func cancelParsing()
}
```

**Implementation: GrokMangaParser**
- Uses Grok Vision API (`grok-4-0709`) to analyze manga pages
- Uses structured output API with JSON schema for guaranteed valid responses
- Extracts dialogue, sound effects, character personalities
- Returns structured MangaScript with timing information

**Features:**
- Right-to-left panel reading (manga style)
- Character personality inference
- Emotion detection from facial expressions
- Sound effect capture with emphasis
- Automatic voice characteristic assignment

### 3. Layer 2: Text-to-Speech (`Services/VoicePerformer.swift`)

**Class: VoicePerformer**
```swift
class VoicePerformer {
    func perform(_ script: MangaScript) async throws -> AudioPerformance
    func cancelPerformance()
}
```

**Implementation:**
- Uses Grok TTS API (`https://api.x.ai/v1/audio/speech`)
- Generates expressive voice performances with 6 distinct voices
- Automatically selects appropriate voice based on character personality
- Handles pauses and timing between segments

**Features:**
- **Voice Selection:** Automatically maps character personalities to 6 voices:
  - Ara (Female) - Warm, balanced - Default/Narrator
  - Rex (Male) - Professional, clear - Serious characters
  - Sal (Neutral) - Versatile - Actions
  - Eve (Female) - Energetic, enthusiastic - Playful/energetic characters
  - Una (Female) - Calm, measured - Timid/calm characters
  - Leo (Male) - Authoritative, commanding - Domineering characters
- Emotion-aware voice selection
- Segment-by-segment generation with timing
- Automatic silence insertion for pauses
- WAV format from API (PCM extracted for concatenation)
- Exponential backoff retry logic for rate limits and server errors

### 4. Layer 3: Audio Playback (`Services/AudioPlayer.swift`)

**Class: AudioPlayer**
```swift
class AudioPlayer {
    var playbackState: PlaybackState { get }
    var playbackStatePublisher: AnyPublisher<PlaybackState, Never> { get }

    func load(_ performance: AudioPerformance) async throws
    func play() throws
    func pause()
    func stop()
    func seek(to time: TimeInterval) throws
}
```

**Implementation:**
- Uses AVFoundation for high-quality playback
- Converts PCM data to WAV format
- Provides real-time playback state updates
- Supports seeking and segment navigation

**Features:**
- Segment-aware playback
- Real-time state updates via Combine
- Seek to specific segments
- Automatic cleanup of temporary files

### 5. Coordinator (`Services/MangaScenePerformer.swift`)

**Class: MangaScenePerformer**
- Orchestrates the complete pipeline
- Creates and manages all three layers internally
- Sequential processing: parse → perform → load
- Progress tracking with Combine publishers
- Error handling and recovery

## Usage Examples

### Basic Usage

```swift
import UIKit

// Initialize (API key loaded from Config)
let performer = MangaScenePerformer()

// Observe state
performer.progressPublisher
    .sink { progress in
        print("Progress: \(progress.description)")
    }
    .store(in: &cancellables)

performer.playbackStatePublisher
    .sink { state in
        print("Playback: \(state)")
    }
    .store(in: &cancellables)

// Process a manga page
let image = UIImage(named: "manga_page")!
let page = MangaPage(image: image, pageNumber: 1)

Task {
    do {
        // This runs the entire pipeline
        try await performer.processPage(page)

        // Now ready to play
        try performer.play()
    } catch {
        print("Error: \(error)")
    }
}
```

### Direct Layer Usage

```swift
// Use layers independently

// Layer 1: Parse only
let parser = GrokMangaParser()
let script = try await parser.parse(page)
print("Found \(script.segments.count) segments")

// Layer 2: Generate audio from existing script
let performer = GrokVoicePerformer()
let audio = try await performer.perform(script)
print("Generated \(audio.duration)s of audio")

// Layer 3: Play pre-generated audio
let player = AVAudioPerformancePlayer()
try await player.load(audio)
try player.play()
```

### Segment Navigation

```swift
// Get current segment while playing
if let segment = performer.getCurrentSegment() {
    print("Currently playing: \(segment.content)")
    if let character = segment.character {
        print("Character: \(character.name)")
    }
}

// Seek to specific segment
if let script = performer.getCurrentScript(),
   let firstDialogue = script.segments.first(where: { $0.type == .dialogue }) {
    try (performer.player as? AVAudioPerformancePlayer)?.seek(to: firstDialogue)
}
```

## Design Principles

### 1. Separation of Concerns
- Each layer has a single, well-defined responsibility
- Layers communicate through well-defined data models
- Simple, direct class implementations

### 2. Async/Await
- Modern concurrency with structured tasks
- Proper cancellation support
- Clean error propagation

### 3. Reactive State Management
- Combine publishers for state changes
- Real-time progress updates
- Decoupled UI from business logic

## Error Handling

Each layer defines its own error types:

- `MangaParserError`: Parsing failures, API errors
- `VoicePerformerError`: Generation failures, audio processing
- `AudioPlayerError`: Playback failures, audio session issues

Errors propagate up through async/await and can be caught at the coordinator level.

## Testing Strategy

- Test real API calls with small test images
- Verify audio generation quality
- Test playback accuracy
- Test each layer independently

## Performance Considerations

1. **Memory Management**
   - Temporary audio files are automatically cleaned up
   - Large images are compressed before sending to API
   - Audio data is streamed, not loaded entirely in memory

2. **Cancellation**
   - All async operations support cancellation
   - WebSocket connections properly closed
   - Tasks cleaned up on cancellation

3. **Caching**
   - Consider caching parsed scripts
   - Consider caching generated audio performances
   - Implement in a service layer above the coordinator

## Future Extensions

Potential enhancements while maintaining architecture:

1. **Multi-page Support**: Batch processing of manga chapters
2. **Voice Customization**: User-selectable voice profiles per character
3. **Offline Mode**: Cache and replay previous performances
4. **Export**: Save performances as audio files
5. **Live Editing**: Modify scripts before voice generation
6. **Background Processing**: Process pages while user browses

## File Structure

```
GrokMode/
├── Models/
│   └── MangaScript.swift          # All data models
├── Services/
│   ├── MangaParser.swift          # Layer 1: Image → Text
│   ├── VoicePerformer.swift       # Layer 2: Text → Audio
│   ├── AudioPlayer.swift          # Layer 3: Audio → Playback
│   └── MangaScenePerformer.swift  # Coordinator
└── ARCHITECTURE.md                # This file
```

## API Requirements

### Grok Vision API
- Endpoint: `https://api.x.ai/v1/chat/completions`
- Model: `grok-4-0709`
- Features: Image analysis with structured output API
- Response Format: Uses `response_format` with `json_schema` for guaranteed valid JSON

### Grok TTS API
- Endpoint: `https://api.x.ai/v1/audio/speech`
- Format: REST API with JSON request/response
- Capabilities: High-quality text-to-speech with 6 voice options
- Audio Formats: MP3, WAV, Opus, FLAC
- Sample Rate: 24kHz
- Used Format: WAV (PCM extracted for concatenation)

## Configuration

The app uses `APIConfig.swift` to load API keys from Info.plist.

Add your API key to `Info.plist`:
```xml
<key>X_AI_API_KEY</key>
<string>xai-your-api-key-here</string>
```

Or configure via `Secrets.xcconfig`:
```
X_AI_API_KEY = xai-your-api-key-here
```

Access in code via `APIConfig.xAiApiKey`:
```swift
let performer = MangaScenePerformer() // Uses APIConfig.xAiApiKey
```
