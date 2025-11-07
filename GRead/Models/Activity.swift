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
    let userEmail: String?
    let userNicename: String?
    let userLogin: String?
    let displayName: String?
    let userFullname: String?
    
    enum CodingKeys: String, CodingKey {
        case id, component, type, action, content
        case userId = "user_id"
        case primaryLink = "primary_link"
        case itemId = "item_id"
        case secondaryItemId = "secondary_item_id"
        case dateRecorded = "date_recorded"
        case hideSitewide = "hide_sitewide"
        case isSpam = "is_spam"
        case userEmail = "user_email"
        case userNicename = "user_nicename"
        case userLogin = "user_login"
        case displayName = "display_name"
        case userFullname = "user_fullname"
    }
    
    // Custom decoder to handle potential data issues
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        
        // Try decoding userId as Int or String
        if let userIdInt = try? container.decode(Int.self, forKey: .userId) {
            userId = userIdInt
        } else if let userIdString = try? container.decode(String.self, forKey: .userId),
                  let userIdInt = Int(userIdString) {
            userId = userIdInt
        } else {
            userId = nil
        }
        
        component = try? container.decode(String.self, forKey: .component)
        type = try? container.decode(String.self, forKey: .type)
        action = try? container.decode(String.self, forKey: .action)
        content = try? container.decode(String.self, forKey: .content)
        primaryLink = try? container.decode(String.self, forKey: .primaryLink)
        itemId = try? container.decode(Int.self, forKey: .itemId)
        secondaryItemId = try? container.decode(Int.self, forKey: .secondaryItemId)
        dateRecorded = try? container.decode(String.self, forKey: .dateRecorded)
        hideSitewide = try? container.decode(Int.self, forKey: .hideSitewide)
        isSpam = try? container.decode(Int.self, forKey: .isSpam)
        userEmail = try? container.decode(String.self, forKey: .userEmail)
        userNicename = try? container.decode(String.self, forKey: .userNicename)
        userLogin = try? container.decode(String.self, forKey: .userLogin)
        displayName = try? container.decode(String.self, forKey: .displayName)
        userFullname = try? container.decode(String.self, forKey: .userFullname)
    }
}
