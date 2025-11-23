import Foundation

// MARK: - Avatar Response
struct AvatarResponse: Codable {
    let full: String?
    let thumb: String?
}

// MARK: - Avatar Upload Response
struct AvatarUploadResponse: Codable {
    let full: String?
    let thumb: String?
    let message: String?
}

// MARK: - Cover Image Response
struct CoverImageResponse: Codable {
    let image: String?
    let message: String?
}
