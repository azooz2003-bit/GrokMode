//
//  APIConfig.swift
//  GrokMode
//
//  Created by Abdulaziz Albahar on 12/6/25.
//

import Foundation

enum APIConfig {
    static let xApiKey: String = {
        guard let apiKey = Bundle.main.infoDictionary?["X_API_KEY"] as? String else {
            fatalError("API Key not found in Info.plist")
        }
        return apiKey
    }()

    static let xAiApiKey: String = {
        guard let apiKey = Bundle.main.infoDictionary?["X_AI_API_KEY"] as? String else {
            fatalError("API Key not found in Info.plist")
        }
        print(apiKey)
        return apiKey
    }()

    static let xBaseURL = "https://api.x.com"
}
