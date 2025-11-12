import Foundation

class ThemeLoader {
    static let shared = ThemeLoader()

    /// Load all themes from the Themes directory in the app bundle
    func loadThemesFromBundle() -> [AppTheme] {
        var themes: [AppTheme] = []
        
        // Get all JSON files from the bundle that are in the Themes group
        guard let resourcePath = Bundle.main.resourcePath else {
            Logger.error("Could not find resource path")
            return themes
        }
        
        let themesPath = (resourcePath as NSString).appendingPathComponent("Themes")
        
        // Check if Themes directory exists
        if FileManager.default.fileExists(atPath: themesPath) {
            Logger.debug("Found Themes directory at: \(themesPath)")
            
            do {
                let fileURLs = try FileManager.default.contentsOfDirectory(
                    atPath: themesPath
                ).filter { $0.hasSuffix(".json") }
                
                for fileName in fileURLs {
                    let fullPath = (themesPath as NSString).appendingPathComponent(fileName)
                    let fileURL = URL(fileURLWithPath: fullPath)
                    
                    if let theme = loadThemeFromFile(fileURL) {
                        themes.append(theme)
                        Logger.debug("✅ Loaded theme from directory: \(theme.name)")
                    }
                }
            } catch {
                Logger.error("Error reading Themes directory: \(error)")
            }
        } else {
            Logger.warning("Themes directory not found at: \(themesPath)")
        }
        
        // Fallback: Try Bundle.main.paths to find JSON files
        if themes.isEmpty {
            Logger.debug("Attempting fallback method to find theme files")
            
            let jsonPaths = Bundle.main.paths(forResourcesOfType: "json", inDirectory: "Themes")
            Logger.debug("Found \(jsonPaths.count) JSON files in Themes directory")
            
            for path in jsonPaths {
                let fileURL = URL(fileURLWithPath: path)
                if let theme = loadThemeFromFile(fileURL) {
                    themes.append(theme)
                    Logger.debug("✅ Loaded theme via fallback: \(theme.name)")
                }
            }
        }
        
        // Last resort: Try loading by specific names
        if themes.isEmpty {
            Logger.debug("Attempting to load themes by name")
            let themeNames = ["Forest", "Lavender", "Ocean", "Sunset", "Midnight", "Cherry", "Royal", "Coral", "Mint"]
            
            for themeName in themeNames {
                if let themeURL = Bundle.main.url(forResource: themeName, withExtension: "json", subdirectory: "Themes") {
                    if let theme = loadThemeFromFile(themeURL) {
                        themes.append(theme)
                        Logger.debug("✅ Loaded theme by name: \(theme.name)")
                    }
                }
            }
        }
        
        Logger.debug("Total themes loaded from bundle: \(themes.count)")
        return themes
    }

    /// Load a single theme from a JSON file
    /// Load a single theme from a JSON file
    func loadThemeFromFile(_ fileURL: URL) -> AppTheme? {
        do {
            Logger.debug("Attempting to load theme from: \(fileURL.lastPathComponent)")
            let data = try Data(contentsOf: fileURL)
            
            // Log the raw JSON for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                Logger.debug("JSON content: \(jsonString)")
            }
            
            let decoder = JSONDecoder()
            let theme = try decoder.decode(AppTheme.self, from: data)
            Logger.debug("✅ Successfully decoded theme: \(theme.name) (id: \(theme.id))")
            return theme
        } catch {
            Logger.error("❌ Error loading theme from \(fileURL.lastPathComponent): \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    Logger.error("  Missing key: \(key.stringValue), context: \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    Logger.error("  Type mismatch for type: \(type), context: \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    Logger.error("  Value not found for type: \(type), context: \(context.debugDescription)")
                case .dataCorrupted(let context):
                    Logger.error("  Data corrupted: \(context.debugDescription)")
                @unknown default:
                    Logger.error("  Unknown decoding error")
                }
            }
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
            Logger.debug("📁 Created GReadThemes directory in Documents")
        }

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: themesURL,
                includingPropertiesForKeys: nil
            )

            for fileURL in fileURLs where fileURL.pathExtension == "json" {
                if let theme = loadThemeFromFile(fileURL) {
                    themes.append(theme)
                    Logger.debug("✅ Loaded custom theme: \(theme.name)")
                }
            }
        } catch {
            Logger.error("Error reading custom themes directory: \(error)")
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
    
    /// Debug function to see what's in the bundle
    func debugBundleContents() {
        Logger.debug("=== BUNDLE DEBUG ===")
        
        // Check resource path
        if let resourcePath = Bundle.main.resourcePath {
            Logger.debug("Resource path: \(resourcePath)")
            
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                Logger.debug("Bundle root contains: \(contents.joined(separator: ", "))")
                
                // Check if Themes exists
                let themesPath = (resourcePath as NSString).appendingPathComponent("Themes")
                if FileManager.default.fileExists(atPath: themesPath) {
                    let themeContents = try FileManager.default.contentsOfDirectory(atPath: themesPath)
                    Logger.debug("Themes directory contains: \(themeContents.joined(separator: ", "))")
                } else {
                    Logger.debug("Themes directory does NOT exist")
                }
            } catch {
                Logger.error("Error reading bundle: \(error)")
            }
        }
        
        // Check Bundle.main.paths
        let allJsons = Bundle.main.paths(forResourcesOfType: "json", inDirectory: nil)
        Logger.debug("All JSON files in bundle: \(allJsons.count)")
        for path in allJsons {
            Logger.debug("  - \((path as NSString).lastPathComponent)")
        }
        
        Logger.debug("===================")
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
        Logger.debug("✅ Theme saved to: \(fileURL.path)")
    }
}
