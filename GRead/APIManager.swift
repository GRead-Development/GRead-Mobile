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

    // MARK: - Achievements API

    /// Get all achievements
    /// - Parameter showHidden: Include hidden achievements in response
    func getAllAchievements(showHidden: Bool = false) async throws -> [Achievement] {
        return try await customRequest(
            endpoint: "/achievements?show_hidden=\(showHidden)",
            authenticated: false
        )
    }

    /// Get specific achievement by ID
    /// - Parameter id: Achievement ID
    func getAchievement(id: Int) async throws -> Achievement {
        return try await customRequest(
            endpoint: "/achievements/\(id)",
            authenticated: false
        )
    }

    /// Get achievement by slug
    /// - Parameter slug: Achievement slug identifier
    func getAchievement(slug: String) async throws -> Achievement {
        return try await customRequest(
            endpoint: "/achievements/slug/\(slug)",
            authenticated: false
        )
    }

    /// Get user achievements with progress
    /// - Parameters:
    ///   - userId: User ID
    ///   - filter: Filter type - "all", "unlocked", or "locked"
    func getUserAchievements(userId: Int, filter: String = "all") async throws -> UserAchievementsResponse {
        return try await customRequest(
            endpoint: "/user/\(userId)/achievements?filter=\(filter)",
            authenticated: false
        )
    }

    /// Get achievement statistics
    func getAchievementStats() async throws -> AchievementStats {
        return try await customRequest(
            endpoint: "/achievements/stats",
            authenticated: false
        )
    }

    /// Get achievements leaderboard
    /// - Parameters:
    ///   - limit: Number of results to return (max 100)
    ///   - offset: Pagination offset
    func getAchievementsLeaderboard(limit: Int = 10, offset: Int = 0) async throws -> [LeaderboardEntry] {
        return try await customRequest(
            endpoint: "/achievements/leaderboard?limit=\(limit)&offset=\(offset)",
            authenticated: false
        )
    }

    /// Get current user's achievements (requires authentication)
    /// - Parameter filter: Filter type - "all", "unlocked", or "locked"
    func getMyAchievements(filter: String = "all") async throws -> UserAchievementsResponse {
        return try await customRequest(
            endpoint: "/me/achievements?filter=\(filter)",
            authenticated: true
        )
    }

    /// Check and unlock achievements for current user (requires authentication)
    func checkAndUnlockAchievements() async throws -> UserAchievementsResponse {
        return try await customRequest(
            endpoint: "/me/achievements/check",
            method: "POST",
            authenticated: true
        )
    }

    // MARK: - Mentions API

    /// Search for users to mention
    /// - Parameters:
    ///   - query: Search term (minimum 2 characters)
    ///   - limit: Number of results (max 100)
    func searchMentionUsers(query: String, limit: Int = 10) async throws -> MentionSearchResponse {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return try await customRequest(
            endpoint: "/mentions/search?query=\(encodedQuery)&limit=\(limit)",
            authenticated: false
        )
    }

    /// Get all mentionable users
    /// - Parameters:
    ///   - limit: Number of users to return (max 500)
    ///   - offset: Pagination offset
    func getMentionableUsers(limit: Int = 50, offset: Int = 0) async throws -> MentionUsersResponse {
        return try await customRequest(
            endpoint: "/mentions/users?limit=\(limit)&offset=\(offset)",
            authenticated: false
        )
    }

    /// Get user mentions by ID
    /// - Parameters:
    ///   - userId: User ID
    ///   - limit: Number of mentions to return
    ///   - offset: Pagination offset
    func getUserMentions(userId: Int, limit: Int = 20, offset: Int = 0) async throws -> UserMentionsResponse {
        return try await customRequest(
            endpoint: "/user/\(userId)/mentions?limit=\(limit)&offset=\(offset)",
            authenticated: false
        )
    }

    /// Get activity containing mentions
    /// - Parameters:
    ///   - userId: Optional user ID to filter by specific user
    ///   - limit: Number of activities to return
    ///   - offset: Pagination offset
    func getMentionsActivity(userId: Int? = nil, limit: Int = 20, offset: Int = 0) async throws -> MentionsActivityResponse {
        var endpoint = "/mentions/activity?limit=\(limit)&offset=\(offset)"
        if let userId = userId {
            endpoint += "&user_id=\(userId)"
        }
        return try await customRequest(
            endpoint: endpoint,
            authenticated: false
        )
    }

    /// Get current user's mentions (requires authentication)
    /// - Parameters:
    ///   - limit: Number of mentions to return
    ///   - offset: Pagination offset
    ///   - unreadOnly: Only return unread mentions
    func getMyMentions(limit: Int = 20, offset: Int = 0, unreadOnly: Bool = false) async throws -> UserMentionsResponse {
        return try await customRequest(
            endpoint: "/me/mentions?limit=\(limit)&offset=\(offset)&unread_only=\(unreadOnly)",
            authenticated: true
        )
    }

    /// Mark mentions as read for current user (requires authentication)
    func markMentionsAsRead() async throws -> MarkMentionsReadResponse {
        return try await customRequest(
            endpoint: "/me/mentions/read",
            method: "POST",
            authenticated: true
        )
    }

    // MARK: - BuddyPress Members Endpoints

    /// Get all members
    func getMembers(page: Int = 1, perPage: Int = 20, search: String? = nil, type: String = "active") async throws -> [User] {
        var endpoint = "/members?page=\(page)&per_page=\(perPage)&type=\(type)"
        if let search = search {
            endpoint += "&search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
        return try await request(endpoint: endpoint, authenticated: false)
    }

    /// Create a new member (signup)
    func createMember(username: String, email: String, password: String, name: String? = nil) async throws -> User {
        var body: [String: Any] = [
            "user_login": username,
            "user_email": email,
            "password": password
        ]
        if let name = name {
            body["name"] = name
        }
        return try await request(endpoint: "/members", method: "POST", body: body, authenticated: false)
    }

    /// Get member by ID
    func getMember(id: Int) async throws -> User {
        return try await request(endpoint: "/members/\(id)", authenticated: false)
    }

    /// Update member
    func updateMember(id: Int, name: String? = nil, roles: [String]? = nil) async throws -> User {
        var body: [String: Any] = [:]
        if let name = name {
            body["name"] = name
        }
        if let roles = roles {
            body["roles"] = roles
        }
        return try await request(endpoint: "/members/\(id)", method: "PUT", body: body, authenticated: true)
    }

    /// Delete member
    func deleteMember(id: Int, reassign: Int? = nil) async throws -> EmptyResponse {
        var body: [String: Any] = [:]
        if let reassign = reassign {
            body["reassign"] = reassign
        }
        return try await request(endpoint: "/members/\(id)", method: "DELETE", body: body, authenticated: true)
    }

    /// Get member XProfile data
    func getMemberXProfile(id: Int) async throws -> MemberXProfileResponse {
        return try await request(endpoint: "/members/\(id)/xprofile", authenticated: false)
    }

    /// Update member XProfile data
    func updateMemberXProfile(id: Int, fields: [String: Any]) async throws -> MemberXProfileResponse {
        return try await request(endpoint: "/members/\(id)/xprofile", method: "PUT", body: ["fields": fields], authenticated: true)
    }

    /// Get member avatar
    func getMemberAvatar(userId: Int) async throws -> AvatarResponse {
        return try await request(endpoint: "/members/\(userId)/avatar", authenticated: false)
    }

    /// Upload member avatar
    func uploadMemberAvatar(userId: Int, imageData: Data) async throws -> AvatarUploadResponse {
        // Note: This would need multipart/form-data encoding
        // Placeholder for now - actual implementation would require URLSession multipart upload
        throw APIError.invalidURL
    }

    /// Delete member avatar
    func deleteMemberAvatar(userId: Int) async throws -> EmptyResponse {
        return try await request(endpoint: "/members/\(userId)/avatar", method: "DELETE", authenticated: true)
    }

    /// Get member cover image
    func getMemberCover(userId: Int) async throws -> CoverImageResponse {
        return try await request(endpoint: "/members/\(userId)/cover", authenticated: false)
    }

    /// Upload member cover image
    func uploadMemberCover(userId: Int, imageData: Data) async throws -> CoverImageResponse {
        // Note: This would need multipart/form-data encoding
        throw APIError.invalidURL
    }

    /// Delete member cover image
    func deleteMemberCover(userId: Int) async throws -> EmptyResponse {
        return try await request(endpoint: "/members/\(userId)/cover", method: "DELETE", authenticated: true)
    }

    /// Get current user (me)
    func getCurrentUser() async throws -> User {
        return try await request(endpoint: "/members/me", authenticated: true)
    }

    /// Update current user
    func updateCurrentUser(name: String? = nil) async throws -> User {
        var body: [String: Any] = [:]
        if let name = name {
            body["name"] = name
        }
        return try await request(endpoint: "/members/me", method: "PUT", body: body, authenticated: true)
    }

    /// Delete current user
    func deleteCurrentUser(reassign: Int? = nil) async throws -> EmptyResponse {
        var body: [String: Any] = [:]
        if let reassign = reassign {
            body["reassign"] = reassign
        }
        return try await request(endpoint: "/members/me", method: "DELETE", body: body, authenticated: true)
    }

    // MARK: - BuddyPress Activity Endpoints

    /// Get activity items
    func getActivity(page: Int = 1, perPage: Int = 20, userId: Int? = nil, type: String? = nil, scope: String? = nil) async throws -> [Activity] {
        var endpoint = "/activity?page=\(page)&per_page=\(perPage)"
        if let userId = userId {
            endpoint += "&user_id=\(userId)"
        }
        if let type = type {
            endpoint += "&type=\(type)"
        }
        if let scope = scope {
            endpoint += "&scope=\(scope)"
        }
        return try await request(endpoint: endpoint, authenticated: false)
    }

    /// Create activity
    func createActivity(content: String, userId: Int, type: String = "activity_update", component: String = "activity") async throws -> Activity {
        let body: [String: Any] = [
            "content": content,
            "user_id": userId,
            "type": type,
            "component": component
        ]
        return try await request(endpoint: "/activity", method: "POST", body: body, authenticated: true)
    }

    /// Get specific activity
    func getActivity(id: Int) async throws -> Activity {
        return try await request(endpoint: "/activity/\(id)", authenticated: false)
    }

    /// Update activity
    func updateActivity(id: Int, content: String) async throws -> Activity {
        return try await request(endpoint: "/activity/\(id)", method: "PUT", body: ["content": content], authenticated: true)
    }

    /// Delete activity
    func deleteActivity(id: Int) async throws -> EmptyResponse {
        return try await request(endpoint: "/activity/\(id)", method: "DELETE", authenticated: true)
    }

    /// Favorite activity
    func favoriteActivity(id: Int) async throws -> EmptyResponse {
        return try await request(endpoint: "/activity/\(id)/favorite", method: "POST", authenticated: true)
    }

    /// Unfavorite activity
    func unfavoriteActivity(id: Int) async throws -> EmptyResponse {
        return try await request(endpoint: "/activity/\(id)/favorite", method: "DELETE", authenticated: true)
    }

    /// Comment on activity
    func commentOnActivity(id: Int, content: String) async throws -> Activity {
        return try await request(endpoint: "/activity/\(id)/comment", method: "POST", body: ["content": content], authenticated: true)
    }

    // MARK: - BuddyPress Groups Endpoints

    /// Get all groups
    func getGroups(page: Int = 1, perPage: Int = 20, search: String? = nil, type: String = "active", userId: Int? = nil) async throws -> [BPGroup] {
        var endpoint = "/groups?page=\(page)&per_page=\(perPage)&type=\(type)"
        if let search = search {
            endpoint += "&search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
        if let userId = userId {
            endpoint += "&user_id=\(userId)"
        }
        return try await request(endpoint: endpoint, authenticated: false)
    }

    /// Create group
    func createGroup(name: String, description: String? = nil, status: String = "public") async throws -> BPGroup {
        var body: [String: Any] = [
            "name": name,
            "status": status
        ]
        if let description = description {
            body["description"] = description
        }
        return try await request(endpoint: "/groups", method: "POST", body: body, authenticated: true)
    }

    /// Get specific group
    func getGroup(id: Int) async throws -> BPGroup {
        return try await request(endpoint: "/groups/\(id)", authenticated: false)
    }

    /// Update group
    func updateGroup(id: Int, name: String? = nil, description: String? = nil, status: String? = nil) async throws -> BPGroup {
        var body: [String: Any] = [:]
        if let name = name {
            body["name"] = name
        }
        if let description = description {
            body["description"] = description
        }
        if let status = status {
            body["status"] = status
        }
        return try await request(endpoint: "/groups/\(id)", method: "PUT", body: body, authenticated: true)
    }

    /// Delete group
    func deleteGroup(id: Int) async throws -> EmptyResponse {
        return try await request(endpoint: "/groups/\(id)", method: "DELETE", authenticated: true)
    }

    /// Get current user's groups
    func getMyGroups() async throws -> [BPGroup] {
        return try await request(endpoint: "/groups/me", authenticated: true)
    }

    /// Get group members
    func getGroupMembers(groupId: Int, page: Int = 1, perPage: Int = 20) async throws -> [GroupMember] {
        return try await request(endpoint: "/groups/\(groupId)/members?page=\(page)&per_page=\(perPage)", authenticated: false)
    }

    /// Add group member
    func addGroupMember(groupId: Int, userId: Int) async throws -> GroupMember {
        return try await request(endpoint: "/groups/\(groupId)/members", method: "POST", body: ["user_id": userId], authenticated: true)
    }

    /// Remove group member
    func removeGroupMember(groupId: Int, userId: Int) async throws -> EmptyResponse {
        return try await request(endpoint: "/groups/\(groupId)/members/\(userId)", method: "DELETE", authenticated: true)
    }

    /// Get group avatar
    func getGroupAvatar(groupId: Int) async throws -> AvatarResponse {
        return try await request(endpoint: "/groups/\(groupId)/avatar", authenticated: false)
    }

    /// Upload group avatar
    func uploadGroupAvatar(groupId: Int, imageData: Data) async throws -> AvatarUploadResponse {
        // Note: This would need multipart/form-data encoding
        throw APIError.invalidURL
    }

    /// Delete group avatar
    func deleteGroupAvatar(groupId: Int) async throws -> EmptyResponse {
        return try await request(endpoint: "/groups/\(groupId)/avatar", method: "DELETE", authenticated: true)
    }

    /// Get group cover image
    func getGroupCover(groupId: Int) async throws -> CoverImageResponse {
        return try await request(endpoint: "/groups/\(groupId)/cover", authenticated: false)
    }

    /// Upload group cover image
    func uploadGroupCover(groupId: Int, imageData: Data) async throws -> CoverImageResponse {
        // Note: This would need multipart/form-data encoding
        throw APIError.invalidURL
    }

    /// Delete group cover image
    func deleteGroupCover(groupId: Int) async throws -> EmptyResponse {
        return try await request(endpoint: "/groups/\(groupId)/cover", method: "DELETE", authenticated: true)
    }

    /// Get group invites
    func getGroupInvites(page: Int = 1, perPage: Int = 20, userId: Int? = nil) async throws -> [GroupInvite] {
        var endpoint = "/groups/invites?page=\(page)&per_page=\(perPage)"
        if let userId = userId {
            endpoint += "&user_id=\(userId)"
        }
        return try await request(endpoint: endpoint, authenticated: true)
    }

    /// Send group invite
    func sendGroupInvite(groupId: Int, userId: Int) async throws -> GroupInvite {
        return try await request(endpoint: "/groups/invites", method: "POST", body: ["group_id": groupId, "user_id": userId], authenticated: true)
    }

    /// Accept group invite
    func acceptGroupInvite(inviteId: Int) async throws -> EmptyResponse {
        return try await request(endpoint: "/groups/invites/\(inviteId)/accept", method: "POST", authenticated: true)
    }

    /// Reject group invite
    func rejectGroupInvite(inviteId: Int) async throws -> EmptyResponse {
        return try await request(endpoint: "/groups/invites/\(inviteId)/reject", method: "POST", authenticated: true)
    }

    /// Get membership requests
    func getGroupMembershipRequests(page: Int = 1, perPage: Int = 20, groupId: Int? = nil) async throws -> [GroupMembershipRequest] {
        var endpoint = "/groups/membership-requests?page=\(page)&per_page=\(perPage)"
        if let groupId = groupId {
            endpoint += "&group_id=\(groupId)"
        }
        return try await request(endpoint: endpoint, authenticated: true)
    }

    /// Request group membership
    func requestGroupMembership(groupId: Int, comments: String? = nil) async throws -> GroupMembershipRequest {
        var body: [String: Any] = ["group_id": groupId]
        if let comments = comments {
            body["comments"] = comments
        }
        return try await request(endpoint: "/groups/membership-requests", method: "POST", body: body, authenticated: true)
    }

    /// Accept membership request
    func acceptMembershipRequest(requestId: Int) async throws -> EmptyResponse {
        return try await request(endpoint: "/groups/membership-requests/\(requestId)/accept", method: "POST", authenticated: true)
    }

    /// Reject membership request
    func rejectMembershipRequest(requestId: Int) async throws -> EmptyResponse {
        return try await request(endpoint: "/groups/membership-requests/\(requestId)/reject", method: "POST", authenticated: true)
    }

    // MARK: - BuddyPress Messages Endpoints

    /// Get messages (threads)
    func getMessages(page: Int = 1, perPage: Int = 20, box: String = "inbox", userId: Int? = nil) async throws -> [Message] {
        var endpoint = "/messages?page=\(page)&per_page=\(perPage)&box=\(box)"
        if let userId = userId {
            endpoint += "&user_id=\(userId)"
        }
        return try await request(endpoint: endpoint, authenticated: true)
    }

    /// Send message
    func sendMessage(recipients: [Int], subject: String, message: String) async throws -> Message {
        let body: [String: Any] = [
            "recipients": recipients,
            "subject": subject,
            "message": message
        ]
        return try await request(endpoint: "/messages", method: "POST", body: body, authenticated: true)
    }

    /// Get message thread
    func getMessageThread(id: Int) async throws -> Message {
        return try await request(endpoint: "/messages/\(id)", authenticated: true)
    }

    /// Update message thread
    func updateMessageThread(id: Int, read: Bool? = nil, unread: Bool? = nil) async throws -> Message {
        var body: [String: Any] = [:]
        if let read = read {
            body["read"] = read
        }
        if let unread = unread {
            body["unread"] = unread
        }
        return try await request(endpoint: "/messages/\(id)", method: "PUT", body: body, authenticated: true)
    }

    /// Delete message thread
    func deleteMessageThread(id: Int) async throws -> EmptyResponse {
        return try await request(endpoint: "/messages/\(id)", method: "DELETE", authenticated: true)
    }

    /// Star message
    func starMessage(id: Int) async throws -> EmptyResponse {
        return try await request(endpoint: "/messages/starred/\(id)", method: "POST", authenticated: true)
    }

    /// Unstar message
    func unstarMessage(id: Int) async throws -> EmptyResponse {
        return try await request(endpoint: "/messages/starred/\(id)", method: "DELETE", authenticated: true)
    }

    // MARK: - BuddyPress Friends Endpoints (using BuddyPress API)

    /// Get friends list (BuddyPress API)
    func getFriendsBP(userId: Int, page: Int = 1, perPage: Int = 20) async throws -> [User] {
        return try await request(endpoint: "/friends/\(userId)?page=\(page)&per_page=\(perPage)", authenticated: false)
    }

    /// Send friend request (BuddyPress API)
    func sendFriendRequestBP(friendId: Int) async throws -> EmptyResponse {
        return try await request(endpoint: "/friends/request", method: "POST", body: ["friend_id": friendId], authenticated: true)
    }

    /// Accept friend request (BuddyPress API)
    func acceptFriendRequestBP(id: Int) async throws -> EmptyResponse {
        return try await request(endpoint: "/friends/\(id)/accept", method: "POST", authenticated: true)
    }

    /// Reject friend request (BuddyPress API)
    func rejectFriendRequestBP(id: Int) async throws -> EmptyResponse {
        return try await request(endpoint: "/friends/\(id)/reject", method: "POST", authenticated: true)
    }

    /// Remove friend (BuddyPress API)
    func removeFriendBP(userId: Int, friendId: Int) async throws -> EmptyResponse {
        return try await request(endpoint: "/friends/\(userId)/\(friendId)", method: "DELETE", authenticated: true)
    }

    // MARK: - BuddyPress Notifications Endpoints

    /// Get notifications
    func getNotifications(page: Int = 1, perPage: Int = 20, userId: Int? = nil, isNew: Bool? = nil) async throws -> [Notification] {
        var endpoint = "/notifications?page=\(page)&per_page=\(perPage)"
        if let userId = userId {
            endpoint += "&user_id=\(userId)"
        }
        if let isNew = isNew {
            endpoint += "&is_new=\(isNew ? "1" : "0")"
        }
        return try await request(endpoint: endpoint, authenticated: true)
    }

    /// Create notification
    func createNotification(userId: Int, componentName: String, componentAction: String, itemId: Int? = nil, secondaryItemId: Int? = nil) async throws -> Notification {
        var body: [String: Any] = [
            "user_id": userId,
            "component_name": componentName,
            "component_action": componentAction
        ]
        if let itemId = itemId {
            body["item_id"] = itemId
        }
        if let secondaryItemId = secondaryItemId {
            body["secondary_item_id"] = secondaryItemId
        }
        return try await request(endpoint: "/notifications", method: "POST", body: body, authenticated: true)
    }

    /// Get specific notification
    func getNotification(id: Int) async throws -> Notification {
        return try await request(endpoint: "/notifications/\(id)", authenticated: true)
    }

    /// Update notification
    func updateNotification(id: Int, isNew: Bool) async throws -> Notification {
        return try await request(endpoint: "/notifications/\(id)", method: "PUT", body: ["is_new": isNew], authenticated: true)
    }

    /// Delete notification
    func deleteNotification(id: Int) async throws -> EmptyResponse {
        return try await request(endpoint: "/notifications/\(id)", method: "DELETE", authenticated: true)
    }

    // MARK: - BuddyPress XProfile Endpoints

    /// Get XProfile field groups
    func getXProfileGroups(fetchFields: Bool = true) async throws -> [XProfileGroup] {
        return try await request(endpoint: "/xprofile/groups?fetch_fields=\(fetchFields)", authenticated: false)
    }

    /// Create XProfile field group
    func createXProfileGroup(name: String, description: String? = nil) async throws -> XProfileGroup {
        var body: [String: Any] = ["name": name]
        if let description = description {
            body["description"] = description
        }
        return try await request(endpoint: "/xprofile/groups", method: "POST", body: body, authenticated: true)
    }

    /// Get XProfile field group
    func getXProfileGroup(id: Int, fetchFields: Bool = true) async throws -> XProfileGroup {
        return try await request(endpoint: "/xprofile/groups/\(id)?fetch_fields=\(fetchFields)", authenticated: false)
    }

    /// Update XProfile field group
    func updateXProfileGroup(id: Int, name: String? = nil, description: String? = nil) async throws -> XProfileGroup {
        var body: [String: Any] = [:]
        if let name = name {
            body["name"] = name
        }
        if let description = description {
            body["description"] = description
        }
        return try await request(endpoint: "/xprofile/groups/\(id)", method: "PUT", body: body, authenticated: true)
    }

    /// Delete XProfile field group
    func deleteXProfileGroup(id: Int) async throws -> EmptyResponse {
        return try await request(endpoint: "/xprofile/groups/\(id)", method: "DELETE", authenticated: true)
    }

    /// Get XProfile fields
    func getXProfileFields(page: Int = 1, perPage: Int = 20) async throws -> [XProfileField] {
        return try await request(endpoint: "/xprofile/fields?page=\(page)&per_page=\(perPage)", authenticated: false)
    }

    /// Create XProfile field
    func createXProfileField(groupId: Int, name: String, type: String, isRequired: Bool = false) async throws -> XProfileField {
        let body: [String: Any] = [
            "group_id": groupId,
            "name": name,
            "type": type,
            "is_required": isRequired
        ]
        return try await request(endpoint: "/xprofile/fields", method: "POST", body: body, authenticated: true)
    }

    /// Get XProfile field
    func getXProfileField(id: Int) async throws -> XProfileField {
        return try await request(endpoint: "/xprofile/fields/\(id)", authenticated: false)
    }

    /// Update XProfile field
    func updateXProfileField(id: Int, name: String? = nil, description: String? = nil, isRequired: Bool? = nil) async throws -> XProfileField {
        var body: [String: Any] = [:]
        if let name = name {
            body["name"] = name
        }
        if let description = description {
            body["description"] = description
        }
        if let isRequired = isRequired {
            body["is_required"] = isRequired
        }
        return try await request(endpoint: "/xprofile/fields/\(id)", method: "PUT", body: body, authenticated: true)
    }

    /// Delete XProfile field
    func deleteXProfileField(id: Int) async throws -> EmptyResponse {
        return try await request(endpoint: "/xprofile/fields/\(id)", method: "DELETE", authenticated: true)
    }

    /// Get XProfile field data for user
    func getXProfileFieldData(fieldId: Int, userId: Int) async throws -> XProfileData {
        return try await request(endpoint: "/xprofile/\(fieldId)/data/\(userId)", authenticated: false)
    }

    /// Update XProfile field data for user
    func updateXProfileFieldData(fieldId: Int, userId: Int, value: Any) async throws -> XProfileData {
        return try await request(endpoint: "/xprofile/\(fieldId)/data/\(userId)", method: "POST", body: ["value": value], authenticated: true)
    }

    /// Delete XProfile field data for user
    func deleteXProfileFieldData(fieldId: Int, userId: Int) async throws -> EmptyResponse {
        return try await request(endpoint: "/xprofile/\(fieldId)/data/\(userId)", method: "DELETE", authenticated: true)
    }

    // MARK: - BuddyPress Signup Endpoints

    /// Get signups
    func getSignups(page: Int = 1, perPage: Int = 20) async throws -> [Signup] {
        return try await request(endpoint: "/signup?page=\(page)&per_page=\(perPage)", authenticated: true)
    }

    /// Create signup
    func createSignup(userLogin: String, userEmail: String, password: String) async throws -> SignupResponse {
        let body: [String: Any] = [
            "user_login": userLogin,
            "user_email": userEmail,
            "password": password
        ]
        return try await request(endpoint: "/signup", method: "POST", body: body, authenticated: false)
    }

    /// Activate signup
    func activateSignup(key: String) async throws -> ActivationResponse {
        return try await request(endpoint: "/signup/activate/\(key)", method: "POST", authenticated: false)
    }

    /// Resend activation email
    func resendActivation(userLogin: String) async throws -> ResendActivationResponse {
        return try await request(endpoint: "/signup/resend", method: "POST", body: ["user_login": userLogin], authenticated: false)
    }

    // MARK: - BuddyPress Components Endpoints

    /// Get components
    func getComponents() async throws -> [BPComponent] {
        return try await request(endpoint: "/components", authenticated: false)
    }

    /// Update component
    func updateComponent(id: String, status: String) async throws -> BPComponent {
        return try await request(endpoint: "/components/\(id)", method: "PUT", body: ["status": status], authenticated: true)
    }

    // MARK: - BuddyPress Sitewide Notices Endpoints

    /// Get sitewide notices
    func getSitewideNotices(page: Int = 1, perPage: Int = 20) async throws -> [SitewideNotice] {
        return try await request(endpoint: "/sitewide-notices?page=\(page)&per_page=\(perPage)", authenticated: false)
    }

    /// Create sitewide notice
    func createSitewideNotice(subject: String, message: String) async throws -> SitewideNotice {
        let body: [String: Any] = [
            "subject": subject,
            "message": message
        ]
        return try await request(endpoint: "/sitewide-notices", method: "POST", body: body, authenticated: true)
    }

    /// Dismiss sitewide notice
    func dismissSitewideNotice(id: Int) async throws -> NoticeResponse {
        return try await request(endpoint: "/sitewide-notices/dismiss", method: "POST", body: ["notice_id": id], authenticated: true)
    }

    // MARK: - GRead Books Endpoints

    /// Get book by ID
    func getBook(id: Int) async throws -> Book {
        return try await customRequest(endpoint: "/book/\(id)", authenticated: false)
    }

    /// Search books by ISBN
    func searchBooksByISBN(isbn: String) async throws -> [Book] {
        let encodedISBN = isbn.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return try await customRequest(endpoint: "/books/isbn?isbn=\(encodedISBN)", authenticated: false)
    }

    /// Merge duplicate books
    func mergeBooks(primaryBookId: Int, duplicateBookIds: [Int]) async throws -> Book {
        let body: [String: Any] = [
            "primary_book_id": primaryBookId,
            "duplicate_book_ids": duplicateBookIds
        ]
        return try await customRequest(endpoint: "/books/merge", method: "POST", body: body, authenticated: true)
    }

    /// Add ISBN to book
    func addISBNToBook(bookId: Int, isbn: String, isbn13: String? = nil) async throws -> BookISBN {
        var body: [String: Any] = ["isbn": isbn]
        if let isbn13 = isbn13 {
            body["isbn13"] = isbn13
        }
        return try await customRequest(endpoint: "/books/\(bookId)/isbn", method: "POST", body: body, authenticated: true)
    }

    /// Get book ISBNs
    func getBookISBNs(bookId: Int) async throws -> [BookISBN] {
        return try await customRequest(endpoint: "/books/\(bookId)/isbns", authenticated: false)
    }

    /// Add book ISBN
    func addBookISBN(bookId: Int, isbn: String, isbn13: String? = nil) async throws -> BookISBN {
        var body: [String: Any] = ["isbn": isbn]
        if let isbn13 = isbn13 {
            body["isbn13"] = isbn13
        }
        return try await customRequest(endpoint: "/books/\(bookId)/isbns", method: "POST", body: body, authenticated: true)
    }

    /// Get book notes
    func getBookNotes(bookId: Int) async throws -> [BookNote] {
        return try await customRequest(endpoint: "/books/\(bookId)/notes", authenticated: true)
    }

    /// Create book note
    func createBookNote(bookId: Int, note: String, page: Int? = nil, isPublic: Bool = false) async throws -> BookNote {
        var body: [String: Any] = [
            "note": note,
            "is_public": isPublic
        ]
        if let page = page {
            body["page"] = page
        }
        return try await customRequest(endpoint: "/books/\(bookId)/notes", method: "POST", body: body, authenticated: true)
    }

    /// Search books
    func searchBooks(query: String, page: Int = 1, perPage: Int = 20) async throws -> BookSearchResponse {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return try await customRequest(endpoint: "/books/search?query=\(encodedQuery)&page=\(page)&per_page=\(perPage)", authenticated: false)
    }

    // MARK: - GRead Library Endpoints

    /// Get user's library
    func getLibrary(page: Int = 1, perPage: Int = 20, status: String? = nil) async throws -> LibraryResponse {
        var endpoint = "/library?page=\(page)&per_page=\(perPage)"
        if let status = status {
            endpoint += "&status=\(status)"
        }
        return try await customRequest(endpoint: endpoint, authenticated: true)
    }

    /// Add book to library
    func addToLibrary(bookId: Int, status: String = "want_to_read") async throws -> LibraryItem {
        let body: [String: Any] = [
            "book_id": bookId,
            "status": status
        ]
        return try await customRequest(endpoint: "/library", method: "POST", body: body, authenticated: true)
    }

    /// Update reading progress
    func updateReadingProgress(bookId: Int, currentPage: Int, status: String? = nil) async throws -> ProgressUpdateResponse {
        var body: [String: Any] = ["current_page": currentPage]
        if let status = status {
            body["status"] = status
        }
        return try await customRequest(endpoint: "/library/progress", method: "POST", body: ["book_id": bookId, "current_page": currentPage, "status": status as Any], authenticated: true)
    }

    // MARK: - GRead Authors Endpoints

    /// Get all authors
    func getAuthors(page: Int = 1, perPage: Int = 20) async throws -> AuthorsListResponse {
        return try await customRequest(endpoint: "/authors?page=\(page)&per_page=\(perPage)", authenticated: false)
    }

    /// Create author
    func createAuthor(name: String, bio: String? = nil, nationality: String? = nil) async throws -> Author {
        var body: [String: Any] = ["name": name]
        if let bio = bio {
            body["bio"] = bio
        }
        if let nationality = nationality {
            body["nationality"] = nationality
        }
        return try await customRequest(endpoint: "/authors", method: "POST", body: body, authenticated: true)
    }

    /// Get author by ID
    func getAuthor(id: Int) async throws -> Author {
        return try await customRequest(endpoint: "/authors/\(id)", authenticated: false)
    }

    /// Update author
    func updateAuthor(id: Int, name: String? = nil, bio: String? = nil, nationality: String? = nil) async throws -> Author {
        var body: [String: Any] = [:]
        if let name = name {
            body["name"] = name
        }
        if let bio = bio {
            body["bio"] = bio
        }
        if let nationality = nationality {
            body["nationality"] = nationality
        }
        return try await customRequest(endpoint: "/authors/\(id)", method: "PUT", body: body, authenticated: true)
    }

    /// Get author's books
    func getAuthorBooks(authorId: Int, page: Int = 1, perPage: Int = 20) async throws -> [Book] {
        return try await customRequest(endpoint: "/authors/\(authorId)/books?page=\(page)&per_page=\(perPage)", authenticated: false)
    }

    // MARK: - GRead Activity Endpoints (Custom)

    /// Delete activity (GRead custom endpoint)
    func deleteActivityGRead(id: Int) async throws -> EmptyResponse {
        return try await customRequest(endpoint: "/activity/\(id)", method: "DELETE", authenticated: true)
    }

    /// Favorite activity (GRead custom endpoint)
    func favoriteActivityGRead(id: Int) async throws -> EmptyResponse {
        return try await customRequest(endpoint: "/activity/\(id)/favorite", method: "POST", authenticated: true)
    }

    /// Comment on activity (GRead custom endpoint)
    func commentOnActivityGRead(id: Int, content: String) async throws -> Activity {
        return try await customRequest(endpoint: "/activity/\(id)/comment", method: "POST", body: ["content": content], authenticated: true)
    }

    // MARK: - GRead Members Endpoints (Custom)

    /// Get all members (GRead)
    func getMembersGRead(page: Int = 1, perPage: Int = 20) async throws -> [User] {
        return try await customRequest(endpoint: "/members?page=\(page)&per_page=\(perPage)", authenticated: false)
    }

    /// Get member (GRead)
    func getMemberGRead(id: Int) async throws -> User {
        return try await customRequest(endpoint: "/members/\(id)", authenticated: false)
    }

    /// Update member (GRead)
    func updateMemberGRead(id: Int, name: String? = nil) async throws -> User {
        var body: [String: Any] = [:]
        if let name = name {
            body["name"] = name
        }
        return try await customRequest(endpoint: "/members/\(id)", method: "PUT", body: body, authenticated: true)
    }

    /// Get member XProfile (GRead)
    func getMemberXProfileGRead(id: Int) async throws -> MemberXProfileResponse {
        return try await customRequest(endpoint: "/members/\(id)/xprofile", authenticated: false)
    }

    /// Update member XProfile (GRead)
    func updateMemberXProfileGRead(id: Int, fields: [String: Any]) async throws -> MemberXProfileResponse {
        return try await customRequest(endpoint: "/members/\(id)/xprofile", method: "PUT", body: ["fields": fields], authenticated: true)
    }

    // MARK: - GRead Groups Endpoints (Custom)

    /// Get groups (GRead)
    func getGroupsGRead(page: Int = 1, perPage: Int = 20) async throws -> [BPGroup] {
        return try await customRequest(endpoint: "/groups?page=\(page)&per_page=\(perPage)", authenticated: false)
    }

    /// Create group (GRead)
    func createGroupGRead(name: String, description: String? = nil) async throws -> BPGroup {
        var body: [String: Any] = ["name": name]
        if let description = description {
            body["description"] = description
        }
        return try await customRequest(endpoint: "/groups", method: "POST", body: body, authenticated: true)
    }

    /// Get group (GRead)
    func getGroupGRead(id: Int) async throws -> BPGroup {
        return try await customRequest(endpoint: "/groups/\(id)", authenticated: false)
    }

    /// Update group (GRead)
    func updateGroupGRead(id: Int, name: String? = nil, description: String? = nil) async throws -> BPGroup {
        var body: [String: Any] = [:]
        if let name = name {
            body["name"] = name
        }
        if let description = description {
            body["description"] = description
        }
        return try await customRequest(endpoint: "/groups/\(id)", method: "PUT", body: body, authenticated: true)
    }

    /// Delete group (GRead)
    func deleteGroupGRead(id: Int) async throws -> EmptyResponse {
        return try await customRequest(endpoint: "/groups/\(id)", method: "DELETE", authenticated: true)
    }

    /// Get group members (GRead)
    func getGroupMembersGRead(groupId: Int) async throws -> [User] {
        return try await customRequest(endpoint: "/groups/\(groupId)/members", authenticated: false)
    }

    /// Add group member (GRead)
    func addGroupMemberGRead(groupId: Int, userId: Int) async throws -> EmptyResponse {
        return try await customRequest(endpoint: "/groups/\(groupId)/members/\(userId)", method: "POST", authenticated: true)
    }

    /// Remove group member (GRead)
    func removeGroupMemberGRead(groupId: Int, userId: Int) async throws -> EmptyResponse {
        return try await customRequest(endpoint: "/groups/\(groupId)/members/\(userId)", method: "DELETE", authenticated: true)
    }

    // MARK: - GRead Messages Endpoints (Custom)

    /// Get messages (GRead)
    func getMessagesGRead(page: Int = 1, perPage: Int = 20) async throws -> [Message] {
        return try await customRequest(endpoint: "/messages?page=\(page)&per_page=\(perPage)", authenticated: true)
    }

    /// Send message (GRead)
    func sendMessageGRead(recipients: [Int], subject: String, message: String) async throws -> Message {
        let body: [String: Any] = [
            "recipients": recipients,
            "subject": subject,
            "message": message
        ]
        return try await customRequest(endpoint: "/messages", method: "POST", body: body, authenticated: true)
    }

    /// Get message (GRead)
    func getMessageGRead(id: Int) async throws -> Message {
        return try await customRequest(endpoint: "/messages/\(id)", authenticated: true)
    }

    /// Delete message (GRead)
    func deleteMessageGRead(id: Int) async throws -> EmptyResponse {
        return try await customRequest(endpoint: "/messages/\(id)", method: "DELETE", authenticated: true)
    }

    // MARK: - GRead Notifications Endpoints (Custom)

    /// Get notifications (GRead)
    func getNotificationsGRead(page: Int = 1, perPage: Int = 20) async throws -> [Notification] {
        return try await customRequest(endpoint: "/notifications?page=\(page)&per_page=\(perPage)", authenticated: true)
    }

    /// Update notification (GRead)
    func updateNotificationGRead(id: Int, isNew: Bool) async throws -> Notification {
        return try await customRequest(endpoint: "/notifications/\(id)", method: "PUT", body: ["is_new": isNew], authenticated: true)
    }

    /// Delete notification (GRead)
    func deleteNotificationGRead(id: Int) async throws -> EmptyResponse {
        return try await customRequest(endpoint: "/notifications/\(id)", method: "DELETE", authenticated: true)
    }

    // MARK: - GRead Signup Endpoints (Custom)

    /// Get signups (GRead)
    func getSignupsGRead(page: Int = 1, perPage: Int = 20) async throws -> [Signup] {
        return try await customRequest(endpoint: "/signup?page=\(page)&per_page=\(perPage)", authenticated: true)
    }

    /// Create signup (GRead)
    func createSignupGRead(userLogin: String, userEmail: String, password: String) async throws -> SignupResponse {
        let body: [String: Any] = [
            "user_login": userLogin,
            "user_email": userEmail,
            "password": password
        ]
        return try await customRequest(endpoint: "/signup", method: "POST", body: body, authenticated: false)
    }

    /// Activate signup (GRead)
    func activateSignupGRead(key: String) async throws -> ActivationResponse {
        return try await customRequest(endpoint: "/signup/activate/\(key)", method: "POST", authenticated: false)
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
