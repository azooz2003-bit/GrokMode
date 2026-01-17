//
//  SystemMessageBubble.swift
//  Tweety
//
//  Created by Abdulaziz Albahar on 1/16/26.
//

import SwiftUI

struct SystemMessageBubble: View {
    let message: String
    let timestamp: Date

    var body: some View {
        HStack {
            Spacer()

            Text(message)
                .font(.caption)
                .foregroundColor(.gray)
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

            Spacer()
        }
        .padding(.horizontal)
    }
}
