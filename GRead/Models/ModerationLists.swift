import Foundation

struct BlockedListResponse: Codable {
    let success: Bool
    let blockedUsers: [Int]

    enum CodingKeys: String, CodingKey {
        case success
        case blockedUsers = "blocked_users"
    }
}

struct MutedListResponse: Codable {
    let success: Bool
    let mutedUsers: [Int]

    enum CodingKeys: String, CodingKey {
        case success
        case mutedUsers = "muted_users"
    }
}

struct ModerationResponse: Codable {
    let success: Bool
    let message: String
}
