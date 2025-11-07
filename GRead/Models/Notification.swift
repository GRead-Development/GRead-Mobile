struct Notification: Codable, Identifiable {
    let id: Int
    let itemId: Int?
    let secondaryItemId: Int?
    let userId: Int?
    let componentName: String?
    let componentAction: String?
    let dateNotified: String?
    let isNew: Bool?
    let content: String?
    let href: String?
    let totalCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case itemId = "item_id"
        case secondaryItemId = "secondary_item_id"
        case userId = "user_id"
        case componentName = "component_name"
        case componentAction = "component_action"
        case dateNotified = "date_notified"
        case isNew = "is_new"
        case content
        case href
        case totalCount = "total_count"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode id as String first, then convert to Int
        if let idString = try? container.decode(String.self, forKey: .id) {
            id = Int(idString) ?? 0
        } else {
            id = try container.decode(Int.self, forKey: .id)
        }
        
        // Decode itemId
        if let itemIdString = try? container.decode(String.self, forKey: .itemId) {
            itemId = Int(itemIdString)
        } else {
            itemId = try? container.decode(Int.self, forKey: .itemId)
        }
        
        // Decode secondaryItemId
        if let secondaryIdString = try? container.decode(String.self, forKey: .secondaryItemId) {
            secondaryItemId = Int(secondaryIdString)
        } else {
            secondaryItemId = try? container.decode(Int.self, forKey: .secondaryItemId)
        }
        
        // Decode userId
        if let userIdString = try? container.decode(String.self, forKey: .userId) {
            userId = Int(userIdString)
        } else {
            userId = try? container.decode(Int.self, forKey: .userId)
        }
        
        // Decode totalCount
        if let totalCountString = try? container.decode(String.self, forKey: .totalCount) {
            totalCount = Int(totalCountString)
        } else {
            totalCount = try? container.decode(Int.self, forKey: .totalCount)
        }
        
        // Decode isNew (can be "1" or "0" string, or boolean)
        if let isNewString = try? container.decode(String.self, forKey: .isNew) {
            isNew = isNewString == "1" || isNewString.lowercased() == "true"
        } else if let isNewBool = try? container.decode(Bool.self, forKey: .isNew) {
            isNew = isNewBool
        } else if let isNewInt = try? container.decode(Int.self, forKey: .isNew) {
            isNew = isNewInt == 1
        } else {
            isNew = nil
        }
        
        // String fields
        componentName = try? container.decode(String.self, forKey: .componentName)
        componentAction = try? container.decode(String.self, forKey: .componentAction)
        dateNotified = try? container.decode(String.self, forKey: .dateNotified)
        content = try? container.decode(String.self, forKey: .content)
        href = try? container.decode(String.self, forKey: .href)
    }
}
