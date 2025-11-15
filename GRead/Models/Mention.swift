import Foundation

// MARK: - User Mention
struct UserMention: Codable, Identifiable {
    let id: Int
    let username: String
    let displayName: String
    let email: String
    let avatarUrl: String
    let profileUrl: String
    let mentionText: String

    enum CodingKeys: String, CodingKey {
        case id, username, email
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case profileUrl = "profile_url"
        case mentionText = "mention_text"
    }
}

// MARK: - Activity Mention
struct ActivityMention: Codable, Identifiable {
    let activityId: Int
    let userId: Int
    let userName: String
    let userAvatar: String
    let content: String
    let contentRaw: String
    let type: String
    let date: String
    let timeAgo: String
    let activityUrl: String
    let replyCount: Int

    var id: Int { activityId }

    enum CodingKeys: String, CodingKey {
        case activityId = "activity_id"
        case userId = "user_id"
        case userName = "user_name"
        case userAvatar = "user_avatar"
        case content
        case contentRaw = "content_raw"
        case type, date
        case timeAgo = "time_ago"
        case activityUrl = "activity_url"
        case replyCount = "reply_count"
    }
}

// MARK: - Mention Search Response
struct MentionSearchResponse: Codable {
    let query: String
    let total: Int
    let users: [UserMention]
}

// MARK: - Mention Users Response
struct MentionUsersResponse: Codable {
    let total: Int
    let limit: Int
    let offset: Int
    let users: [UserMention]
}

// MARK: - User Mentions Response
struct UserMentionsResponse: Codable {
    let userId: Int
    let userName: String
    let total: Int
    let limit: Int
    let offset: Int
    let mentions: [ActivityMention]

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case userName = "user_name"
        case total, limit, offset, mentions
    }
}

// MARK: - Mentions Activity Response
struct MentionsActivityResponse: Codable {
    let total: Int
    let limit: Int
    let offset: Int
    let mentions: [ActivityMention]
}

// MARK: - Mark Mentions Read Response
struct MarkMentionsReadResponse: Codable {
    let success: Bool
    let message: String
    let userId: Int

    enum CodingKeys: String, CodingKey {
        case success, message
        case userId = "user_id"
    }
}
