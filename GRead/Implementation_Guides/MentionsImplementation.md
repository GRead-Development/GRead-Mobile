# Mentions System Implementation Guide

## Overview
The GRead Mentions API allows users to @mention other users in posts and comments, similar to Twitter/X. The API provides endpoints for searching users to mention, viewing mentions, and managing mention notifications.

## API Endpoints (Already Implemented in APIManager.swift)

The following endpoints are already available in your `APIManager.swift`:

1. `searchMentionUsers(query:limit:)` - Search users to mention
2. `getMentionableUsers(limit:offset:)` - Get all mentionable users
3. `getUserMentions(userId:limit:offset:)` - Get mentions for a user
4. `getMentionsActivity(userId:limit:offset:)` - Get activities with mentions
5. `getMyMentions(limit:offset:unreadOnly:)` - Get current user's mentions
6. `markMentionsAsRead()` - Mark mentions as read

## UI Implementation

### 1. Mention Text Editor Component

Create a smart text editor that detects @ symbols and shows user suggestions:

```swift
import SwiftUI
import Combine

struct MentionTextEditor: View {
    @Binding var text: String
    @Environment(\.themeColors) var themeColors

    @State private var mentionQuery = ""
    @State private var showingSuggestions = false
    @State private var suggestions: [MentionUser] = []
    @State private var cursorPosition = 0
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Text Editor
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("What's on your mind? Use @ to mention users...")
                        .foregroundColor(themeColors.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                }

                TextEditor(text: $text)
                    .focused($isFocused)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                    .onChange(of: text) { newValue in
                        handleTextChange(newValue)
                    }
            }
            .frame(minHeight: 100)
            .background(themeColors.inputBackground)
            .cornerRadius(8)

            // Mention Suggestions
            if showingSuggestions && !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Divider()

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(suggestions) { user in
                                Button(action: {
                                    insertMention(user)
                                }) {
                                    MentionSuggestionRow(user: user)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
                .background(themeColors.cardBackground)
                .cornerRadius(8)
                .shadow(color: themeColors.shadowColor, radius: 4, x: 0, y: 2)
            }
        }
    }

    private func handleTextChange(_ newValue: String) {
        // Find @ symbol and extract query
        if let range = findMentionRange(in: newValue) {
            let query = String(newValue[range])
            if query != mentionQuery {
                mentionQuery = query
                searchUsers(query: query)
            }
        } else {
            showingSuggestions = false
            mentionQuery = ""
        }
    }

    private func findMentionRange(in text: String) -> Range<String.Index>? {
        guard let cursorIndex = text.index(text.startIndex, offsetBy: cursorPosition, limitedBy: text.endIndex) else {
            return nil
        }

        // Find the last @ before cursor
        var searchIndex = cursorIndex
        while searchIndex > text.startIndex {
            let prevIndex = text.index(before: searchIndex)
            let char = text[prevIndex]

            if char == "@" {
                // Found @, extract until cursor or whitespace
                let mentionStart = searchIndex
                var mentionEnd = searchIndex

                while mentionEnd < cursorIndex {
                    let nextChar = text[mentionEnd]
                    if nextChar.isWhitespace {
                        break
                    }
                    mentionEnd = text.index(after: mentionEnd)
                }

                return mentionStart..<mentionEnd
            } else if char.isWhitespace {
                // Hit whitespace before @, no active mention
                return nil
            }

            searchIndex = prevIndex
        }

        return nil
    }

    private func searchUsers(query: String) {
        guard query.count >= 1 else {
            suggestions = []
            showingSuggestions = false
            return
        }

        Task {
            do {
                let response = try await APIManager.shared.searchMentionUsers(query: query, limit: 10)
                await MainActor.run {
                    suggestions = response.users
                    showingSuggestions = !suggestions.isEmpty
                }
            } catch {
                print("Failed to search users: \(error)")
            }
        }
    }

    private func insertMention(_ user: MentionUser) {
        // Replace the query with the selected username
        if let range = findMentionRange(in: text) {
            let beforeMention = String(text[..<text.index(before: range.lowerBound)])
            let afterMention = String(text[range.upperBound...])

            text = beforeMention + "@\(user.userLogin) " + afterMention
        }

        showingSuggestions = false
        mentionQuery = ""
        isFocused = true
    }
}

struct MentionSuggestionRow: View {
    let user: MentionUser
    @Environment(\.themeColors) var themeColors

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: user.avatarUrl)) { image in
                image.resizable()
            } placeholder: {
                Circle()
                    .fill(themeColors.primary.opacity(0.2))
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundColor(themeColors.primary)
                    }
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeColors.textPrimary)

                Text("@\(user.userLogin)")
                    .font(.caption)
                    .foregroundColor(themeColors.textSecondary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
```

### 2. Mentions Notification View

View to display when someone mentions you:

```swift
struct MentionsView: View {
    @Environment(\.themeColors) var themeColors
    @State private var mentions: [UserMention] = []
    @State private var isLoading = false
    @State private var showUnreadOnly = false

    var body: some View {
        NavigationView {
            ZStack {
                if isLoading && mentions.isEmpty {
                    ProgressView()
                } else if mentions.isEmpty {
                    emptyState
                } else {
                    mentionsList
                }
            }
            .navigationTitle("Mentions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showUnreadOnly.toggle() }) {
                            Label(
                                showUnreadOnly ? "Show All" : "Unread Only",
                                systemImage: showUnreadOnly ? "envelope.open" : "envelope.badge"
                            )
                        }

                        Button(action: {
                            Task { await markAllAsRead() }
                        }) {
                            Label("Mark All as Read", systemImage: "checkmark.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .task {
                await loadMentions()
            }
            .refreshable {
                await loadMentions()
            }
            .onChange(of: showUnreadOnly) { _ in
                Task { await loadMentions() }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "at")
                .font(.system(size: 60))
                .foregroundColor(themeColors.textSecondary)

            Text("No Mentions Yet")
                .font(.headline)

            Text("When someone mentions you, it will appear here")
                .font(.caption)
                .foregroundColor(themeColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var mentionsList: some View {
        List(mentions) { mention in
            NavigationLink(destination: MentionDetailView(mention: mention)) {
                MentionRow(mention: mention)
            }
        }
        .listStyle(.plain)
    }

    private func loadMentions() async {
        isLoading = true
        do {
            let response = try await APIManager.shared.getMyMentions(
                limit: 50,
                offset: 0,
                unreadOnly: showUnreadOnly
            )
            await MainActor.run {
                mentions = response.mentions
                isLoading = false
            }
        } catch {
            print("Failed to load mentions: \(error)")
            await MainActor.run {
                isLoading = false
            }
        }
    }

    private func markAllAsRead() async {
        do {
            _ = try await APIManager.shared.markMentionsAsRead()
            await loadMentions()
        } catch {
            print("Failed to mark as read: \(error)")
        }
    }
}

struct MentionRow: View {
    let mention: UserMention
    @Environment(\.themeColors) var themeColors

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: mention.mentionerAvatar)) { image in
                image.resizable()
            } placeholder: {
                Circle()
                    .fill(themeColors.primary.opacity(0.2))
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundColor(themeColors.primary)
                    }
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(mention.mentionerName)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("mentioned you")
                        .font(.caption)
                        .foregroundColor(themeColors.textSecondary)
                }

                if let content = mention.content {
                    Text(content.stripHTML())
                        .font(.caption)
                        .foregroundColor(themeColors.textSecondary)
                        .lineLimit(2)
                }

                if let date = mention.dateMentioned {
                    Text(date.toRelativeTime())
                        .font(.caption2)
                        .foregroundColor(themeColors.textSecondary)
                }
            }

            Spacer()

            if !mention.isRead {
                Circle()
                    .fill(themeColors.primary)
                    .frame(width: 10, height: 10)
            }
        }
        .padding(.vertical, 8)
    }
}
```

### 3. Mention Parser for Display

Utility to parse and highlight mentions in text:

```swift
import SwiftUI

struct MentionTextView: View {
    let text: String
    let onMentionTap: (String) -> Void

    @Environment(\.themeColors) var themeColors

    var body: some View {
        Text(parseTextWithMentions())
            .font(.body)
    }

    private func parseTextWithMentions() -> AttributedString {
        var attributedString = AttributedString(text)

        // Regular expression to match @username
        let pattern = "@([a-zA-Z0-9_]+)"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])

        let nsString = text as NSString
        let matches = regex?.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

        matches?.forEach { match in
            if let range = Range(match.range, in: text) {
                let username = String(text[range])

                if let attrRange = Range(match.range, in: attributedString) {
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
```

## Usage in Activity Feed

### Update NewActivityView to support mentions:

```swift
struct NewActivityWithMentionsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.themeColors) var themeColors
    @State private var content = ""
    @State private var isPosting = false

    let onPost: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Text("New Post")
                    .font(.headline)
                Spacer()
                Button("Post") {
                    Task { await postActivity() }
                }
                .disabled(content.isEmpty || isPosting)
            }
            .padding()

            // Use the mention-aware text editor
            MentionTextEditor(text: $content)
                .padding(.horizontal)

            Spacer()
        }
    }

    private func postActivity() async {
        isPosting = true
        do {
            let body: [String: Any] = [
                "content": content,
                "type": "activity_update",
                "component": "activity"
            ]

            let _: AnyCodable = try await APIManager.shared.request(
                endpoint: "/activity",
                method: "POST",
                body: body
            )

            await MainActor.run {
                onPost()
                dismiss()
            }
        } catch {
            print("Failed to post: \(error)")
            await MainActor.run {
                isPosting = false
            }
        }
    }
}
```

## Best Practices

1. **Real-time Suggestions**: Debounce the search query to avoid too many API calls
2. **Mention Highlighting**: Highlight mentions in posts with different color
3. **Clickable Mentions**: Make mentions tappable to view user profiles
4. **Notifications**: Show badge count for unread mentions
5. **Autocomplete**: Show maximum 10 suggestions to avoid overwhelming users
6. **Character Limit**: Display character count and limit for posts
7. **Keyboard Management**: Handle keyboard properly when showing suggestions

## Integration Checklist

- [x] API methods already implemented in APIManager
- [ ] Create MentionTextEditor component
- [ ] Add mentions to activity posts
- [ ] Add mentions to comments
- [ ] Create MentionsView for notifications
- [ ] Parse and highlight mentions in feed
- [ ] Add mention badge to tab bar
- [ ] Implement mention notifications
- [ ] Test mention detection and insertion
- [ ] Add analytics for mention usage

## Example: Complete Mention Flow

```swift
// 1. User types "@joh" in post composer
// 2. MentionTextEditor detects @ and calls searchMentionUsers("joh")
// 3. API returns matching users (john_doe, johnny_reader, etc.)
// 4. User selects "john_doe" from suggestions
// 5. Text is updated to include "@john_doe "
// 6. Post is submitted with mention
// 7. Backend creates mention notification for john_doe
// 8. john_doe sees notification in MentionsView
// 9. john_doe clicks to see the post mentioning them
```

## Performance Optimization

```swift
class MentionSearchDebouncer {
    private var task: Task<Void, Never>?
    private let delay: TimeInterval

    init(delay: TimeInterval = 0.3) {
        self.delay = delay
    }

    func debounce(action: @escaping () async -> Void) {
        task?.cancel()
        task = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            if !Task.isCancelled {
                await action()
            }
        }
    }
}

// Usage in MentionTextEditor:
private let searchDebouncer = MentionSearchDebouncer(delay: 0.3)

private func searchUsers(query: String) {
    searchDebouncer.debounce {
        do {
            let response = try await APIManager.shared.searchMentionUsers(query: query, limit: 10)
            await MainActor.run {
                self.suggestions = response.users
                self.showingSuggestions = !suggestions.isEmpty
            }
        } catch {
            print("Search failed: \(error)")
        }
    }
}
```
