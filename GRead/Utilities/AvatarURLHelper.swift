import Foundation

/// Helper utility for constructing and validating avatar URLs
struct AvatarURLHelper {
    private static let baseURL = "https://gread.fun"

    /// Converts an avatar URL string to a valid URL object
    /// Handles both absolute and relative paths
    static func resolveAvatarURL(_ urlString: String?) -> URL? {
        guard let urlString = urlString, !urlString.isEmpty else {
            return nil
        }

        // If it already has a scheme (http/https), use it as-is
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
            let url = URL(string: urlString)
            Logger.debug("Avatar URL (absolute): \(urlString) - Valid: \(url != nil)")
            return url
        }

        // If it starts with /, prepend base URL
        if urlString.hasPrefix("/") {
            let fullURLString = baseURL + urlString
            let url = URL(string: fullURLString)
            Logger.debug("Avatar URL (relative /): \(fullURLString) - Valid: \(url != nil)")
            return url
        }

        // Otherwise try to construct as absolute URL with base
        let fullURLString = baseURL + "/" + urlString
        let url = URL(string: fullURLString)
        Logger.debug("Avatar URL (relative path): \(fullURLString) - Valid: \(url != nil)")
        return url
    }
}
