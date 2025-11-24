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
