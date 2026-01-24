//
//  XAPIUsageDetails.swift
//  Tweety
//
//  Created by Abdulaziz Albahar on 12/28/25.
//

import Foundation

nonisolated
struct XAPIUsageDetails: Codable {
    let postsRead: Int?
    let usersRead: Int?
    let dmEventsRead: Int?
    let contentCreates: Int?
    let dmInteractionCreates: Int?
    let userInteractionCreates: Int?
}
