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

    /// Get the effective cover URL - use API provided URL, or generate from ISBN via Open Library
    var effectiveCoverUrl: String? {
        // If API provides a cover URL, use it
        if let coverUrl = coverUrl, !coverUrl.isEmpty {
            return coverUrl
        }

        // Otherwise, generate Open Library cover URL from ISBN
        if let isbn = isbn, !isbn.isEmpty {
            // Clean the ISBN (remove hyphens)
            let cleanISBN = isbn.replacingOccurrences(of: "-", with: "")
            return "https://covers.openlibrary.org/b/isbn/\(cleanISBN)-M.jpg"
        }

        return nil
    }
}
