//
//  User.swift
//  Declutter
//
//  Created by Kiro on 2025-12-06.
//

import Foundation

struct User: Codable, Identifiable {
    let id: String
    var displayName: String
    var email: String?
    var avatarURL: URL?
    var authProvider: AuthProvider
    var createdAt: Date
    var lastLoginAt: Date
    
    init(
        id: String = UUID().uuidString,
        displayName: String,
        email: String? = nil,
        avatarURL: URL? = nil,
        authProvider: AuthProvider,
        createdAt: Date = Date(),
        lastLoginAt: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.avatarURL = avatarURL
        self.authProvider = authProvider
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
    }
}
