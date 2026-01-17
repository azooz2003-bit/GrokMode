//
//  XAPICallResult.swift
//  Tweety
//
//  Created by Abdulaziz Albahar on 1/16/26.
//

import Foundation

nonisolated
enum XAPICallErrorType: String, Codable {
    case missingParam = "MISSING_PARAM"
    case invalidResponse = "INVALID_RESPONSE"
    case unauthorized = "UNAUTHORIZED"
    case authRequired = "AUTH_REQUIRED"
    case usageTrackingFailed = "USAGE_TRACKING_FAILED"
    case insufficientCredits = "INSUFFICIENT_CREDITS"
    case httpError = "HTTP_ERROR"
    case requestFailed = "REQUEST_FAILED"
    case invalidURL = "INVALID_URL"
    case notImplemented = "NOT_IMPLEMENTED"
}

nonisolated
struct XAPICallError: Codable, Error {
    let code: XAPICallErrorType
    let message: String
    let details: [String: String]?

    init(code: XAPICallErrorType, message: String, details: [String: String]? = nil) {
        self.code = code
        self.message = message
        self.details = details
    }
}

nonisolated
struct XAPICallResult: Codable {
    let id: String?
    let toolName: String
    let success: Bool
    let response: String?  // JSON string - ready for LLM
    let error: XAPICallError?
    let statusCode: Int?

    init(id: String? = nil, toolName: String, success: Bool, response: String? = nil, error: XAPICallError? = nil, statusCode: Int? = nil) {
        self.id = id
        self.toolName = toolName
        self.success = success
        self.response = response
        self.error = error
        self.statusCode = statusCode
    }

    static func success(id: String? = nil, toolName: String, response: String?, statusCode: Int) -> XAPICallResult {
        XAPICallResult(id: id, toolName: toolName, success: true, response: response, error: nil, statusCode: statusCode)
    }

    static func failure(id: String? = nil, toolName: String, error: XAPICallError, statusCode: Int?) -> XAPICallResult {
        XAPICallResult(id: id, toolName: toolName, success: false, response: nil, error: error, statusCode: statusCode)
    }
}
