import SwiftUI

/// Enhanced activity card with smooth animations and better interactions
struct AnimatedActivityCard: View {
    let activity: Activity
    let onUserTap: (Int) -> Void
    let onCommentsTap: () -> Void
    let onLike: () -> Void

    @Environment(\.themeColors) var themeColors
    @State private var isLiked = false
    @State private var likeCount = 0
    @State private var showContent = false
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User Header
            HStack(spacing: 12) {
                Button(action: { onUserTap(activity.userId ?? 0) }) {
                    AsyncImage(url: URL(string: activity.avatarURL)) { image in
                        image
                            .resizable()
                            .scaledToFill()
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
                    .shadow(color: themeColors.shadowColor, radius: 2, x: 0, y: 1)
                }
                .buttonStyle(ScaleButtonStyle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.bestUserName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeColors.textPrimary)

                    if let date = activity.dateRecorded {
                        Text(date.toRelativeTime())
                            .font(.caption)
                            .foregroundColor(themeColors.textSecondary)
                    }
                }

                Spacer()

                // Activity type badge
                if let type = activity.type {
                    Text(type.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(themeColors.primary.opacity(0.1))
                        .foregroundColor(themeColors.primary)
                        .cornerRadius(8)
                }
            }

            // Content with fade-in animation
            if let content = activity.content, !content.isEmpty {
                Text(content.decodingHTMLEntities.stripHTML())
                    .font(.body)
                    .foregroundColor(themeColors.textPrimary)
                    .lineLimit(nil)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 10)
                    .animation(.easeOut(duration: 0.3).delay(0.1), value: showContent)
            }

            // Interaction Buttons
            HStack(spacing: 24) {
                // Like Button with animation
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isLiked.toggle()
                        likeCount += isLiked ? 1 : -1
                    }
                    onLike()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.body)
                            .foregroundColor(isLiked ? .red : themeColors.textSecondary)
                            .scaleEffect(isLiked ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isLiked)

                        if likeCount > 0 {
                            Text("\(likeCount)")
                                .font(.caption)
                                .foregroundColor(themeColors.textSecondary)
                        }
                    }
                }

                // Comment Button
                Button(action: onCommentsTap) {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.right")
                            .font(.body)
                            .foregroundColor(themeColors.textSecondary)

                        if let children = activity.children, !children.isEmpty {
                            Text("\(children.count)")
                                .font(.caption)
                                .foregroundColor(themeColors.textSecondary)
                        }
                    }
                }
                .buttonStyle(ScaleButtonStyle())

                Spacer()
            }
            .padding(.top, 8)
        }
        .padding()
        .background(themeColors.cardBackground)
        .cornerRadius(16)
        .shadow(color: themeColors.shadowColor, radius: isPressed ? 2 : 6, x: 0, y: isPressed ? 1 : 3)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onAppear {
            withAnimation {
                showContent = true
            }
        }
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Bounce Button Style
struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
