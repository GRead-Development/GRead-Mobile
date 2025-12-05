import Foundation

/// Utility for decoding HTML entities in text
struct HTMLDecoder {
    /// Decode common HTML entities to their character equivalents
    static func decode(_ text: String) -> String {
        var result = text

        // First, handle backslash escaping (JSON escaping)
        result = result.replacingOccurrences(of: "\\\"", with: "\"")
        result = result.replacingOccurrences(of: "\\'", with: "'")
        result = result.replacingOccurrences(of: "\\\\", with: "\\")
        result = result.replacingOccurrences(of: "\\/", with: "/")

        // Common HTML entity replacements
        let entities: [String: String] = [
            "&#8217;": "'",      // Right single quotation mark
            "&#8216;": "'",      // Left single quotation mark
            "&#8220;": "\"",     // Left double quotation mark
            "&#8221;": "\"",     // Right double quotation mark
            "&#8212;": "—",      // Em dash
            "&#8211;": "–",      // En dash
            "&#8230;": "…",      // Ellipsis
            "&#38;": "&",        // Ampersand
            "&amp;": "&",        // Ampersand (named entity)
            "&quot;": "\"",      // Quotation mark
            "&apos;": "'",       // Apostrophe
            "&lt;": "<",         // Less than
            "&gt;": ">",         // Greater than
            "&nbsp;": " ",       // Non-breaking space
            "&#39;": "'",        // Apostrophe (numeric)
            "&#34;": "\"",       // Quote (numeric)
        ]

        for (entity, character) in entities {
            result = result.replacingOccurrences(of: entity, with: character)
        }

        // Use native HTML entity decoding for any remaining entities
        if let data = result.data(using: .utf8) {
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]
            if let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
                result = attributedString.string
            }
        }

        return result
    }
}

/// Extension for String to add HTML decoding
extension String {
    var decodingHTMLEntities: String {
        HTMLDecoder.decode(self)
    }
}
