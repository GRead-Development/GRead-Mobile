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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle id as either Int or String
        if let idInt = try? container.decode(Int.self, forKey: .id) {
            id = idInt
        } else if let idString = try? container.decode(String.self, forKey: .id) {
            id = Int(idString) ?? 0
        } else {
            id = 0
        }

        username = try container.decode(String.self, forKey: .username)
        displayName = try container.decode(String.self, forKey: .displayName)
        email = try container.decode(String.self, forKey: .email)
        avatarUrl = try container.decode(String.self, forKey: .avatarUrl)
        profileUrl = try container.decode(String.self, forKey: .profileUrl)
        mentionText = try container.decode(String.self, forKey: .mentionText)
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle activityId as either Int or String
        if let activityIdInt = try? container.decode(Int.self, forKey: .activityId) {
            activityId = activityIdInt
        } else if let activityIdString = try? container.decode(String.self, forKey: .activityId) {
            activityId = Int(activityIdString) ?? 0
        } else {
            activityId = 0
        }

        // Handle userId as either Int or String
        if let userIdInt = try? container.decode(Int.self, forKey: .userId) {
            userId = userIdInt
        } else if let userIdString = try? container.decode(String.self, forKey: .userId) {
            userId = Int(userIdString) ?? 0
        } else {
            userId = 0
        }

        userName = try container.decode(String.self, forKey: .userName)
        userAvatar = try container.decode(String.self, forKey: .userAvatar)
        content = try container.decode(String.self, forKey: .content)
        contentRaw = try container.decode(String.self, forKey: .contentRaw)
        type = try container.decode(String.self, forKey: .type)
        date = try container.decode(String.self, forKey: .date)
        timeAgo = try container.decode(String.self, forKey: .timeAgo)
        activityUrl = try container.decode(String.self, forKey: .activityUrl)
        replyCount = try container.decode(Int.self, forKey: .replyCount)
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle userId as either Int or String
        if let userIdInt = try? container.decode(Int.self, forKey: .userId) {
            userId = userIdInt
        } else if let userIdString = try? container.decode(String.self, forKey: .userId) {
            userId = Int(userIdString) ?? 0
        } else {
            userId = 0
        }

        userName = try container.decode(String.self, forKey: .userName)
        total = try container.decode(Int.self, forKey: .total)
        limit = try container.decode(Int.self, forKey: .limit)
        offset = try container.decode(Int.self, forKey: .offset)
        mentions = try container.decode([ActivityMention].self, forKey: .mentions)
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        success = try container.decode(Bool.self, forKey: .success)
        message = try container.decode(String.self, forKey: .message)

        // Handle userId as either Int or String
        if let userIdInt = try? container.decode(Int.self, forKey: .userId) {
            userId = userIdInt
        } else if let userIdString = try? container.decode(String.self, forKey: .userId) {
            userId = Int(userIdString) ?? 0
        } else {
            userId = 0
        }
    }
}
