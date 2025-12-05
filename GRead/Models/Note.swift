import Foundation

struct Note: Codable, Identifiable {
    let id: Int
    let bookId: Int
    let userId: Int
    let noteText: String
    let pageNumber: Int?
    let isPublic: Bool
    let dateCreated: String
    let dateModified: String?
    let userName: String?
    let userAvatar: String?
    let likeCount: Int?
    let isLiked: Bool?

    enum CodingKeys: String, CodingKey {
        case id, bookId, userId, noteText, pageNumber, isPublic
        case dateCreated, dateModified, userName, userAvatar
        case likeCount, isLiked
    }
}

struct NotesResponse: Codable {
    let success: Bool
    let count: Int?
    let notes: [Note]?
}

struct NoteResponse: Codable {
    let success: Bool
    let note: Note?
    let message: String?
}

struct NoteLikeResponse: Codable {
    let success: Bool
    let likeCount: Int
    let message: String?
}
