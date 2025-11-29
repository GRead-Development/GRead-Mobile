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
    let username: String?
    let email: String?
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle id as either Int or String
        if let idInt = try? container.decode(Int.self, forKey: .id) {
            id = idInt
        } else if let idString = try? container.decode(String.self, forKey: .id),
                  let idInt = Int(idString) {
            id = idInt
        } else {
            throw DecodingError.dataCorruptedError(forKey: .id, in: container, debugDescription: "id must be an Int or String convertible to Int")
        }

        displayName = try container.decode(String.self, forKey: .displayName)
        username = try container.decodeIfPresent(String.self, forKey: .username)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        website = try container.decodeIfPresent(String.self, forKey: .website)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
        profileUrl = try container.decodeIfPresent(String.self, forKey: .profileUrl)
        registeredDate = try container.decodeIfPresent(String.self, forKey: .registeredDate)
        stats = try container.decodeIfPresent(ProfileStats.self, forKey: .stats)
        social = try container.decodeIfPresent(ProfileSocial.self, forKey: .social)
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle all fields as either Int or String
        points = try Self.decodeIntOrString(from: container, forKey: .points)
        booksCompleted = try Self.decodeIntOrString(from: container, forKey: .booksCompleted)
        pagesRead = try Self.decodeIntOrString(from: container, forKey: .pagesRead)
        booksAdded = try Self.decodeIntOrString(from: container, forKey: .booksAdded)
        approvedReports = try Self.decodeIntOrString(from: container, forKey: .approvedReports)
    }

    private static func decodeIntOrString(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Int {
        if let intValue = try? container.decode(Int.self, forKey: key) {
            return intValue
        } else if let stringValue = try? container.decode(String.self, forKey: key),
                  let intValue = Int(stringValue) {
            return intValue
        } else {
            // Default to 0 if field is missing or invalid
            return 0
        }
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle fields as either Int or String
        followersCount = try Self.decodeIntOrString(from: container, forKey: .followersCount)
        followingCount = try Self.decodeIntOrString(from: container, forKey: .followingCount)
    }

    private static func decodeIntOrString(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Int {
        if let intValue = try? container.decode(Int.self, forKey: key) {
            return intValue
        } else if let stringValue = try? container.decode(String.self, forKey: key),
                  let intValue = Int(stringValue) {
            return intValue
        } else {
            // Default to 0 if field is missing or invalid
            return 0
        }
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle id as either Int or String, default to 0 if invalid
        if let idInt = try? container.decode(Int.self, forKey: .id) {
            id = idInt
        } else if let idString = try? container.decode(String.self, forKey: .id),
                  let idInt = Int(idString) {
            id = idInt
        } else {
            // Default to 0 if id is null, missing, or invalid
            id = 0
        }

        // Handle groupId as either Int or String
        if let groupIdInt = try? container.decode(Int.self, forKey: .groupId) {
            groupId = groupIdInt
        } else if let groupIdString = try? container.decode(String.self, forKey: .groupId),
                  let groupIdInt = Int(groupIdString) {
            groupId = groupIdInt
        } else {
            groupId = 0
        }

        // Name might be missing in some responses, use empty string as default
        name = (try? container.decode(String.self, forKey: .name)) ?? ""
        value = try container.decodeIfPresent(String.self, forKey: .value)
        type = (try? container.decode(String.self, forKey: .type)) ?? "textbox"
        group = (try? container.decode(String.self, forKey: .group)) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description)

        // Handle optional Int fields as either Int or String
        canDelete = try Self.decodeOptionalIntOrString(from: container, forKey: .canDelete)
        isRequired = try Self.decodeOptionalIntOrString(from: container, forKey: .isRequired)
        order = try Self.decodeOptionalIntOrString(from: container, forKey: .order)
    }

    private static func decodeOptionalIntOrString(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Int? {
        if let intValue = try? container.decode(Int.self, forKey: key) {
            return intValue
        } else if let stringValue = try? container.decode(String.self, forKey: key),
                  let intValue = Int(stringValue) {
            return intValue
        } else {
            return nil
        }
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle id as either Int or String
        if let idInt = try? container.decode(Int.self, forKey: .id) {
            id = idInt
        } else if let idString = try? container.decode(String.self, forKey: .id),
                  let idInt = Int(idString) {
            id = idInt
        } else {
            throw DecodingError.dataCorruptedError(forKey: .id, in: container, debugDescription: "id must be an Int or String convertible to Int")
        }

        // Handle canDelete as either Int or String
        if let canDeleteInt = try? container.decode(Int.self, forKey: .canDelete) {
            canDelete = canDeleteInt
        } else if let canDeleteString = try? container.decode(String.self, forKey: .canDelete),
                  let canDeleteInt = Int(canDeleteString) {
            canDelete = canDeleteInt
        } else {
            canDelete = 0
        }

        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        fields = try container.decode([XProfileGroupField].self, forKey: .fields)
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle id as either Int or String
        if let idInt = try? container.decode(Int.self, forKey: .id) {
            id = idInt
        } else if let idString = try? container.decode(String.self, forKey: .id),
                  let idInt = Int(idString) {
            id = idInt
        } else {
            throw DecodingError.dataCorruptedError(forKey: .id, in: container, debugDescription: "id must be an Int or String convertible to Int")
        }

        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        type = try container.decode(String.self, forKey: .type)

        // Handle Int fields as either Int or String
        isRequired = try Self.decodeIntOrString(from: container, forKey: .isRequired)
        canDelete = try Self.decodeIntOrString(from: container, forKey: .canDelete)
        order = try Self.decodeIntOrString(from: container, forKey: .order)
    }

    private static func decodeIntOrString(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Int {
        if let intValue = try? container.decode(Int.self, forKey: key) {
            return intValue
        } else if let stringValue = try? container.decode(String.self, forKey: key),
                  let intValue = Int(stringValue) {
            return intValue
        } else {
            return 0
        }
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
