import SwiftUI
import Foundation
import Combine
import AuthenticationServices

// MARK: - Auth Manager with JWT
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isGuestMode = false
    @Published var needsUsernameSelection = false
    @Published var suggestedUsername: String?
    var jwtToken: String?
    var pendingAppleUserData: [String: Any]?

    init() {
        loadAuthState()
    }
    
    func login(username: String, password: String) async throws {
        // JWT Authentication endpoint
        guard let url = URL(string: "https://gread.fun/wp-json/jwt-auth/v1/token") else {
            throw AuthError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "username": username,
            "password": password
        ]
        
        request.httpBody = try JSONEncoder().encode(body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }
            
            // Log response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                Logger.debug("JWT Response: \(responseString)")
            }

            // First, check if response is an error response (has a code field)
            if let errorResponse = try? JSONDecoder().decode(JWTErrorResponse.self, from: data),
               errorResponse.code != nil {
                Logger.warning("JWT Error detected: \(errorResponse.message ?? "Unknown error")")
                // Show user-friendly message for all registration/account issues
                throw AuthError.registrationFailed("If you are a new user and your username is unique, check your email and verify your account.")
            }

            if httpResponse.statusCode == 403 || httpResponse.statusCode == 401 {
                // Try to parse error message from server
                if let errorResponse = try? JSONDecoder().decode(JWTErrorResponse.self, from: data),
                   let message = errorResponse.message {
                    Logger.warning("JWT Error: \(message)")
                    throw AuthError.registrationFailed("If you are a new user and your username is unique, check your email and verify your account.")
                }
                throw AuthError.unauthorized
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                Logger.error("JWT Auth failed with status: \(httpResponse.statusCode)")
                throw AuthError.httpError(httpResponse.statusCode)
            }

            // Parse JWT response
            let jwtResponse = try JSONDecoder().decode(JWTResponse.self, from: data)
            
            // Store JWT token
            self.jwtToken = jwtResponse.token
            
            // Fetch current user from BuddyPress
            try await fetchCurrentUser()
            
            await MainActor.run {
                self.isAuthenticated = true
                self.isGuestMode = false
                saveAuthState()
            }
        } catch let error as AuthError {
            throw error
        } catch {
            Logger.error("Login error: \(error)")
            throw AuthError.networkError
        }
    }
    
    func register(username: String, email: String, password: String) async throws {
        // BuddyPress signup endpoint
        guard let url = URL(string: "https://gread.fun/wp-json/buddypress/v1/signup") else {
            throw AuthError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "user_login": username,
            "user_email": email,
            "password": password,
            "signup_field_data": [
                [
                    "field_id": 1,
                    "value": username
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }

            // Log response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                Logger.debug("Registration Response: \(responseString)")
            }

            if httpResponse.statusCode == 400 || httpResponse.statusCode == 409 {
                // Try to parse error message from response in multiple formats
                var errorMessage: String?

                // Try WordPress error response format
                if let errorResponse = try? JSONDecoder().decode(RegistrationErrorResponse.self, from: data) {
                    errorMessage = errorResponse.message
                }

                // Try parsing as generic dictionary for WordPress error format
                if errorMessage == nil, let jsonDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let message = jsonDict["message"] as? String {
                        errorMessage = message
                    } else if let data = jsonDict["data"] as? [String: Any], let message = data["message"] as? String {
                        errorMessage = message
                    } else if let errors = jsonDict["errors"] as? [String: Any], let errorDetail = errors.first?.value as? [String: Any], let message = errorDetail["message"] as? String {
                        errorMessage = message
                    }
                }

                if let errorMessage = errorMessage {
                    let lowercasedError = errorMessage.lowercased()
                    
                    if lowercasedError.contains("email is already registered") || lowercasedError.contains("email address is already in use") || lowercasedError.contains("Sorry, that email address is already used!") {
                        throw AuthError.registrationFailed("This email address is already registered.")
                    }
                    
                    if lowercasedError.contains("sorry, that username already exists") || lowercasedError.contains("username is already in use") {
                        throw AuthError.registrationFailed("This username is already taken. Please choose another.")
                    }
                }
                throw AuthError.registrationFailed("Registration failed. Please check your information.")
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                Logger.error("Registration failed with status: \(httpResponse.statusCode)")
                throw AuthError.registrationFailed("Registration failed. Please try again.")
            }

            // After successful registration, try to auto-login
            // If account needs activation, this will throw an error which we'll catch
            do {
                try await login(username: username, password: password)
            } catch let error as AuthError {
                // Check if the error is about account not being activated
                if case .unauthorized = error {
                    // Account created but needs email activation
                    throw AuthError.registrationFailed("Account created! Please check your email to activate your account before logging in.")
                }
                throw error
            }
        } catch let error as AuthError {
            throw error
        } catch {
            Logger.error("Registration error: \(error)")
            throw AuthError.networkError
        }
    }

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        // Extract user information from Apple credential
        let userIdentifier = credential.user
        let email = credential.email
        let fullName = credential.fullName

        // Create the identity token string
        guard let identityTokenData = credential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            throw AuthError.invalidResponse
        }

        // Send to WordPress backend for verification and user creation/login
        guard let url = URL(string: "https://gread.fun/wp-json/custom/v1/apple-login") else {
            throw AuthError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "identity_token": identityToken,
            "user_identifier": userIdentifier
        ]

        // Include email and name if this is the first sign-in (Apple only provides these once)
        if let email = email {
            body["email"] = email
        }

        if let fullName = fullName {
            var nameComponents: [String: String] = [:]
            if let givenName = fullName.givenName {
                nameComponents["given_name"] = givenName
            }
            if let familyName = fullName.familyName {
                nameComponents["family_name"] = familyName
            }
            if !nameComponents.isEmpty {
                body["full_name"] = nameComponents
            }
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }

            // Log response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                Logger.debug("Apple Login Response: \(responseString)")
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                Logger.error("Apple Login failed with status: \(httpResponse.statusCode)")
                throw AuthError.httpError(httpResponse.statusCode)
            }

            // Try to parse as Apple login response first
            if let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // Check if username selection is needed
                if let needsUsername = jsonResponse["needs_username_selection"] as? Bool, needsUsername {
                    // Store the pending data
                    await MainActor.run {
                        self.pendingAppleUserData = jsonResponse
                        self.suggestedUsername = jsonResponse["suggested_username"] as? String
                        self.jwtToken = jsonResponse["token"] as? String
                        self.needsUsernameSelection = true
                    }
                    return
                }
            }

            // Parse JWT response from backend
            let jwtResponse = try JSONDecoder().decode(JWTResponse.self, from: data)

            // Store JWT token
            self.jwtToken = jwtResponse.token

            // Fetch current user from BuddyPress
            try await fetchCurrentUser()

            await MainActor.run {
                self.isAuthenticated = true
                self.isGuestMode = false
                self.needsUsernameSelection = false
                saveAuthState()
            }
        } catch let error as AuthError {
            throw error
        } catch {
            Logger.error("Apple Sign In error: \(error)")
            throw AuthError.networkError
        }
    }

    func checkUsernameAvailability(username: String) async throws -> Bool {
        guard let url = URL(string: "https://gread.fun/wp-json/custom/v1/check-username") else {
            throw AuthError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = ["username": username]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AuthError.invalidResponse
        }

        if let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let available = jsonResponse["available"] as? Bool {
            return available
        }

        return false
    }

    func completeUsernameSelection(username: String) async throws {
        guard let token = jwtToken else {
            throw AuthError.unauthorized
        }

        guard let url = URL(string: "https://gread.fun/wp-json/custom/v1/complete-apple-signup") else {
            throw AuthError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body: [String: String] = ["username": username]
        request.httpBody = try JSONEncoder().encode(body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }

            if let responseString = String(data: data, encoding: .utf8) {
                Logger.debug("Complete Username Response: \(responseString)")
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                Logger.error("Complete username failed with status: \(httpResponse.statusCode)")
                throw AuthError.httpError(httpResponse.statusCode)
            }

            // Fetch current user from BuddyPress
            try await fetchCurrentUser()

            await MainActor.run {
                self.isAuthenticated = true
                self.isGuestMode = false
                self.needsUsernameSelection = false
                self.suggestedUsername = nil
                self.pendingAppleUserData = nil
                saveAuthState()
            }
        } catch let error as AuthError {
            throw error
        } catch {
            Logger.error("Complete username error: \(error)")
            throw AuthError.networkError
        }
    }

    func enterGuestMode() {
        isGuestMode = true
        isAuthenticated = false
    }

    func logout() {
        jwtToken = nil
        currentUser = nil
        isAuthenticated = false
        isGuestMode = false
        UserDefaults.standard.removeObject(forKey: "jwtToken")
        UserDefaults.standard.removeObject(forKey: "userId")
    }
    
    func fetchCurrentUser() async throws {
        let user: User = try await APIManager.shared.request(
            endpoint: "/members/me",
            authenticated: true
        )
        await MainActor.run {
            self.currentUser = user
        }
    }
    
    private func saveAuthState() {
        if let token = jwtToken {
            UserDefaults.standard.set(token, forKey: "jwtToken")
        }
        if let userId = currentUser?.id {
            UserDefaults.standard.set(userId, forKey: "userId")
        }
    }
    
    private func loadAuthState() {
        guard let token = UserDefaults.standard.string(forKey: "jwtToken") else {
            return
        }
        
        self.jwtToken = token
        self.isAuthenticated = true
        
        Task {
            do {
                try await fetchCurrentUser()
            } catch {
                // Token might be expired, logout
                await MainActor.run {
                    logout()
                }
            }
        }
    }
}
