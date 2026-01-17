//
//  TweetConversationCard.swift
//  Tweety
//
//  Created by Abdulaziz Albahar on 1/16/26.
//

import SwiftUI
internal import os

struct TweetConversationCard: View {
    let enrichedTweet: EnrichedTweet
    let imageCache: ImageCache

    var body: some View {
        PrimaryContentBlock(
            profileImageUrl: enrichedTweet.author?.profile_image_url,
            displayName: enrichedTweet.author?.name ?? "Unknown",
            username: enrichedTweet.author?.username ?? "unknown",
            text: enrichedTweet.displayText,
            media: enrichedTweet.media.isEmpty ? nil : enrichedTweet.media,
            metrics: tweetMetrics,
            tweetUrl: tweetUrl,
            retweeterName: enrichedTweet.retweetInfo?.retweeter.name,
            quotedTweet: quotedTweetData,
            imageCache: imageCache
        )
        .listRowSeparator(.hidden)
        .padding(.vertical, 4)
    }

    private var quotedTweetData: PrimaryContentBlock.QuotedTweetData? {
        guard let quotedTweet = enrichedTweet.quotedTweet else { return nil }
        return PrimaryContentBlock.QuotedTweetData(
            authorName: quotedTweet.author.name,
            authorUsername: quotedTweet.author.username,
            text: quotedTweet.text,
            media: quotedTweet.media.isEmpty ? nil : quotedTweet.media
        )
    }

    private var tweetMetrics: TweetMetrics? {
        #if DEBUG
        AppLogger.ui.debug("===== UI: RENDERING TWEET =====")
        AppLogger.ui.debug("Tweet ID: \(enrichedTweet.tweet.id)")
        AppLogger.ui.debug("Tweet Text: \(String(enrichedTweet.displayText.prefix(50)))...")
        AppLogger.ui.debug("Author: \(enrichedTweet.author?.username ?? "nil")")
        AppLogger.ui.debug("Profile Image URL: \(enrichedTweet.author?.profile_image_url ?? "NIL")")
        AppLogger.ui.debug("Media URLs: \(enrichedTweet.media.count)")
        AppLogger.ui.debug("Public Metrics Object: \(enrichedTweet.tweet.public_metrics != nil ? "EXISTS" : "NIL")")
        #endif

        guard let publicMetrics = enrichedTweet.tweet.public_metrics else {
            #if DEBUG
            AppLogger.ui.debug("✗ NO METRICS - Will not display engagement stats")
            #endif
            return nil
        }

        let metrics = TweetMetrics(
            likes: publicMetrics.like_count ?? 0,
            retweets: publicMetrics.retweet_count ?? 0,
            views: publicMetrics.impression_count ?? 0
        )

        #if DEBUG
        AppLogger.ui.debug("✓ Metrics Created:")
        AppLogger.ui.debug("  - Likes: \(metrics.likes)")
        AppLogger.ui.debug("  - Retweets: \(metrics.retweets)")
        AppLogger.ui.debug("  - Views: \(metrics.views)")
        #endif

        return metrics
    }

    private var tweetUrl: String? {
        if let retweetInfo = enrichedTweet.retweetInfo {
            let url = "https://twitter.com/\(retweetInfo.retweeter.username)/status/\(retweetInfo.retweetId)"
            #if DEBUG
            AppLogger.ui.debug("✓ Retweet URL: \(url)")
            #endif
            return url
        }

        guard let username = enrichedTweet.author?.username else {
            #if DEBUG
            AppLogger.ui.debug("✗ Cannot create URL - no author username")
            #endif
            return nil
        }
        let url = "https://twitter.com/\(username)/status/\(enrichedTweet.tweet.id)"
        #if DEBUG
        AppLogger.ui.debug("✓ Tweet URL: \(url)")
        #endif
        return url
    }
}
