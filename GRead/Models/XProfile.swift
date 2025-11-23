import Foundation

// MARK: - XProfile Field Group
struct XProfileGroup: Codable, Identifiable {
    let id: Int
    let name: String?
    let description: String?
    let groupOrder: Int?
    let canDelete: Bool?
    let fields: [XProfileField]?

    enum CodingKeys: String, CodingKey {
        case id, name, description, fields
        case groupOrder = "group_order"
        case canDelete = "can_delete"
    }
}

// MARK: - XProfile Field
struct XProfileField: Codable, Identifiable {
    let id: Int
    let groupId: Int?
    let parentId: Int?
    let type: String?
    let name: String?
    let description: String?
    let isRequired: Bool?
    let canDelete: Bool?
    let fieldOrder: Int?
    let optionOrder: Int?
    let orderBy: String?
    let isDefaultOption: Bool?
    let defaultVisibility: String?
    let allowCustomVisibility: String?
    let doAutolink: String?
    let options: [String]?

    enum CodingKeys: String, CodingKey {
        case id, name, description, type, options
        case groupId = "group_id"
        case parentId = "parent_id"
        case isRequired = "is_required"
        case canDelete = "can_delete"
        case fieldOrder = "field_order"
        case optionOrder = "option_order"
        case orderBy = "order_by"
        case isDefaultOption = "is_default_option"
        case defaultVisibility = "default_visibility"
        case allowCustomVisibility = "allow_custom_visibility"
        case doAutolink = "do_autolink"
    }
}

// MARK: - XProfile Data
struct XProfileData: Codable {
    let fieldId: Int?
    let userId: Int?
    let value: AnyCodable?
    let lastUpdated: String?

    enum CodingKeys: String, CodingKey {
        case value
        case fieldId = "field_id"
        case userId = "user_id"
        case lastUpdated = "last_updated"
    }
}

// MARK: - Member XProfile Response
struct MemberXProfileResponse: Codable {
    let groups: [XProfileGroup]?
}
