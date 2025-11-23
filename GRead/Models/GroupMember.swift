import Foundation

// MARK: - Group Member
struct GroupMember: Codable, Identifiable {
    let id: Int
    let userId: Int?
    let userName: String?
    let userAvatar: String?
    let isAdmin: Bool?
    let isMod: Bool?
    let isBanned: Bool?
    let dateModified: String?
    let isConfirmed: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case userName = "user_name"
        case userAvatar = "user_avatar"
        case isAdmin = "is_admin"
        case isMod = "is_mod"
        case isBanned = "is_banned"
        case dateModified = "date_modified"
        case isConfirmed = "is_confirmed"
    }
}

// MARK: - Group Members Response
struct GroupMembersResponse: Codable {
    let members: [GroupMember]
    let total: Int?

    enum CodingKeys: String, CodingKey {
        case members, total
    }
}

// MARK: - Group Invite
struct GroupInvite: Codable, Identifiable {
    let id: Int
    let userId: Int?
    let itemId: Int?
    let inviterId: Int?
    let inviterName: String?
    let dateModified: String?
    let type: String?

    enum CodingKeys: String, CodingKey {
        case id, type
        case userId = "user_id"
        case itemId = "item_id"
        case inviterId = "inviter_id"
        case inviterName = "inviter_name"
        case dateModified = "date_modified"
    }
}

// MARK: - Group Membership Request
struct GroupMembershipRequest: Codable, Identifiable {
    let id: Int
    let userId: Int?
    let groupId: Int?
    let dateModified: String?
    let comments: String?

    enum CodingKeys: String, CodingKey {
        case id, comments
        case userId = "user_id"
        case groupId = "group_id"
        case dateModified = "date_modified"
    }
}
