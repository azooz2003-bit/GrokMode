//
//  PendingToolCall.swift
//  Tweety
//
//  Created by Abdulaziz Albahar on 12/14/25.
//

import Foundation

struct PendingToolCall: Identifiable {
    let id: String
    let functionName: String
    let arguments: String
    let previewTitle: String
    let previewContent: String
    let itemId: String?

    var actionIcon: String {
        XAPIEndpoint(rawValue: functionName)?.actionIcon ?? "hand.raised.fill"
    }
}
