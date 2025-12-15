import Foundation

struct Guide: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String
    let icon: String
    let content: String
    let order: Int
    let category: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description, icon, content, order, category
    }
}

struct GuideCategory: Codable, Identifiable {
    let id: Int
    let name: String
    let icon: String
    let order: Int

    enum CodingKeys: String, CodingKey {
        case id, name, icon, order
    }
}
