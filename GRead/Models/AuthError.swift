//
//  AuthError.swift
//  GRead
//
//  Created by apple on 11/6/25.
//

import Foundation


enum AuthError: LocalizedError {
    case invalidCredentials
    case invalidResponse
    case unauthorized
    case httpError(Int)
    case networkError
    case registrationFailed(String)
    case userNotFound

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid username or password format"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Invalid username or password"
        case .httpError(let code):
            return "Server error: \(code)"
        case .networkError:
            return "Network error. Please check your connection."
        case .registrationFailed(let message):
            return message
        case .userNotFound:
            return "User not found. Please register first."
        }
    }
}

struct RegistrationErrorResponse: Decodable {
    let message: String?
}

struct AppleAuthErrorResponse: Decodable {
    let message: String?
    let code: String?
}

struct AppleAuthResponse: Decodable {
    let success: Bool
    let message: String?
    let userId: Int?
    let username: String?
    let email: String?
    let token: String
    let displayName: String?

    enum CodingKeys: String, CodingKey {
        case success, message, username, email, token
        case userId = "user_id"
        case displayName = "display_name"
    }
}
