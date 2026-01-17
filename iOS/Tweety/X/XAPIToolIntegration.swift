//
//  XAPIToolIntegration.swift
//  Tweety
//
//  Created by Abdulaziz Albahar on 1/16/26.
//

import Foundation
import JSONSchema

struct XAPIToolIntegration {

    static var endpoints: [XAPIEndpoint] {
        var all = XAPIEndpoint.allCases
        all.removeAll(where: { $0 == .searchAllTweets})
        // Exclude Community Notes tools
        all.removeAll(where: {
            switch $0 {
            case .createNote, .deleteNote, .evaluateNote, .getNotesWritten, .getPostsEligibleForNotes:
                return true
            default:
                return false
            }
        })
        // Exclude Media tools
        all.removeAll(where: {
            switch $0 {
            case .uploadMedia, .getMediaStatus, .initializeChunkedUpload, .appendChunkedUpload,
                 .finalizeChunkedUpload, .createMediaMetadata, .getMediaAnalytics:
                return true
            default:
                return false
            }
        })
        return all
    }

    static func getToolDefinitions() -> [VoiceToolDefinition] {
        endpoints.map { endpoint in
            let parametersDict: [String: Any]
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(endpoint.jsonSchema)
                if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    parametersDict = dict
                } else {
                    parametersDict = ["type": "object", "properties": [:]]
                }
            } catch {
                parametersDict = ["type": "object", "properties": [:]]
            }

            return VoiceToolDefinition(
                type: "function",
                name: endpoint.rawValue,
                description: endpoint.description,
                parameters: parametersDict
            )
        }
    }
}
