import Foundation

struct LibraryItem: Codable, Identifiable {
    let id: Int
    let userId: Int
    var book: Book?
    var status: String
    var currentPage: Int
    var progressPercentage: Double
    let dateAdded: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case book
        case status
        case currentPage = "current_page"
        case progressPercentage = "progress_percentage"
        case dateAdded = "date_added"
    }
}
