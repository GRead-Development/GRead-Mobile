//
//  MentionsView.swift
//  GRead
//
//  Created by Claude on 11/23/25.
//

import SwiftUI

struct MentionsView: View {
    @Environment(\.themeColors) var themeColors
    @State private var mentions: [ActivityMention] = []
    @State private var isLoading = false
    @State private var showUnreadOnly = false

    var body: some View {
        NavigationView {
            ZStack {
                themeColors.background.ignoresSafeArea()

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
                            .foregroundColor(themeColors.textPrimary)
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
                .foregroundColor(themeColors.textPrimary)

            Text("When someone mentions you, it will appear here")
                .font(.caption)
                .foregroundColor(themeColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var mentionsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(mentions) { mention in
                    NavigationLink(destination: MentionDetailView(mention: mention)) {
                        MentionRow(mention: mention)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Divider()
                        .padding(.leading, 68)
                }
            }
        }
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
    let mention: ActivityMention
    @Environment(\.themeColors) var themeColors

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: mention.userAvatar)) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fill)
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
                    Text(mention.userName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeColors.textPrimary)

                    Text("mentioned you")
                        .font(.caption)
                        .foregroundColor(themeColors.textSecondary)
                }

                Text(mention.contentRaw.stripHTML())
                    .font(.caption)
                    .foregroundColor(themeColors.textSecondary)
                    .lineLimit(2)

                Text(mention.timeAgo)
                    .font(.caption2)
                    .foregroundColor(themeColors.textSecondary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

}

struct MentionDetailView: View {
    let mention: ActivityMention
    @Environment(\.themeColors) var themeColors
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    AsyncImage(url: URL(string: mention.userAvatar)) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(themeColors.primary.opacity(0.2))
                            .overlay {
                                Image(systemName: "person.fill")
                                    .foregroundColor(themeColors.primary)
                            }
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(mention.userName)
                            .font(.headline)
                            .foregroundColor(themeColors.textPrimary)

                        Text(mention.date)
                            .font(.caption)
                            .foregroundColor(themeColors.textSecondary)
                    }

                    Spacer()
                }

                Divider()

                MentionTextView(text: mention.contentRaw.stripHTML())
                    .foregroundColor(themeColors.textPrimary)

                Spacer()
            }
            .padding()
        }
        .background(themeColors.background)
        .navigationTitle("Mention")
        .navigationBarTitleDisplayMode(.inline)
    }

}

#Preview {
    MentionsView()
}
