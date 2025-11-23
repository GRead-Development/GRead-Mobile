//
//  Note.swift
//  GRead
//
//  Created for notes system API integration
//

import Foundation

// MARK: - Main Note Model
struct Note: Codable, Identifiable {
    let id: Int
    let authorId: Int
    let authorName: String
    let authorAvatar: String
    let title: String
    let content: String
    let contentRaw: String
    let excerpt: String
    let status: String
    let visibility: String
    let dateCreated: String
    let dateModified: String
    let tags: [String]
    let categories: [String]
    let attachments: [NoteAttachment]
    let likes: Int
    let views: Int
    let isLiked: Bool?
    let isPinned: Bool
    let noteUrl: String

    enum CodingKeys: String, CodingKey {
        case id
        case authorId = "author_id"
        case authorName = "author_name"
        case authorAvatar = "author_avatar"
        case title
        case content
        case contentRaw = "content_raw"
        case excerpt
        case status
        case visibility
        case dateCreated = "date_created"
        case dateModified = "date_modified"
        case tags
        case categories
        case attachments
        case likes
        case views
        case isLiked = "is_liked"
        case isPinned = "is_pinned"
        case noteUrl = "note_url"
    }
}

// MARK: - Note Attachment
struct NoteAttachment: Codable, Identifiable {
    let id: Int
    let url: String
    let fileName: String
    let fileType: String
    let fileSize: Int

    enum CodingKeys: String, CodingKey {
        case id
        case url
        case fileName = "file_name"
        case fileType = "file_type"
        case fileSize = "file_size"
    }
}

// MARK: - Notes Response (List with Pagination)
struct NotesResponse: Codable {
    let total: Int
    let limit: Int
    let offset: Int
    let notes: [Note]
}

// MARK: - User Notes Response
struct UserNotesResponse: Codable {
    let userId: Int
    let userName: String
    let total: Int
    let limit: Int
    let offset: Int
    let notes: [Note]

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case userName = "user_name"
        case total
        case limit
        case offset
        case notes
    }
}

// MARK: - Create Note Request
struct CreateNoteRequest: Codable {
    let title: String
    let content: String
    let visibility: String
    let tags: [String]?
    let categories: [String]?
    let isPinned: Bool?

    enum CodingKeys: String, CodingKey {
        case title
        case content
        case visibility
        case tags
        case categories
        case isPinned = "is_pinned"
    }
}

// MARK: - Update Note Request
struct UpdateNoteRequest: Codable {
    let title: String?
    let content: String?
    let visibility: String?
    let tags: [String]?
    let categories: [String]?
    let isPinned: Bool?

    enum CodingKeys: String, CodingKey {
        case title
        case content
        case visibility
        case tags
        case categories
        case isPinned = "is_pinned"
    }
}

// MARK: - Note Creation/Update Response
struct NoteActionResponse: Codable {
    let success: Bool
    let message: String
    let note: Note?
}

// MARK: - Delete Note Response
struct DeleteNoteResponse: Codable {
    let success: Bool
    let message: String
    let noteId: Int

    enum CodingKeys: String, CodingKey {
        case success
        case message
        case noteId = "note_id"
    }
}

// MARK: - Like Note Response
struct LikeNoteResponse: Codable {
    let success: Bool
    let message: String
    let noteId: Int
    let isLiked: Bool
    let totalLikes: Int

    enum CodingKeys: String, CodingKey {
        case success
        case message
        case noteId = "note_id"
        case isLiked = "is_liked"
        case totalLikes = "total_likes"
    }
}

// MARK: - Pin Note Response
struct PinNoteResponse: Codable {
    let success: Bool
    let message: String
    let noteId: Int
    let isPinned: Bool

    enum CodingKeys: String, CodingKey {
        case success
        case message
        case noteId = "note_id"
        case isPinned = "is_pinned"
    }
}

// MARK: - Note Search Response
struct NoteSearchResponse: Codable {
    let query: String
    let total: Int
    let limit: Int
    let offset: Int
    let notes: [Note]
}

// MARK: - Note Stats
struct NoteStats: Codable {
    let totalNotes: Int
    let totalLikes: Int
    let totalViews: Int
    let averageLikesPerNote: Double
    let mostLikedNote: NoteSummary?
    let mostViewedNote: NoteSummary?
    let recentNotes: [NoteSummary]

    enum CodingKeys: String, CodingKey {
        case totalNotes = "total_notes"
        case totalLikes = "total_likes"
        case totalViews = "total_views"
        case averageLikesPerNote = "average_likes_per_note"
        case mostLikedNote = "most_liked_note"
        case mostViewedNote = "most_viewed_note"
        case recentNotes = "recent_notes"
    }
}

// MARK: - Note Summary (for stats)
struct NoteSummary: Codable, Identifiable {
    let id: Int
    let title: String
    let authorName: String
    let likes: Int
    let views: Int
    let dateCreated: String

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case authorName = "author_name"
        case likes
        case views
        case dateCreated = "date_created"
    }
}

// MARK: - Note Categories Response
struct NoteCategoriesResponse: Codable {
    let categories: [NoteCategory]
}

// MARK: - Note Category
struct NoteCategory: Codable, Identifiable {
    let id: Int
    let name: String
    let slug: String
    let count: Int
}

// MARK: - Note Tags Response
struct NoteTagsResponse: Codable {
    let tags: [NoteTag]
}

// MARK: - Note Tag
struct NoteTag: Codable, Identifiable {
    let id: Int
    let name: String
    let slug: String
    let count: Int
}
