import SwiftUI

struct MentionText: View {
    let text: String
    let onUserTap: (String) -> Void
    @Environment(\.themeColors) var themeColors

    private struct TextSegment: Identifiable {
        let id = UUID()
        let text: String
        let isMention: Bool
        let username: String?
    }

    private var segments: [TextSegment] {
        parseTextForMentions(text)
    }

    var body: some View {
        segments.map { segment in
            if segment.isMention, let username = segment.username {
                return Text("@\(username)")
                    .foregroundColor(themeColors.primary)
                    .fontWeight(.semibold)
            } else {
                return Text(segment.text)
                    .foregroundColor(themeColors.textPrimary)
            }
        }.reduce(Text(""), +)
        .onTapGesture {
            // Find which mention was tapped - for now, just show the first one
            if let firstMention = segments.first(where: { $0.isMention }),
               let username = firstMention.username {
                onUserTap(username)
            }
        }
    }

    private func parseTextForMentions(_ text: String) -> [TextSegment] {
        var segments: [TextSegment] = []
        let pattern = "@([a-zA-Z0-9_]+)"

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return [TextSegment(text: text, isMention: false, username: nil)]
        }

        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

        var lastIndex = 0

        for match in matches {
            // Add text before mention
            if match.range.location > lastIndex {
                let beforeRange = NSRange(location: lastIndex, length: match.range.location - lastIndex)
                let beforeText = nsString.substring(with: beforeRange)
                segments.append(TextSegment(text: beforeText, isMention: false, username: nil))
            }

            // Add mention
            if match.numberOfRanges > 1 {
                let usernameRange = match.range(at: 1)
                let username = nsString.substring(with: usernameRange)
                segments.append(TextSegment(text: "", isMention: true, username: username))
            }

            lastIndex = match.range.location + match.range.length
        }

        // Add remaining text
        if lastIndex < nsString.length {
            let remainingRange = NSRange(location: lastIndex, length: nsString.length - lastIndex)
            let remainingText = nsString.substring(with: remainingRange)
            segments.append(TextSegment(text: remainingText, isMention: false, username: nil))
        }

        return segments.isEmpty ? [TextSegment(text: text, isMention: false, username: nil)] : segments
    }
}

// Alternative implementation with better tap handling
struct ClickableMentionText: View {
    let text: String
    let onUserTap: (String) -> Void
    @Environment(\.themeColors) var themeColors

    private struct MentionSegment {
        let text: String
        let isMention: Bool
        let username: String?
    }

    private var segments: [MentionSegment] {
        parseText(text)
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                if segment.isMention, let username = segment.username {
                    Button {
                        onUserTap(username)
                    } label: {
                        Text("@\(username)")
                            .foregroundColor(themeColors.primary)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Text(segment.text)
                        .foregroundColor(themeColors.textPrimary)
                }
            }
        }
    }

    private func parseText(_ text: String) -> [MentionSegment] {
        var segments: [MentionSegment] = []
        let pattern = "@([a-zA-Z0-9_]+)"

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return [MentionSegment(text: text, isMention: false, username: nil)]
        }

        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

        var lastIndex = 0

        for match in matches {
            // Add text before mention
            if match.range.location > lastIndex {
                let beforeRange = NSRange(location: lastIndex, length: match.range.location - lastIndex)
                let beforeText = nsString.substring(with: beforeRange)
                if !beforeText.isEmpty {
                    segments.append(MentionSegment(text: beforeText, isMention: false, username: nil))
                }
            }

            // Add mention
            if match.numberOfRanges > 1 {
                let usernameRange = match.range(at: 1)
                let username = nsString.substring(with: usernameRange)
                segments.append(MentionSegment(text: "", isMention: true, username: username))
            }

            lastIndex = match.range.location + match.range.length
        }

        // Add remaining text
        if lastIndex < nsString.length {
            let remainingRange = NSRange(location: lastIndex, length: nsString.length - lastIndex)
            let remainingText = nsString.substring(with: remainingRange)
            if !remainingText.isEmpty {
                segments.append(MentionSegment(text: remainingText, isMention: false, username: nil))
            }
        }

        return segments.isEmpty ? [MentionSegment(text: text, isMention: false, username: nil)] : segments
    }
}
