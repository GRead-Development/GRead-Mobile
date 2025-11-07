struct BPGroup: Codable, Identifiable {
    let id: Int
    let creatorId: Int?
    let name: String
    let link: String?
    let description: GroupDescription?
    let slug: String?
    let status: String?
    let dateCreated: String?
    let parentId: Int?
    let enableForum: Int?
    let totalMemberCount: Int?
    let avatarUrls: AvatarUrls?
    let args: String?
    
    struct GroupDescription: Codable {
        let rendered: String?
        let raw: String?
        
        // Custom init to handle plain string descriptions
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let string = try? container.decode(String.self) {
                // If it's just a plain string
                self.rendered = string
                self.raw = string
            } else {
                // If it's an object with rendered/raw
                let dict = try decoder.container(keyedBy: CodingKeys.self)
                self.rendered = try? dict.decode(String.self, forKey: .rendered)
                self.raw = try? dict.decode(String.self, forKey: .raw)
            }
        }
        
        enum CodingKeys: String, CodingKey {
            case rendered, raw
        }
    }
    
    struct AvatarUrls: Codable {
        let full: String?
        let thumb: String?
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, link, description, slug, status, args
        case creatorId = "creator_id"
        case dateCreated = "date_created"
        case parentId = "parent_id"
        case enableForum = "enable_forum"
        case totalMemberCount = "total_member_count"
        case avatarUrls = "avatar_urls"
    }
}
