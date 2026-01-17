//
//  UserSpeechBubble.swift
//  Tweety
//
//  Created by Abdulaziz Albahar on 1/16/26.
//

import SwiftUI

struct UserSpeechBubble: View {
    let transcript: String
    let timestamp: Date

    var body: some View {
        HStack {
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(transcript)
                    .padding(12)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(16)

                Text(formatTime(timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
