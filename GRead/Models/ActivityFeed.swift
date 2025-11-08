import Foundation

struct ActivityFeedResponse: Codable {
    let activities: [ActivityItem]
    let total: Int
    let hasMore: Bool

    enum CodingKeys: String, CodingKey {
        case activities
        case total
        case hasMore = "has_more"
    }
}

struct ActivityItem: Codable, Identifiable {
    let id: Int
    let userId: Int
    let userName: String
    let avatarUrl: String
    let content: String
    let action: String?
    let type: String?
    let date: String
    let dateFormatted: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case userName = "user_name"
        case avatarUrl = "avatar_url"
        case content
        case action
        case type
        case date
        case dateFormatted = "date_formatted"
    }
}
