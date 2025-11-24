//
//  MentionTextEditor.swift
//  GRead
//
//  Created by Claude on 11/23/25.
//

import SwiftUI
import Combine

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

struct MentionTextEditor: View {
    @Binding var text: String
    @Environment(\.themeColors) var themeColors

    @State private var mentionQuery = ""
    @State private var showingSuggestions = false
    @State private var suggestions: [UserMention] = []
    @State private var cursorPosition = 0
    @FocusState private var isFocused: Bool

    private let searchDebouncer = MentionSearchDebouncer(delay: 0.3)

    var placeholder: String = "What's on your mind? Use @ to mention users..."
    var minHeight: CGFloat = 100

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Text Editor
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
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
            .frame(minHeight: minHeight)
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
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                .padding(.top, 4)
            }
        }
    }

    private func handleTextChange(_ newValue: String) {
        // Find @ symbol and extract query
        if let query = extractMentionQuery(from: newValue) {
            if query != mentionQuery {
                mentionQuery = query
                searchUsers(query: query)
            }
        } else {
            showingSuggestions = false
            mentionQuery = ""
        }
    }

    private func extractMentionQuery(from text: String) -> String? {
        // Find the last @ symbol followed by alphanumeric characters
        let pattern = "@([a-zA-Z0-9_]*)$"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

            if let match = matches.last, match.numberOfRanges > 1 {
                let queryRange = match.range(at: 1)
                if let range = Range(queryRange, in: text) {
                    return String(text[range])
                }
            }
        }
        return nil
    }

    private func searchUsers(query: String) {
        guard query.count >= 0 else {
            suggestions = []
            showingSuggestions = false
            return
        }

        searchDebouncer.debounce {
            do {
                let response = try await APIManager.shared.searchMentionUsers(query: query.isEmpty ? " " : query, limit: 10)
                await MainActor.run {
                    self.suggestions = response.users
                    self.showingSuggestions = !self.suggestions.isEmpty
                }
            } catch {
                print("Failed to search users: \(error)")
                await MainActor.run {
                    self.suggestions = []
                    self.showingSuggestions = false
                }
            }
        }
    }

    private func insertMention(_ user: UserMention) {
        // Find and replace the @query with @username
        let pattern = "@[a-zA-Z0-9_]*$"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let nsString = text as NSString
            let range = regex.rangeOfFirstMatch(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

            if range.location != NSNotFound, let swiftRange = Range(range, in: text) {
                text.replaceSubrange(swiftRange, with: "@\(user.username) ")
            }
        }

        showingSuggestions = false
        mentionQuery = ""
        isFocused = true
    }
}

struct MentionSuggestionRow: View {
    let user: UserMention
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

                Text("@\(user.username)")
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
