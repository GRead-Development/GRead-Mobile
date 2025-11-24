//
//  MentionTextView.swift
//  GRead
//
//  Created by Claude on 11/23/25.
//

import SwiftUI

struct MentionTextView: View {
    let text: String
    let onMentionTap: ((String) -> Void)?

    @Environment(\.themeColors) var themeColors

    init(text: String, onMentionTap: ((String) -> Void)? = nil) {
        self.text = text
        self.onMentionTap = onMentionTap
    }

    var body: some View {
        Text(parseTextWithMentions())
            .font(.body)
            .environment(\.openURL, OpenURLAction { url in
                if url.scheme == "mention", let username = url.host {
                    onMentionTap?(username)
                    return .handled
                }
                return .systemAction
            })
    }

    private func parseTextWithMentions() -> AttributedString {
        var attributedString = AttributedString(text)

        // Regular expression to match @username
        let pattern = "@([a-zA-Z0-9_]+)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return attributedString
        }

        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

        matches.forEach { match in
            if let range = Range(match.range, in: text) {
                let username = String(text[range].dropFirst()) // Remove @

                if let attrRange = attributedString.range(of: String(text[range])) {
                    attributedString[attrRange].foregroundColor = themeColors.primary
                    attributedString[attrRange].font = .body.weight(.semibold)
                    // Add link attribute for tapping
                    attributedString[attrRange].link = URL(string: "mention://\(username)")
                }
            }
        }

        return attributedString
    }
}

// Extension for parsing mentions in HTML content
extension String {
    func parseMentions() -> AttributedString {
        let cleanText = self.stripHTML()
        var attributedString = AttributedString(cleanText)

        let pattern = "@([a-zA-Z0-9_]+)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return attributedString
        }

        let nsString = cleanText as NSString
        let matches = regex.matches(in: cleanText, options: [], range: NSRange(location: 0, length: nsString.length))

        matches.forEach { match in
            if let range = Range(match.range, in: cleanText) {
                if let attrRange = attributedString.range(of: String(cleanText[range])) {
                    attributedString[attrRange].foregroundColor = .blue
                    attributedString[attrRange].font = .body.weight(.semibold)
                }
            }
        }

        return attributedString
    }
}
