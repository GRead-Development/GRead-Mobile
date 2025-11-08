import Foundation

class ThemeLoader {
    static let shared = ThemeLoader()

    /// Load all themes from the Themes directory in the app bundle
    func loadThemesFromBundle() -> [AppTheme] {
        var themes: [AppTheme] = []

        // Get the Themes directory in the app bundle
        guard let themesURL = Bundle.main.url(forResource: "Themes", withExtension: nil) else {
            print("⚠️ Themes directory not found in bundle")
            return themes
        }

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: themesURL,
                includingPropertiesForKeys: nil
            )

            // Filter for JSON files and load them
            for fileURL in fileURLs where fileURL.pathExtension == "json" {
                if let theme = loadThemeFromFile(fileURL) {
                    themes.append(theme)
                    print("✅ Loaded theme: \(theme.name)")
                }
            }
        } catch {
            print("❌ Error reading Themes directory: \(error)")
        }

        return themes
    }

    /// Load a single theme from a JSON file
    private func loadThemeFromFile(_ fileURL: URL) -> AppTheme? {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let theme = try decoder.decode(AppTheme.self, from: data)
            return theme
        } catch {
            print("❌ Error loading theme from \(fileURL.lastPathComponent): \(error)")
            return nil
        }
    }

    /// Load themes from Documents directory (user-created themes)
    func loadThemesFromDocuments() -> [AppTheme] {
        var themes: [AppTheme] = []

        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return themes
        }

        let themesURL = documentsURL.appendingPathComponent("GReadThemes")

        // Create directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: themesURL.path) {
            try? FileManager.default.createDirectory(
                at: themesURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
            print("📁 Created GReadThemes directory in Documents")
        }

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: themesURL,
                includingPropertiesForKeys: nil
            )

            for fileURL in fileURLs where fileURL.pathExtension == "json" {
                if let theme = loadThemeFromFile(fileURL) {
                    themes.append(theme)
                    print("✅ Loaded custom theme: \(theme.name)")
                }
            }
        } catch {
            print("❌ Error reading custom themes directory: \(error)")
        }

        return themes
    }

    /// Get the path where users can add custom themes
    func getCustomThemesPath() -> String? {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsURL.appendingPathComponent("GReadThemes").path
    }
}

/// Extension to help create theme files programmatically
extension AppTheme {
    /// Export theme to a JSON file
    func saveToFile(filename: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)

        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "ThemeError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Documents directory not found"])
        }

        let themesURL = documentsURL.appendingPathComponent("GReadThemes")

        // Create directory if needed
        try FileManager.default.createDirectory(
            at: themesURL,
            withIntermediateDirectories: true,
            attributes: nil
        )

        let fileURL = themesURL.appendingPathComponent(filename)
        try data.write(to: fileURL)
        print("✅ Theme saved to: \(fileURL.path)")
    }
}
