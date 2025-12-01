struct User: Codable, Identifiable {
    let id: Int
    let name: String
    let link: String?
    let userLogin: String?
    let memberTypes: [String]?
    let registeredDate: String?
    let avatarUrls: [String: String]?
    let avatar: String?  // Some endpoints return avatar as a simple string

    enum CodingKeys: String, CodingKey {
        case id, name, link
        case userLogin = "user_login"
        case username  // Alternative to user_login
        case memberTypes = "member_types"
        case registeredDate = "registered_date"
        case avatarUrls = "avatar_urls"
        case avatar  // Simple avatar URL string
    }

    // Computed property to get the best avatar URL
    var avatarUrl: String {
        // First try the simple avatar string (from /members/{id} endpoint)
        if let simpleAvatar = avatar, !simpleAvatar.isEmpty {
            return simpleAvatar
        }

        // Try to get the largest avatar from avatar_urls dictionary (from /members/me endpoint)
        if let urls = avatarUrls {
            if let large = urls["96"] ?? urls["full"] {
                return large
            } else if let medium = urls["48"] {
                return medium
            } else if let small = urls["24"] ?? urls["thumb"] {
                return small
            }
        }

        // Fallback to gravatar
        return "https://www.gravatar.com/avatar/default?d=mp&s=150"
    }

    // Custom decoder to handle id being returned as string from API
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle id as either Int or String
        if let idInt = try? container.decode(Int.self, forKey: .id) {
            id = idInt
        } else if let idString = try? container.decode(String.self, forKey: .id),
                  let idInt = Int(idString) {
            id = idInt
        } else {
            throw DecodingError.dataCorruptedError(forKey: .id, in: container, debugDescription: "Could not decode id as Int or String")
        }

        name = try container.decode(String.self, forKey: .name)
        link = try? container.decode(String.self, forKey: .link)

        // Try user_login first, then fall back to username
        if let login = try? container.decode(String.self, forKey: .userLogin) {
            userLogin = login
        } else {
            userLogin = try? container.decode(String.self, forKey: .username)
        }

        memberTypes = try? container.decode([String].self, forKey: .memberTypes)
        registeredDate = try? container.decode(String.self, forKey: .registeredDate)
        avatarUrls = try? container.decode([String: String].self, forKey: .avatarUrls)
        avatar = try? container.decode(String.self, forKey: .avatar)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(link, forKey: .link)
        try container.encodeIfPresent(userLogin, forKey: .userLogin)
        try container.encodeIfPresent(memberTypes, forKey: .memberTypes)
        try container.encodeIfPresent(registeredDate, forKey: .registeredDate)
        try container.encodeIfPresent(avatarUrls, forKey: .avatarUrls)
        try container.encodeIfPresent(avatar, forKey: .avatar)
    }
}
