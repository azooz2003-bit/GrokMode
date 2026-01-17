//
//  ConversationItemView.swift
//  Tweety
//
//  Created by Abdulaziz Albahar on 12/7/25.
//

import SwiftUI

struct ConversationItemView: View {
    let item: ConversationItem
    let imageCache: ImageCache

    var body: some View {
        Group {
            switch item.type {
            case .userSpeech(let transcript):
                UserSpeechBubble(transcript: transcript, timestamp: item.timestamp)

            case .assistantSpeech(let text):
                AssistantSpeechBubble(text: text, timestamp: item.timestamp)

            case .tweet(let enrichedTweet):
                TweetConversationCard(enrichedTweet: enrichedTweet, imageCache: imageCache)

            case .tweets(let tweets):
                TweetsBatchPreview(tweets: tweets, imageCache: imageCache)

            case .toolCall(let name, let status):
                ToolCallIndicator(toolName: name, status: status, timestamp: item.timestamp)

            case .systemMessage(let message):
                SystemMessageBubble(message: message, timestamp: item.timestamp)
            }
        }
    }
}

#Preview {
    let imageCache = ImageCache()
    VStack(spacing: 20) {
        ConversationItemView(item: ConversationItem(
            timestamp: Date(),
            type: .systemMessage("Connected to XAI Voice")
        ), imageCache: imageCache)

        ConversationItemView(item: ConversationItem(
            timestamp: Date(),
            type: .toolCall(name: "search_recent_tweets", status: .pending)
        ), imageCache: imageCache)

        ConversationItemView(item: ConversationItem(
            timestamp: Date(),
            type: .tweet(
                EnrichedTweet(
                    from: XTweet(
                        id: "1",
                        text: "This is a test tweet https://t.co/abc123",
                        author_id: "1",
                        created_at: nil,
                        attachments: nil,
                        public_metrics: XTweet.PublicMetrics(
                            retweet_count: 100,
                            reply_count: 50,
                            like_count: 500,
                            quote_count: 20,
                            impression_count: 10000,
                            bookmark_count: 30
                        ),
                        referenced_tweets: nil
                    ),
                    includes: XTweetResponse.Includes(
                        users: [XUser(id: "1", name: "Test User", username: "testuser", profile_image_url: nil)],
                        media: nil,
                        tweets: nil
                    )
                )
            )
        ), imageCache: imageCache)
    }
}


#Preview("Fetched post preview") {
    VStack {
        Button {
            print("Submitted")
        } label: {
            ConversationItemView(item: .init(timestamp: .now, type: .tweets([
                EnrichedTweet(
                    from: XTweet(
                        id: "1",
                        text: "This is a test tweet https://t.co/abc123",
                        author_id: "1",
                        created_at: nil,
                        attachments: nil,
                        public_metrics: XTweet.PublicMetrics(
                            retweet_count: 100,
                            reply_count: 50,
                            like_count: 500,
                            quote_count: 20,
                            impression_count: 10000,
                            bookmark_count: 30
                        ),
                        referenced_tweets: nil
                    ),
                    includes: XTweetResponse.Includes(
                        users: [XUser(id: "1", name: "Test User", username: "testuser", profile_image_url: nil)],
                        media: nil,
                        tweets: nil
                    )
                )
            ])), imageCache: .init())
        }
        .buttonStyle(.plain)
        .padding()
    }
}
