import Foundation
import SwiftUI
import Combine
import UserNotifications

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var currentTheme: AppTheme
    @Published var userCosmetics: UserCosmetics
    @Published var availableCosmetics: [CosmeticUnlock] = []

    @Published var allThemes: [AppTheme] = []

    // MARK: - Built-in Themes (always available)

    static let defaultTheme = AppTheme(
        id: "default",
        name: "Light",
        description: "Fresh and bright light theme",
        primaryColor: "#6C5CE7",
        secondaryColor: "#A29BFE",
        accentColor: "#FF6B9D",
        backgroundColor: "#FFFFFF",
        unlockRequirement: nil
    )

    static let darkTheme = AppTheme(
        id: "dark",
        name: "Dark",
        description: "Easy on the eyes dark theme",
        primaryColor: "#A29BFE",
        secondaryColor: "#74B9FF",
        accentColor: "#FF7675",
        backgroundColor: "#1A1A2E",
        unlockRequirement: nil
    )

    // MARK: - Initialization

    private init() {
        currentTheme = ThemeManager.defaultTheme
        userCosmetics = UserCosmetics(
            activeTheme: nil,
            activeIcon: nil,
            unlockedCosmetics: []
        )

        // Load all themes from bundle and documents
        loadAllThemes()
        loadUserCosmetics()
        applyTheme(ThemeManager.defaultTheme)
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
