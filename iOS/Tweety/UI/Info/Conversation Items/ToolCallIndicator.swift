//
//  ToolCallIndicator.swift
//  Tweety
//
//  Created by Abdulaziz Albahar on 1/16/26.
//

import SwiftUI

struct ToolCallIndicator: View {
    let toolName: String
    let status: ToolCallStatus
    let timestamp: Date

    var body: some View {
        HStack(spacing: 8) {
            statusIcon

            VStack(alignment: .leading, spacing: 2) {
                Text(formattedToolName)
                    .font(.caption)
                    .fontWeight(.medium)

                Text(statusText)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            Spacer()

            Text(formatTime(timestamp))
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(8)
        .background(statusColor.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }

    private var formattedToolName: String {
        if let tool = Tool(rawValue: toolName) {
            return tool.displayName
        }
        return toolName
            .split(separator: "_")
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    private var statusIcon: some View {
        Group {
            switch status {
            case .pending:
                Image(systemName: "clock.fill")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(.blue)
                    .scaleEffect(0.7)
            case .approved:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .rejected:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            case .executed(let success):
                Image(systemName: success ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundColor(success ? .green : .orange)
            }
        }
    }

    private var statusText: String {
        switch status {
        case .pending: return "Awaiting approval"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        case .executed(let success): return success ? "Completed" : "Failed"
        }
    }

    private var statusColor: Color {
        switch status {
        case .pending: return .blue
        case .approved: return .green
        case .rejected: return .red
        case .executed(let success): return success ? .green : .orange
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
