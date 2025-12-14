//
//  AuthToken.swift
//  LightGallery
//
//  Created by Kiro on 2025-12-06.
//

import Foundation

struct AuthToken: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let tokenType: String
    
    init(
        accessToken: String,
        refreshToken: String,
        expiresAt: Date,
        tokenType: String = "Bearer"
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
        self.tokenType = tokenType
    }
    
    var isExpired: Bool {
        return Date() >= expiresAt
    }
}
