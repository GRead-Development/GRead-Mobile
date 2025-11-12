import Foundation
import SwiftUI
import Combine
import UserNotifications

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var currentTheme: AppTheme
    @Published var currentFont: AppFont?
    @Published var userCosmetics: UserCosmetics
    @Published var availableCosmetics: [CosmeticUnlock] = []

    @Published var allThemes: [AppTheme] = []
    @Published var allFonts: [AppFont] = []

    // MARK: - Built-in Themes (always available)

    static let defaultTheme = AppTheme(
        id: "default",
        name: "Light",
        description: "Fresh and bright light theme",
        primaryColor: "#6C5CE7",
        secondaryColor: "#A29BFE",
        accentColor: "#FF6B9D",
        backgroundColor: "#FFFFFF",
        isDarkTheme: false,
        unlockRequirement: nil
    )

    static let darkTheme = AppTheme(
        id: "dark",
        name: "Dark",
        description: "Easy on the eyes dark theme",
        primaryColor: "#A29BFE",
        secondaryColor: "#74B9FF",
        accentColor: "#FF7675",
        backgroundColor: "#121212",
        isDarkTheme: true,
        unlockRequirement: nil
    )

    // MARK: - Built-in Fonts (always available)

    static let defaultFont = AppFont(
        id: "system",
        name: "System Default",
        description: "The standard iOS system font",
        fontFamily: ".AppleSystemUIFont",
        isDarkTheme: false,
        unlockRequirement: nil
    )

    static let serifFont = AppFont(
        id: "serif",
        name: "Serif",
        description: "A classic serif font for a traditional feel",
        fontFamily: "Georgia",
        isDarkTheme: false,
        unlockRequirement: nil
    )

    // MARK: - Initialization

    private init() {
        currentTheme = ThemeManager.defaultTheme
        currentFont = ThemeManager.defaultFont
        userCosmetics = UserCosmetics(
            activeTheme: nil,
            activeIcon: nil,
            activeFont: nil,
            unlockedCosmetics: []
        )

        // Load all themes and fonts from bundle and documents
        loadAllThemes()
        loadAllFonts()
        loadUserCosmetics()

        // Only apply default theme if no saved theme was restored
        if userCosmetics.activeTheme == nil {
            applyTheme(ThemeManager.defaultTheme)
        }

        // Only apply default font if no saved font was restored
        if userCosmetics.activeFont == nil {
            applyFont(ThemeManager.defaultFont)
        }
    }

    // MARK: - Theme Loading

    private func loadAllThemes() {
        var themes = [ThemeManager.defaultTheme, ThemeManager.darkTheme]

        // Load themes from app bundle
        let bundleThemes = ThemeLoader.shared.loadThemesFromBundle()
        themes.append(contentsOf: bundleThemes)

        // Load custom themes from Documents
        let customThemes = ThemeLoader.shared.loadThemesFromDocuments()
        themes.append(contentsOf: customThemes)

        self.allThemes = themes
        Logger.debug("Loaded \(themes.count) total themes")
    }

    /// Reload themes (useful after user adds new theme files)
    func reloadThemes() {
        loadAllThemes()
    }

    // MARK: - Font Loading

    private func loadAllFonts() {
        var fonts = [ThemeManager.defaultFont, ThemeManager.serifFont]

        // Load fonts from app bundle
        let bundleFonts = FontLoader.shared.loadFontsFromBundle()
        fonts.append(contentsOf: bundleFonts)

        // Load custom fonts from Documents
        let customFonts = FontLoader.shared.loadFontsFromDocuments()
        fonts.append(contentsOf: customFonts)

        self.allFonts = fonts
        Logger.debug("Loaded \(fonts.count) total fonts")
    }

    /// Reload fonts (useful after user adds new font files)
    func reloadFonts() {
        loadAllFonts()
    }

    // MARK: - Theme Management

    func applyTheme(_ theme: AppTheme) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentTheme = theme
        }
        saveActiveTheme(theme.id)
    }

    func setActiveTheme(_ themeId: String) {
        if let theme = allThemes.first(where: { $0.id == themeId }) {
            if userCosmetics.unlockedCosmetics.contains(themeId) || themeId == "default" {
                applyTheme(theme)
                userCosmetics.activeTheme = themeId
            }
        }
    }

    // MARK: - Font Management

    func applyFont(_ font: AppFont) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentFont = font
        }
        saveActiveFont(font.id)
    }

    func setActiveFont(_ fontId: String) {
        if let font = allFonts.first(where: { $0.id == fontId }) {
            if userCosmetics.unlockedCosmetics.contains(fontId) || fontId == "system" || fontId == "serif" {
                applyFont(font)
                userCosmetics.activeFont = fontId
            }
        }
    }

    func isFontUnlocked(_ fontId: String) -> Bool {
        return fontId == "system" || fontId == "serif" || userCosmetics.unlockedCosmetics.contains(fontId)
    }

    // MARK: - Cosmetic Management

    func checkAndUnlockCosmetics(stats: UserStats) {
        var newUnlocks: [String] = []

        // Check each theme's unlock requirement
        for theme in allThemes {
            // Skip if already unlocked
            if userCosmetics.unlockedCosmetics.contains(theme.id) {
                continue
            }

            // Check if theme has an unlock requirement
            if let requirement = theme.unlockRequirement {
                // Check if requirement is met
                if requirement.isMet(by: stats) {
                    userCosmetics.unlockedCosmetics.append(theme.id)
                    newUnlocks.append(theme.id)
                }
            }
        }

        if !newUnlocks.isEmpty {
            saveUserCosmetics()
            notifyNewUnlocks(newUnlocks)
        }
    }

    func isThemeUnlocked(_ themeId: String) -> Bool {
        return themeId == "default" || userCosmetics.unlockedCosmetics.contains(themeId)
    }

    func isIconUnlocked(_ iconId: String) -> Bool {
        return userCosmetics.unlockedCosmetics.contains(iconId)
    }

    // MARK: - Persistence

    private func loadUserCosmetics() {
        if let data = UserDefaults.standard.data(forKey: "userCosmetics") {
            if let decoded = try? JSONDecoder().decode(UserCosmetics.self, from: data) {
                userCosmetics = decoded
                if let activeTheme = decoded.activeTheme,
                   let theme = allThemes.first(where: { $0.id == activeTheme })
                {
                    currentTheme = theme
                }
                if let activeFont = decoded.activeFont,
                   let font = allFonts.first(where: { $0.id == activeFont })
                {
                    currentFont = font
                }
            }
        }
    }

    private func saveUserCosmetics() {
        if let encoded = try? JSONEncoder().encode(userCosmetics) {
            UserDefaults.standard.set(encoded, forKey: "userCosmetics")
        }
    }

    private func saveActiveTheme(_ themeId: String) {
        userCosmetics.activeTheme = themeId
        saveUserCosmetics()
    }

    private func saveActiveFont(_ fontId: String) {
        userCosmetics.activeFont = fontId
        saveUserCosmetics()
    }

    // MARK: - Notifications

    private func notifyNewUnlocks(_ unlockedIds: [String]) {
        let names = unlockedIds.compactMap { id in
            allThemes.first(where: { $0.id == id })?.name
        }

        let message = names.joined(separator: ", ")
        let notification = UNMutableNotificationContent()
        notification.title = "New Cosmetics Unlocked!"
        notification.body = "You've unlocked: \(message)"
        notification.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "unlock-\(UUID())", content: notification, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { _ in }
    }
}

// MARK: - Environment Object Helper
extension EnvironmentValues {
    @Entry var themeManager: ThemeManager = .shared
}
