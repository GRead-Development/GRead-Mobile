import Foundation

// MARK: - Book Note
struct BookNote: Codable, Identifiable {
    let id: Int
    let bookId: Int?
    let userId: Int?
    let note: String?
    let page: Int?
    let isPublic: Bool?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, note, page
        case bookId = "book_id"
        case userId = "user_id"
        case isPublic = "is_public"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Book ISBN
struct BookISBN: Codable, Identifiable {
    let id: Int
    let bookId: Int?
    let isbn: String?
    let isbn13: String?

    enum CodingKeys: String, CodingKey {
        case id, isbn, isbn13
        case bookId = "book_id"
    }
}

// MARK: - Library Response
struct LibraryResponse: Codable {
    let items: [LibraryItem]
    let total: Int?
    let page: Int?
    let perPage: Int?

    enum CodingKeys: String, CodingKey {
        case items, total, page
        case perPage = "per_page"
    }
}

// MARK: - Progress Update Response
struct ProgressUpdateResponse: Codable {
    let success: Bool?
    let message: String?
    let currentPage: Int?

    enum CodingKeys: String, CodingKey {
        case success, message
        case currentPage = "current_page"
    }
}

// MARK: - Book Search Response
struct BookSearchResponse: Codable {
    let books: [Book]
    let total: Int?
    let page: Int?

    enum CodingKeys: String, CodingKey {
        case books, total, page
    }
}
