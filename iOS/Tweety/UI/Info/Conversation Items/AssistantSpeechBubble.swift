//
//  AssistantSpeechBubble.swift
//  Tweety
//
//  Created by Abdulaziz Albahar on 1/16/26.
//

import SwiftUI

struct AssistantSpeechBubble: View {
    let text: String
    let timestamp: Date

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(.grok)
                        .resizable()
                        .frame(width: 24, height: 24)
                    Text("Gerald")
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                Text(text)
                    .padding(12)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(16)

                Text(formatTime(timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            Spacer()
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
