import Foundation

struct Book: Codable, Identifiable {
    let id: Int
    let title: String
    let author: String?
    let description: String?
    let coverUrl: String?
    let totalPages: Int?
    let isbn: String?
    let publishedDate: String?

    enum CodingKeys: String, CodingKey {
        case id, title, author
        case description = "content"
        case coverUrl = "cover_url"
        case totalPages = "page_count"
        case isbn
        case publishedDate = "published_date"
    }
}

struct LibraryItem: Codable, Identifiable {
    let id: Int
    let book: Book?
    var currentPage: Int
    let status: String? // e.g., "reading", "completed", "paused"
    let addedDate: String?
    let lastUpdated: String?

    enum CodingKeys: String, CodingKey {
        case id
        case book
        case currentPage = "current_page"
        case status
        case addedDate = "added_date"
        case lastUpdated = "last_updated"
    }
}
