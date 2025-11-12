import Foundation

// MARK: - Friend Request
struct FriendRequest: Codable, Identifiable {
    let id: Int
    let userId: Int
    let friendId: Int
    let initiatorId: Int
    let status: String // "pending", "accepted", "rejected"
    let createdAt: String
    let user: User?
    let friend: User?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case friendId = "friend_id"
        case initiatorId = "initiator_id"
        case status
        case createdAt = "created_at"
        case user
        case friend
    }
}

// MARK: - Friend List Response
struct FriendsListResponse: Codable {
    let success: Bool
    let friends: [User]
    let totalCount: Int?

    enum CodingKeys: String, CodingKey {
        case success
        case friends
        case totalCount = "total_count"
    }
}

// MARK: - Friend Request Response
struct FriendRequestResponse: Codable {
    let success: Bool
    let message: String
    let friendRequest: FriendRequest?

    enum CodingKeys: String, CodingKey {
        case success
        case message
        case friendRequest = "friend_request"
    }
}

// MARK: - Pending Friend Requests Response
struct PendingRequestsResponse: Codable {
    let success: Bool
    let requests: [FriendRequest]
    let totalCount: Int?

    enum CodingKeys: String, CodingKey {
        case success
        case requests
        case totalCount = "total_count"
    }
}

// MARK: - User Search Response
struct UserSearchResponse: Codable {
    let success: Bool
    let users: [User]
    let totalCount: Int?

    enum CodingKeys: String, CodingKey {
        case success
        case users
        case totalCount = "total_count"
    }
}
