import Foundation

/// Utility for decoding HTML entities in text
struct HTMLDecoder {
    /// Decode common HTML entities to their character equivalents
    static func decode(_ text: String) -> String {
        var result = text

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
        ]

        for (entity, character) in entities {
            result = result.replacingOccurrences(of: entity, with: character)
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
