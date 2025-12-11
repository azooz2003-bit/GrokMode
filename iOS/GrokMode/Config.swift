//
//  Config.swift
//  GrokMode
//
//  Created by Matt Steele on 12/7/25.
//

import Foundation

nonisolated
enum Config {
    static let xApiKey = {
        guard let apiKey = Bundle.main.infoDictionary?["X_API_KEY"] as? String else {
            fatalError()
        }
        return apiKey
    }()
    
    static let xAiApiKey = {
        guard let apiKey = Bundle.main.infoDictionary?["X_AI_API_KEY"] as? String else {
            fatalError()
        }
        return apiKey
    }()

    static let baseXProxyURL = {
        guard let url = Bundle.main.infoDictionary?["BASE_X_PROXY_URL"] as? String else {
            fatalError()
        }
        return URL(string: url)!
    }()

    static let baseXAIProxyURL = {
        guard let url = Bundle.main.infoDictionary?["BASE_XAI_PROXY_URL"] as? String else {
            fatalError()
        }
        return URL(string: url)!
    }()

    static let baseXAIURL = URL(string: "https://api.x.ai/v1/")!

    static let appSecret = "34FxRVXGLo3hSikbYhH7a5n7JKHGSghaLrlddbD0/l8=" // TODO: remove
}
