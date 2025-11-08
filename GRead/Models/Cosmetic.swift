import Foundation
import SwiftUI

// MARK: - Cosmetic Types
enum CosmeticType: String, Codable {
    case theme
    case icon
    case badge
    case profileFrame
}

// MARK: - Unlock Requirement
struct UnlockRequirement: Codable {
    let stat: String // "booksCompleted", "pagesRead", "points", "booksAdded", "approvedReports"
    let value: Int

    enum CodingKeys: String, CodingKey {
        case stat
        case value
    }

    // Helper to check if stats meet requirement
    func isMet(by stats: UserStats) -> Bool {
        switch stat {
        case "booksCompleted":
            return stats.booksCompleted >= value
        case "pagesRead":
            return stats.pagesRead >= value
        case "points":
            return stats.points >= value
        case "booksAdded":
            return stats.booksAdded >= value
        case "approvedReports":
            return stats.approvedReports >= value
        default:
            return false
        }
    }

    // Human-readable label
    var label: String {
        switch stat {
        case "booksCompleted":
            return "Books Completed"
        case "pagesRead":
            return "Pages Read"
        case "points":
            return "Points"
        case "booksAdded":
            return "Books Added"
        case "approvedReports":
            return "Approved Reports"
        default:
            return stat
        }
    }
}

// MARK: - Theme Definition
struct AppTheme: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let primaryColor: String // Hex color
    let secondaryColor: String
    let accentColor: String
    let backgroundColor: String
    let unlockRequirement: UnlockRequirement?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case primaryColor = "primary_color"
        case secondaryColor = "secondary_color"
        case accentColor = "accent_color"
        case backgroundColor = "background_color"
        case unlockRequirement = "unlock_requirement"
    }

    // Get SwiftUI Colors from hex strings
    var primary: Color {
        Color(hex: primaryColor)
    }

    var secondary: Color {
        Color(hex: secondaryColor)
    }

    var accent: Color {
        Color(hex: accentColor)
    }

    var background: Color {
        Color(hex: backgroundColor)
    }
}

// MARK: - Custom Icon
struct CustomIcon: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let imageUrl: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case imageUrl = "image_url"
    }
}

// MARK: - Cosmetic Unlock
struct CosmeticUnlock: Codable, Identifiable {
    let id: String
    let type: CosmeticType
    let name: String
    let description: String
    let imageUrl: String?
    let unlockedAt: Date?
    let unlockedBy: String // "points", "pages_read", "books_completed", etc.
    let requiredValue: Int

    // For themes
    let theme: AppTheme?

    // For icons
    let icon: CustomIcon?

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case name
        case description
        case imageUrl = "image_url"
        case unlockedAt = "unlocked_at"
        case unlockedBy = "unlocked_by"
        case requiredValue = "required_value"
        case theme
        case icon
    }
}

// MARK: - User Cosmetics (Active selections)
struct UserCosmetics: Codable {
    var activeTheme: String? // Theme ID
    var activeIcon: String? // Icon ID
    var unlockedCosmetics: [String] // Array of unlocked cosmetic IDs

    enum CodingKeys: String, CodingKey {
        case activeTheme = "active_theme"
        case activeIcon = "active_icon"
        case unlockedCosmetics = "unlocked_cosmetics"
    }
}

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var color: UInt64 = 0
        scanner.scanHexInt64(&color)

        let r = Double((color & 0xFF0000) >> 16) / 255.0
        let g = Double((color & 0x00FF00) >> 8) / 255.0
        let b = Double(color & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
