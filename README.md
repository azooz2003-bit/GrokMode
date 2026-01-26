# Tweety

X (Twitter) voice assistant app for iOS with real-time voice chat.

## Important Note

**`GoogleService-Info.plist` is not included in this repository.** This file contains Firebase project credentials and is excluded for security reasons. If you wish to build and run this project, you will need to:

1. Create your own Firebase project at [Firebase Console](https://console.firebase.google.com)
2. Download your own `GoogleService-Info.plist`
3. Place it in `iOS/Tweety/`

Alternatively, contact the repository owner for permission to use the existing Firebase project.

## Project Structure

- **`iOS/Tweety/Audio/`** - Audio streaming and voice activity detection (VAD)
- **`iOS/Tweety/Voice Service/`** - Grok and OpenAI voice service integration
- **`iOS/Tweety/X/`** - X API client, tool definitions and orchestration
- **`iOS/Tweety/UI/`** - SwiftUI views: voice assistant, authentication, settings, conversation history
- **`iOS/Tweety/Authentication/`** - X OAuth2, App Attest, keychain
- **`iOS/Tweety/Store/`** - In-app purchases, StoreKit, credits management
- **`iOS/Tweety/Usage/`** - Usage tracking and cost analytics
- **`Server/tweety-server/`** - Cloudflare Worker for API key handling, OAuth2, and credit tracking
