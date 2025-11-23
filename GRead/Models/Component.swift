import Foundation

// MARK: - BuddyPress Component
struct BPComponent: Codable, Identifiable {
    let id: String
    let name: String?
    let description: String?
    let status: String?
    let title: String?

    var intId: Int {
        return id.hashValue
    }
}

// MARK: - Sitewide Notice
struct SitewideNotice: Codable, Identifiable {
    let id: Int
    let subject: String?
    let message: String?
    let dateNotified: String?
    let isActive: Bool?

    enum CodingKeys: String, CodingKey {
        case id, subject, message
        case dateNotified = "date_notified"
        case isActive = "is_active"
    }
}

// MARK: - Notice Response
struct NoticeResponse: Codable {
    let success: Bool?
    let message: String?
}
