import Foundation

class FontLoader {
    static let shared = FontLoader()

    /// Load all fonts from the Fonts directory in the app bundle
    func loadFontsFromBundle() -> [AppFont] {
        var fonts: [AppFont] = []

        // Get all JSON files from the bundle that are in the Fonts group
        guard let resourcePath = Bundle.main.resourcePath else {
            Logger.error("Could not find resource path")
            return fonts
        }

        let fontsPath = (resourcePath as NSString).appendingPathComponent("Fonts")

        // Check if Fonts directory exists
        if FileManager.default.fileExists(atPath: fontsPath) {
            Logger.debug("Found Fonts directory at: \(fontsPath)")

            do {
                let fileURLs = try FileManager.default.contentsOfDirectory(
                    atPath: fontsPath
                ).filter { $0.hasSuffix(".json") }

                for fileName in fileURLs {
                    let fullPath = (fontsPath as NSString).appendingPathComponent(fileName)
                    let fileURL = URL(fileURLWithPath: fullPath)

                    if let font = loadFontFromFile(fileURL) {
                        fonts.append(font)
                        Logger.debug("✅ Loaded font from directory: \(font.name)")
                    }
                }
            } catch {
                Logger.error("Error reading Fonts directory: \(error)")
            }
        } else {
            Logger.debug("Fonts directory not found at: \(fontsPath)")
        }

        // Fallback: Try Bundle.main.paths to find JSON files
        if fonts.isEmpty {
            Logger.debug("Attempting fallback method to find font files")

            let jsonPaths = Bundle.main.paths(forResourcesOfType: "json", inDirectory: "Fonts")
            Logger.debug("Found \(jsonPaths.count) JSON files in Fonts directory")

            for path in jsonPaths {
                let fileURL = URL(fileURLWithPath: path)
                if let font = loadFontFromFile(fileURL) {
                    fonts.append(font)
                    Logger.debug("✅ Loaded font via fallback: \(font.name)")
                }
            }
        }

        Logger.debug("Total fonts loaded from bundle: \(fonts.count)")
        return fonts
    }

    /// Load a single font from a JSON file
    func loadFontFromFile(_ fileURL: URL) -> AppFont? {
        do {
            Logger.debug("Attempting to load font from: \(fileURL.lastPathComponent)")
            let data = try Data(contentsOf: fileURL)

            let decoder = JSONDecoder()
            let font = try decoder.decode(AppFont.self, from: data)
            Logger.debug("✅ Successfully decoded font: \(font.name) (id: \(font.id))")
            return font
        } catch {
            Logger.error("❌ Error loading font from \(fileURL.lastPathComponent): \(error)")
            return nil
        }
    }

    /// Load fonts from Documents directory (user-created fonts)
    func loadFontsFromDocuments() -> [AppFont] {
        var fonts: [AppFont] = []

        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return fonts
        }

        let fontsURL = documentsURL.appendingPathComponent("GReadFonts")

        // Create directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: fontsURL.path) {
            try? FileManager.default.createDirectory(
                at: fontsURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
            Logger.debug("📁 Created GReadFonts directory in Documents")
        }

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: fontsURL,
                includingPropertiesForKeys: nil
            )

            for fileURL in fileURLs where fileURL.pathExtension == "json" {
                if let font = loadFontFromFile(fileURL) {
                    fonts.append(font)
                    Logger.debug("✅ Loaded custom font: \(font.name)")
                }
            }
        } catch {
            Logger.error("Error reading custom fonts directory: \(error)")
        }

        return fonts
    }
}

/// Extension to help create font files programmatically
extension AppFont {
    /// Export font to a JSON file
    func saveToFile(filename: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)

        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "FontError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Documents directory not found"])
        }

        let fontsURL = documentsURL.appendingPathComponent("GReadFonts")

        // Create directory if needed
        try FileManager.default.createDirectory(
            at: fontsURL,
            withIntermediateDirectories: true,
            attributes: nil
        )

        let fileURL = fontsURL.appendingPathComponent(filename)
        try data.write(to: fileURL)
        Logger.debug("✅ Font saved to: \(fileURL.path)")
    }
}
