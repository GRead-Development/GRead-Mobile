import Foundation

// MARK: - API Response Wrapper
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T
}

// MARK: - User Profile
struct UserProfile: Codable {
    let id: Int
    let displayName: String
    let username: String
    let email: String
    let bio: String?
    let website: String?
    let location: String?
    let avatarUrl: String?
    let profileUrl: String?
    let registeredDate: String?
    let stats: ProfileStats?
    let social: ProfileSocial?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case username
        case email
        case bio
        case website
        case location
        case avatarUrl = "avatar_url"
        case profileUrl = "profile_url"
        case registeredDate = "registered_date"
        case stats
        case social
    }
}

// MARK: - Profile Stats
struct ProfileStats: Codable {
    let points: Int
    let booksCompleted: Int
    let pagesRead: Int
    let booksAdded: Int
    let approvedReports: Int

    enum CodingKeys: String, CodingKey {
        case points
        case booksCompleted = "books_completed"
        case pagesRead = "pages_read"
        case booksAdded = "books_added"
        case approvedReports = "approved_reports"
    }
}

// MARK: - Profile Social
struct ProfileSocial: Codable {
    let followersCount: Int
    let followingCount: Int

    enum CodingKeys: String, CodingKey {
        case followersCount = "followers_count"
        case followingCount = "following_count"
    }
}

// MARK: - Profile Update Request
struct ProfileUpdateRequest: Codable {
    let displayName: String?
    let bio: String?
    let website: String?
    let location: String?

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case bio
        case website
        case location
    }
}

// MARK: - Extended Profile Field
struct XProfileField: Codable, Identifiable {
    let id: Int
    let name: String
    let value: String?
    let type: String
    let groupId: Int
    let group: String
    let description: String?
    let canDelete: Int?
    let isRequired: Int?
    let order: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case value
        case type
        case groupId = "group_id"
        case group
        case description
        case canDelete = "can_delete"
        case isRequired = "is_required"
        case order
    }
}

// MARK: - Extended Profile Field Update
struct XProfileFieldUpdate: Codable {
    let fieldId: Int
    let value: String
    let visibility: String?

    enum CodingKeys: String, CodingKey {
        case fieldId = "field_id"
        case value
        case visibility
    }
}

// MARK: - Extended Profile Group
struct XProfileGroup: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let canDelete: Int
    let fields: [XProfileGroupField]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case canDelete = "can_delete"
        case fields
    }
}

// MARK: - Extended Profile Group Field
struct XProfileGroupField: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let type: String
    let isRequired: Int
    let canDelete: Int
    let order: Int

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case type
        case isRequired = "is_required"
        case canDelete = "can_delete"
        case order
    }
}

// MARK: - Extended Profile Response
struct XProfileFieldsData: Codable {
    let fields: [String: XProfileField]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        fields = try container.decode([String: XProfileField].self)
    }
}
