//
//  CompactQuotedTweetView.swift
//  Tweety
//
//  Created by Abdulaziz Albahar on 1/16/26.
//

import SwiftUI

struct CompactQuotedTweetView: View {
    let authorName: String
    let authorUsername: String
    let text: String
    let media: [XMedia]?
    let imageCache: ImageCache

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text(authorName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                Text("@\(authorUsername)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
            if let media = media, let firstMedia = media.first, let urlString = firstMedia.displayUrl, let url = URL(string: urlString) {
                CachedAsyncImage(url: url, imageCache: imageCache) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: 120)
                        .clipped()
                        .cornerRadius(8)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(maxWidth: .infinity, maxHeight: 120)
                        .overlay { ProgressView() }
                } errorPlaceholder: { error in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(maxWidth: .infinity, maxHeight: 120)
                        .overlay {
                            VStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.red.opacity(0.8))
                                Text(error.localizedDescription.prefix(30))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview("Default States") {
    let imageCache = ImageCache()
    ZStack {
        Color(.systemBackground).ignoresSafeArea()
        ScrollView{
            VStack(spacing: 24){
                Spacer()

                PrimaryContentBlock(
                    profileImageUrl: nil,
                    displayName: "Elon Musk",
                    username: "elonmusk",
                    text: "Just had a great conversation about the future of AI and space exploration. The possibilities are endless when you combine these technologies!",
                    media: nil,
                    metrics: TweetMetrics(likes: 12500, retweets: 3400, views: 150000),
                    tweetUrl: "https://twitter.com/elonmusk/status/1234567890",
                    retweeterName: nil,
                    quotedTweet: nil,
                    imageCache: imageCache
                )


                PrimaryContentBlock(
                    profileImageUrl: nil,
                    displayName: "Elon Musk",
                    username: "elonmusk",
                    text: "Just had a great conversation about the future of AI and space exploration. The possibilities are endless when you combine these technologies!",
                    media: nil,
                    metrics: TweetMetrics(likes: 12500, retweets: 3400, views: 150000),
                    tweetUrl: "https://twitter.com/elonmusk/status/1234567890",
                    retweeterName: "John Doe",
                    quotedTweet: nil,
                    imageCache: imageCache
                )




                PrimaryContentBlock(
                    profileImageUrl: nil,
                    displayName: "Elon Musk",
                    username: "elonmusk",
                    text: "Just had a great conversation about the future of AI and space exploration. The possibilities are endless when you combine these technologies! Just had a great conversation about the future of AI. Just had a great conversation about the future of AI",
                    media: nil,
                    metrics: TweetMetrics(likes: 12500, retweets: 3400, views: 150000),
                    tweetUrl: "https://twitter.com/elonmusk/status/1234567890",
                    retweeterName: nil,
                    quotedTweet: nil,
                    imageCache: imageCache
                )


                Spacer()
            }}
    }
}
