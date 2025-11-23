import Foundation

// MARK: - Author
struct Author: Codable, Identifiable {
    let id: Int
    let name: String
    let bio: String?
    let photoUrl: String?
    let websiteUrl: String?
    let birthDate: String?
    let nationality: String?
    let booksCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, bio, nationality
        case photoUrl = "photo_url"
        case websiteUrl = "website_url"
        case birthDate = "birth_date"
        case booksCount = "books_count"
    }
}

// MARK: - Author Response
struct AuthorResponse: Codable {
    let author: Author
}

// MARK: - Authors List Response
struct AuthorsListResponse: Codable {
    let authors: [Author]
    let total: Int?
    let page: Int?
    let perPage: Int?

    enum CodingKeys: String, CodingKey {
        case authors, total, page
        case perPage = "per_page"
    }
}
