//
//  ConversationItemType.swift
//  GrokMode
//
//  Created by Abdulaziz Albahar on 12/14/25.
//

import Foundation

enum ConversationItemType {
    case userSpeech(transcript: String)
    case assistantSpeech(text: String)
    case tweet(XTweet, author: XUser?, media: [XMedia], retweeter: XUser?, retweetId: String?, quotedTweet: QuotedTweetInfo?)
    case toolCall(name: String, status: ToolCallStatus)
    case systemMessage(String)
}

struct QuotedTweetInfo {
    let author: XUser
    let text: String
    let media: [XMedia]
}
