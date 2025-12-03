import SwiftUI
import Foundation
import Combine

// MARK: - Auth Manager with JWT
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isGuestMode = false
    var jwtToken: String?

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

        // Clear caches on logout
        LibraryManager.shared.clearCache()
        DashboardManager.shared.clearCache()
        ProfileManager.shared.clearCache()
        UserProfileManager.shared.clearCache()
    }
    
    func fetchCurrentUser() async throws {
        // First get basic user info from /members/me
        let basicUser: User = try await APIManager.shared.request(
            endpoint: "/members/me",
            authenticated: true
        )

        // Then fetch full user data with avatar from /members/{id}
        let fullUser: User = try await APIManager.shared.request(
            endpoint: "/members/\(basicUser.id)",
            authenticated: false
        )

        await MainActor.run {
            self.currentUser = fullUser
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

    // MARK: - Apple Sign In

    /// Login with Apple - for existing users
    func loginWithApple(identityToken: String, authorizationCode: String, userIdentifier: String) async throws {
        guard let url = URL(string: "https://gread.fun/wp-json/gread/v1/auth/apple/login") else {
            throw AuthError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Backend expects appleUserID (camelCase)
        let body: [String: String] = [
            "appleUserID": userIdentifier
        ]

        request.httpBody = try JSONEncoder().encode(body)

        // Log request details
        Logger.debug("=== Apple Login Request ===")
        Logger.debug("URL: \(url)")
        Logger.debug("Body: \(body)")
        if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            Logger.debug("Request JSON: \(bodyString)")
        }
        Logger.debug("========================")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }

            Logger.debug("=== Apple Login Response ===")
            Logger.debug("Status: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                Logger.debug("Response: \(responseString)")
            }
            Logger.debug("========================")

            guard (200...299).contains(httpResponse.statusCode) else {
                // If 404 or user not found, this means they need to register
                if httpResponse.statusCode == 404 {
                    throw AuthError.userNotFound
                }
                Logger.error("Apple login failed with status: \(httpResponse.statusCode)")
                throw AuthError.httpError(httpResponse.statusCode)
            }

            // Parse Apple auth response
            let appleResponse = try JSONDecoder().decode(AppleAuthResponse.self, from: data)

            // Store auth token (this is a WordPress nonce-style token, not JWT)
            self.jwtToken = appleResponse.token

            // Create user object from Apple response (don't fetch from /members/me)
            let user = User(
                id: appleResponse.userId ?? 0,
                name: appleResponse.displayName ?? appleResponse.username ?? "User",
                userLogin: appleResponse.username
            )

            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
                self.isGuestMode = false
                saveAuthState()
            }

            // Fetch full user profile in background (this will update avatar, etc.)
            Task {
                do {
                    try await fetchCurrentUser()
                } catch {
                    Logger.warning("Could not fetch full user profile after Apple login: \(error)")
                    // Not critical - we already have basic user info
                }
            }
        } catch let error as AuthError {
            throw error
        } catch {
            Logger.error("Apple login error: \(error)")
            throw AuthError.networkError
        }
    }

    /// Register with Apple - for new users (returns username selection requirement)
    func registerWithApple(
        identityToken: String,
        authorizationCode: String,
        userIdentifier: String,
        email: String?,
        fullName: String?,
        username: String
    ) async throws {
        guard let url = URL(string: "https://gread.fun/wp-json/gread/v1/auth/apple/register") else {
            throw AuthError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Backend expects: appleUserID, email, username, and optionally fullName
        var body: [String: String] = [
            "appleUserID": userIdentifier,
            "username": username
        ]

        // Email is required by backend
        if let email = email {
            body["email"] = email
        } else {
            // If no email provided, generate a placeholder
            // This shouldn't happen with Apple Sign In, but just in case
            body["email"] = "\(userIdentifier)@appleid.private"
        }

        if let fullName = fullName {
            body["fullName"] = fullName
        }

        request.httpBody = try JSONEncoder().encode(body)

        // Log request details
        Logger.debug("=== Apple Register Request ===")
        Logger.debug("URL: \(url)")
        Logger.debug("Body: \(body)")
        if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            Logger.debug("Request JSON: \(bodyString)")
        }
        Logger.debug("========================")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }

            Logger.debug("=== Apple Register Response ===")
            Logger.debug("Status: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                Logger.debug("Response: \(responseString)")
            }
            Logger.debug("========================")

            // Check for username already taken error
            if httpResponse.statusCode == 400 || httpResponse.statusCode == 409 {
                if let errorResponse = try? JSONDecoder().decode(AppleAuthErrorResponse.self, from: data),
                   let message = errorResponse.message {
                    if message.lowercased().contains("username") {
                        throw AuthError.registrationFailed("This username is already taken. Please choose another.")
                    }
                    throw AuthError.registrationFailed(message)
                }
                throw AuthError.registrationFailed("Registration failed. Please try again.")
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                Logger.error("Apple registration failed with status: \(httpResponse.statusCode)")
                throw AuthError.httpError(httpResponse.statusCode)
            }

            // Parse Apple auth response
            let appleResponse = try JSONDecoder().decode(AppleAuthResponse.self, from: data)

            // Store auth token (this is a WordPress nonce-style token, not JWT)
            self.jwtToken = appleResponse.token

            // Create user object from Apple response (don't fetch from /members/me)
            let user = User(
                id: appleResponse.userId ?? 0,
                name: appleResponse.displayName ?? appleResponse.username ?? "User",
                userLogin: appleResponse.username
            )

            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
                self.isGuestMode = false
                saveAuthState()
            }

            // Fetch full user profile in background (this will update avatar, etc.)
            Task {
                do {
                    try await fetchCurrentUser()
                } catch {
                    Logger.warning("Could not fetch full user profile after Apple registration: \(error)")
                    // Not critical - we already have basic user info
                }
            }
        } catch let error as AuthError {
            throw error
        } catch {
            Logger.error("Apple registration error: \(error)")
            throw AuthError.networkError
        }
    }
}
