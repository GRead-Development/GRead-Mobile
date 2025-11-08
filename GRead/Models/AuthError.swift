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
        }
    }
}

struct RegistrationErrorResponse: Decodable {
    let message: String?
}
