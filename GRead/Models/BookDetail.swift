import Foundation

struct BookDetail: Codable, Identifiable {
    let id: Int
    let title: String
    let author: String?
    let description: String?
    let isbn: String?
    let pageCount: Int?
    let publicationYear: String?
    let coverImage: String?
    let statistics: BookStatistics?

    enum CodingKeys: String, CodingKey {
        case id, title, author, description, isbn
        case pageCount = "page_count"
        case publicationYear = "publication_year"
        case coverImage = "cover_image"
        case statistics
    }

    /// Get the effective cover URL - use API provided URL, or generate from ISBN via Open Library
    var effectiveCoverUrl: String? {
        // If API provides a cover URL, use it
        if let coverImage = coverImage, !coverImage.isEmpty {
            return coverImage
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

struct BookStatistics: Codable {
    let totalReaders: Int
    let averageRating: Double
    let reviewCount: Int

    enum CodingKeys: String, CodingKey {
        case totalReaders = "total_readers"
        case averageRating = "average_rating"
        case reviewCount = "review_count"
    }
}
