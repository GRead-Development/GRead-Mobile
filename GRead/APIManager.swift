import Foundation

// MARK: - API Manager for handling all API requests to the GRead backend
class APIManager {
    static let shared = APIManager()
    private let baseURL = "https://gread.fun/wp-json/buddypress/v1"
    private let customBaseURL = "https://gread.fun/wp-json/gread/v1"
    
    private init() {}
    
    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: [String: Any]? = nil,
        authenticated: Bool = true
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add JWT token to Authorization header
        if authenticated, let token = AuthManager.shared.jwtToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Enhanced response logging
        Logger.debug("=== API Response Debug ===")
        Logger.debug("URL: \(url)")
        Logger.debug("Status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            Logger.debug("Raw Response: \(responseString.prefix(500))") // First 500 chars
        }
        Logger.debug("========================")

        guard (200...299).contains(httpResponse.statusCode) else {
            Logger.error("API Error: Status \(httpResponse.statusCode)")
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        // Check for empty or "false" response
        if let responseString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
            if responseString == "false" || responseString == "[]" || responseString.isEmpty {
                Logger.warning("Empty response detected")
                // For empty array response, try to decode it as empty array
                if responseString == "[]" {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    if let decodedArray = try? decoder.decode(T.self, from: "[]".data(using: .utf8)!) {
                        return decodedArray
                    }
                }
                throw APIError.emptyResponse
            }
        }
        
        // Create decoder with flexible date strategy
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        // Custom date decoding to handle multiple formats
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try multiple date formats
            let formatters: [DateFormatter] = [
                self.createISO8601Formatter(),
                self.createDateFormatter(format: "yyyy-MM-dd'T'HH:mm:ss"),
                self.createDateFormatter(format: "yyyy-MM-dd HH:mm:ss"),
                self.createDateFormatter(format: "yyyy-MM-dd")
            ]
            
            for formatter in formatters {
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            
            // If all formats fail, throw error
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string: \(dateString)"
            )
        }
        
        do {
            let decoded = try decoder.decode(T.self, from: data)
            Logger.debug("Successfully decoded response")
            return decoded
        } catch {
            Logger.error("Decoding error for \(endpoint): \(error)")

            // Try to print the JSON structure for debugging
            if let json = try? JSONSerialization.jsonObject(with: data),
               let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                Logger.debug("JSON structure: \(prettyString.prefix(1000))")
            }

            // If decoding fails and the response was "[]", try to decode as empty array
            if let responseString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               responseString == "[]" {
                Logger.debug("Attempting to decode empty array")
                let emptyDecoder = JSONDecoder()
                if let decodedArray = try? emptyDecoder.decode(T.self, from: "[]".data(using: .utf8)!) {
                    return decodedArray
                }
            }

            throw APIError.decodingError(error)
        }
    }
    
    // Custom API request for GRead endpoints
    func customRequest<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: [String: Any]? = nil,
        authenticated: Bool = true
    ) async throws -> T {
        guard let url = URL(string: customBaseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if authenticated, let token = AuthManager.shared.jwtToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        Logger.debug("=== Custom API Response ===")
        Logger.debug("URL: \(url)")
        Logger.debug("Status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            Logger.debug("Response: \(responseString)")
        }
        Logger.debug("=========================")

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }

        // Check for empty response
        if let responseString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
            if responseString == "false" || responseString == "[]" || responseString.isEmpty {
                // For empty array response, try to decode it as empty array
                if responseString == "[]" {
                    let decoder = JSONDecoder()
                    if let decodedArray = try? decoder.decode(T.self, from: "[]".data(using: .utf8)!) {
                        return decodedArray
                    }
                }
                throw APIError.emptyResponse
            }
        }

        // Log raw JSON for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            Logger.debug("Raw API Response: \(responseString.prefix(2000))")
        }

        let decoder = JSONDecoder()
        // Don't use snake_case conversion for custom endpoints
        // They already use snake_case keys

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            Logger.error("Decoding error for \(endpoint): \(error)")

            // Try to log the JSON structure for debugging
            if let json = try? JSONSerialization.jsonObject(with: data),
               let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                Logger.debug("JSON structure: \(prettyString)")
            }

            throw APIError.decodingError(error)
        }
    }
    
    // Helper methods for date formatting
    private func createISO8601Formatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }
    
    private func createDateFormatter(format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }

    // MARK: - User Stats Endpoints

    /// Fetch user statistics for a given user ID
    func getUserStats(userId: Int) async throws -> UserStats {
        return try await customRequest(
            endpoint: "/user/\(userId)/stats",
            authenticated: true
        )
    }

    // MARK: - Moderation Endpoints

    /// Block a user
    func blockUser(userId: Int) async throws -> ModerationResponse {
        return try await customRequest(
            endpoint: "/user/block",
            method: "POST",
            body: ["user_id": userId],
            authenticated: true
        )
    }

    /// Unblock a user
    func unblockUser(userId: Int) async throws -> ModerationResponse {
        return try await customRequest(
            endpoint: "/user/unblock",
            method: "POST",
            body: ["user_id": userId],
            authenticated: true
        )
    }

    /// Mute a user
    func muteUser(userId: Int) async throws -> ModerationResponse {
        return try await customRequest(
            endpoint: "/user/mute",
            method: "POST",
            body: ["user_id": userId],
            authenticated: true
        )
    }

    /// Unmute a user
    func unmuteUser(userId: Int) async throws -> ModerationResponse {
        return try await customRequest(
            endpoint: "/user/unmute",
            method: "POST",
            body: ["user_id": userId],
            authenticated: true
        )
    }

    /// Report a user
    func reportUser(userId: Int, reason: String) async throws -> ModerationResponse {
        return try await customRequest(
            endpoint: "/user/report",
            method: "POST",
            body: ["user_id": userId, "reason": reason],
            authenticated: true
        )
    }

    /// Get list of blocked users
    func getBlockedList() async throws -> BlockedListResponse {
        return try await customRequest(
            endpoint: "/user/blocked_list",
            authenticated: true
        )
    }

    /// Get list of muted users
    func getMutedList() async throws -> MutedListResponse {
        return try await customRequest(
            endpoint: "/user/muted_list",
            authenticated: true
        )
    }

    // MARK: - Activity Feed Endpoints

    /// Fetch activity feed with pagination
    func getActivityFeed(page: Int = 1, perPage: Int = 20) async throws -> ActivityFeedResponse {
        return try await customRequest(
            endpoint: "/activity?per_page=\(perPage)&page=\(page)&type=activity_update",
            authenticated: false
        )
    }

    // MARK: - Cosmetics Endpoints

    /// Fetch all available cosmetics for the user
    func getUserCosmetics() async throws -> UserCosmetics {
        return try await customRequest(
            endpoint: "/user/cosmetics",
            authenticated: true
        )
    }

    /// Fetch all available cosmetics to unlock
    func getAvailableCosmetics() async throws -> [CosmeticUnlock] {
        return try await customRequest(
            endpoint: "/cosmetics",
            authenticated: true
        )
    }

    /// Set active theme for the user
    func setActiveTheme(themeId: String) async throws -> UserCosmetics {
        return try await customRequest(
            endpoint: "/user/cosmetics/theme",
            method: "POST",
            body: ["theme_id": themeId],
            authenticated: true
        )
    }

    /// Set active icon for the user
    func setActiveIcon(iconId: String) async throws -> UserCosmetics {
        return try await customRequest(
            endpoint: "/user/cosmetics/icon",
            method: "POST",
            body: ["icon_id": iconId],
            authenticated: true
        )
    }

    /// Check and unlock cosmetics based on current stats
    func checkAndUnlockCosmetics(stats: UserStats) async throws -> [CosmeticUnlock] {
        return try await customRequest(
            endpoint: "/user/check-unlocks",
            method: "POST",
            body: [
                "points": stats.points,
                "books_completed": stats.booksCompleted,
                "pages_read": stats.pagesRead,
                "books_added": stats.booksAdded,
                "approved_reports": stats.approvedReports
            ],
            authenticated: true
        )
    }

    // MARK: - Friend Endpoints

    /// Get list of friends for a user
    func getFriends(userId: Int) async throws -> FriendsListResponse {
        return try await customRequest(
            endpoint: "/friends/\(userId)",
            authenticated: false
        )
    }

    /// Get pending friend requests for the current user
    func getPendingFriendRequests() async throws -> PendingRequestsResponse {
        return try await customRequest(
            endpoint: "/friends/requests/pending",
            authenticated: true
        )
    }

    /// Send a friend request to another user
    func sendFriendRequest(friendId: Int) async throws -> FriendRequestResponse {
        return try await customRequest(
            endpoint: "/friends/request",
            method: "POST",
            body: ["friend_id": friendId],
            authenticated: true
        )
    }

    /// Accept a friend request
    func acceptFriendRequest(requestId: Int) async throws -> FriendRequestResponse {
        return try await customRequest(
            endpoint: "/friends/request/\(requestId)/accept",
            method: "POST",
            authenticated: true
        )
    }

    /// Reject a friend request
    func rejectFriendRequest(requestId: Int) async throws -> FriendRequestResponse {
        return try await customRequest(
            endpoint: "/friends/request/\(requestId)/reject",
            method: "POST",
            authenticated: true
        )
    }

    /// Remove a friend
    func removeFriend(friendId: Int) async throws -> FriendRequestResponse {
        return try await customRequest(
            endpoint: "/friends/\(friendId)/remove",
            method: "POST",
            authenticated: true
        )
    }

    /// Search for users
    func searchUsers(query: String, page: Int = 1, perPage: Int = 20) async throws -> UserSearchResponse {
        return try await customRequest(
            endpoint: "/members/search?search=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&per_page=\(perPage)&page=\(page)",
            authenticated: false
        )
    }
}

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case emptyResponse
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP Error: \(code)"
        case .emptyResponse:
            return "No data available"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}
