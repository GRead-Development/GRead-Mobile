import Foundation
import SwiftUI

// MARK: - Custom Font Definition
struct AppFont: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let fontFamily: String      // System font name (e.g., "Georgia", "Menlo")
    let isDarkTheme: Bool       // Whether this is meant for dark themes
    let unlockRequirement: UnlockRequirement?

    init(
        id: String,
        name: String,
        description: String,
        fontFamily: String,
        isDarkTheme: Bool = false,
        unlockRequirement: UnlockRequirement? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.fontFamily = fontFamily
        self.isDarkTheme = isDarkTheme
        self.unlockRequirement = unlockRequirement
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case fontFamily = "font_family"
        case isDarkTheme = "is_dark_theme"
        case unlockRequirement = "unlock_requirement"
    }
}

// MARK: - User Font Cosmetics
struct UserFontCosmetics: Codable {
    var activeFont: String?        // Font ID
    var unlockedFonts: [String]    // Array of unlocked font IDs

    enum CodingKeys: String, CodingKey {
        case activeFont = "active_font"
        case unlockedFonts = "unlocked_fonts"
    }

    init(activeFont: String? = nil, unlockedFonts: [String] = []) {
        self.activeFont = activeFont
        self.unlockedFonts = unlockedFonts
    }
}
