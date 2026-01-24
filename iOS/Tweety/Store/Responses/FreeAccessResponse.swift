//
//  FreeAccessResponse.swift
//  Tweety
//
//  Created by Abdulaziz Albahar on 12/28/25.
//

import Foundation

nonisolated
struct FreeAccessResponse: Decodable {
    let success: Bool
    let userId: String
    let hasFreeAccess: Bool
}
