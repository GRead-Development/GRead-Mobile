import Foundation

struct Activity: Codable, Identifiable {
    let id: Int
    let userId: Int?
    let component: String?
    let type: String?
    let action: String?
    let content: String?
    let primaryLink: String?
    let itemId: Int?
    let secondaryItemId: Int?
    let dateRecorded: String?
    let hideSitewide: Int?
    let isSpam: Int?
    let userNicename: String?
    let userLogin: String?
    let displayName: String?
    let userFullname: String?
    let userAvatar: UserAvatarUrls?
    let userEmail: String?
    let parent: Int?
    var children: [Activity]?

    struct UserAvatarUrls: Codable {
        let full: String?
        let thumb: String?
    }

    enum CodingKeys: String, CodingKey {
        case id, component, type, action, content
        case userId, primaryLink, itemId, secondaryItemId
        case dateRecorded, hideSitewide, isSpam
        case userNicename, userLogin, displayName, userFullname
        case userAvatar = "user_avatar"
        case userEmail = "user_email"
        case parent, children
    }
    
    // Custom decoder to handle potential data issues
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required field
        id = try container.decode(Int.self, forKey: .id)
        
        // Try decoding userId with multiple strategies
        if let userIdInt = try? container.decode(Int.self, forKey: .userId) {
            userId = userIdInt
        } else if let userIdString = try? container.decode(String.self, forKey: .userId),
                  let userIdInt = Int(userIdString) {
            userId = userIdInt
        } else {
            userId = nil
            print("⚠️ Warning: No userId found for activity \(id)")
        }
        
        // Optional string fields
        component = try? container.decode(String.self, forKey: .component)
        type = try? container.decode(String.self, forKey: .type)
        action = try? container.decode(String.self, forKey: .action)
        
        // Content might be wrapped in an object or be a plain string
        if let contentObj = try? container.decode([String: String].self, forKey: .content) {
            content = contentObj["rendered"] ?? contentObj["raw"]
        } else {
            content = try? container.decode(String.self, forKey: .content)
        }
        
        primaryLink = try? container.decode(String.self, forKey: .primaryLink)
        
        // Integer fields
        itemId = try? container.decode(Int.self, forKey: .itemId)
        secondaryItemId = try? container.decode(Int.self, forKey: .secondaryItemId)
        hideSitewide = try? container.decode(Int.self, forKey: .hideSitewide)
        isSpam = try? container.decode(Int.self, forKey: .isSpam)
        
        // Date as string (don't try to parse as Date object)
        dateRecorded = try? container.decode(String.self, forKey: .dateRecorded)

        // User info fields
        userNicename = try? container.decode(String.self, forKey: .userNicename)
        userLogin = try? container.decode(String.self, forKey: .userLogin)
        displayName = try? container.decode(String.self, forKey: .displayName)
        userFullname = try? container.decode(String.self, forKey: .userFullname)

        // Try decoding userAvatar as object first, then as string for backward compatibility
        if let avatarUrls = try? container.decode(UserAvatarUrls.self, forKey: .userAvatar) {
            userAvatar = avatarUrls
        } else if let avatarString = try? container.decode(String.self, forKey: .userAvatar) {
            // If it's a string, convert to UserAvatarUrls
            userAvatar = UserAvatarUrls(full: avatarString, thumb: avatarString)
        } else {
            userAvatar = nil
        }

        userEmail = try? container.decode(String.self, forKey: .userEmail)

        // Parent and children for threading
        parent = try? container.decode(Int.self, forKey: .parent)
        children = try? container.decode([Activity].self, forKey: .children)

        // Debug logging
        if displayName == nil && userLogin == nil {
            print("⚠️ Warning: Activity \(id) has no display name or user login")
        }
    }
    
    // Computed property for getting the best available name
    var bestUserName: String {
        if let name = displayName, !name.isEmpty {
            return name
        } else if let name = userFullname, !name.isEmpty {
            return name
        } else if let login = userLogin, !login.isEmpty {
            return login
        } else if let userId = userId {
            return "User \(userId)"
        } else {
            return "Unknown User"
        }
    }

    // Computed property for avatar URL
    var avatarURL: String {
        // If we have a user_avatar field from API, use it
        if let avatar = userAvatar {
            // Prefer full size, fall back to thumb
            if let full = avatar.full, !full.isEmpty {
                return full
            } else if let thumb = avatar.thumb, !thumb.isEmpty {
                return thumb
            }
        }

        // Use Gravatar based on email (like WordPress does)
        if let email = userEmail, !email.isEmpty {
            let trimmedEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if let emailData = trimmedEmail.data(using: .utf8) {
                let hash = emailData.md5Hash
                return "https://www.gravatar.com/avatar/\(hash)?s=150&d=mp"
            }
        }

        // Final fallback - use a generic avatar
        return "https://www.gravatar.com/avatar/default?d=mp&s=150"
    }
}
