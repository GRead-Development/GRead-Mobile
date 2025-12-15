import SwiftUI

struct GuideDetailView: View {
    let guide: Guide
    @Environment(\.themeColors) var themeColors
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: guide.icon)
                            .font(.system(size: 40))
                            .foregroundColor(themeColors.primary)
                            .frame(width: 60, height: 60)
                            .background(
                                LinearGradient(
                                    colors: [themeColors.primary.opacity(0.2), themeColors.primary.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(12)

                        Spacer()
                    }

                    Text(guide.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(themeColors.textPrimary)

                    Text(guide.description)
                        .font(.subheadline)
                        .foregroundColor(themeColors.textSecondary)
                        .lineLimit(nil)
                }
                .padding()
                .background(themeColors.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(themeColors.border, lineWidth: 1)
                )

                Divider()
                    .background(themeColors.border)

                // Content Section
                VStack(alignment: .leading, spacing: 16) {
                    Text(guide.content)
                        .font(.body)
                        .foregroundColor(themeColors.textPrimary)
                        .lineSpacing(6)
                }
                .padding()
                .background(themeColors.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(themeColors.border, lineWidth: 1)
                )
            }
            .padding()
        }
        .background(themeColors.background)
        .navigationTitle("Guide")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Guides List View
struct GuidesListView: View {
    @Environment(\.themeColors) var themeColors
    @ObservedObject var guidesManager = GuidesManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if guidesManager.guides.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 50))
                            .foregroundColor(themeColors.textSecondary)

                        Text("No guides available")
                            .font(.headline)
                            .foregroundColor(themeColors.textPrimary)

                        Text("Check back later for helpful guides")
                            .font(.subheadline)
                            .foregroundColor(themeColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else {
                    ForEach(guidesManager.guides) { guide in
                        NavigationLink(destination: GuideDetailView(guide: guide)) {
                            GuideCard(guide: guide)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding()
        }
        .background(themeColors.background)
        .navigationTitle("How to use GRead")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await guidesManager.loadGuidesIfNeeded()
        }
    }
}

// MARK: - Guide Card Component
struct GuideCard: View {
    let guide: Guide
    @Environment(\.themeColors) var themeColors

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: guide.icon)
                .font(.system(size: 24))
                .foregroundColor(themeColors.primary)
                .frame(width: 50, height: 50)
                .background(
                    LinearGradient(
                        colors: [themeColors.primary.opacity(0.2), themeColors.primary.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(10)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(guide.title)
                    .font(.headline)
                    .foregroundColor(themeColors.textPrimary)

                Text(guide.description)
                    .font(.caption)
                    .foregroundColor(themeColors.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            // Arrow
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(themeColors.textSecondary)
        }
        .padding()
        .background(themeColors.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeColors.border, lineWidth: 1)
        )
    }
}

#Preview {
    let sampleGuide = Guide(
        id: 1,
        title: "Getting Started",
        description: "Learn how to use GRead and track your reading progress",
        icon: "book.fill",
        content: "Welcome to GRead! This guide will help you get started with tracking your reading.\n\n1. Add books to your library\n2. Track your reading progress\n3. Share with friends",
        order: 1,
        category: "Basics"
    )

    return GuideDetailView(guide: sampleGuide)
}
