//
//  DashboardView.swift
//  GRead
//
//  Created by apple on 11/23/25.
//


import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.themeColors) var themeColors
    @ObservedObject var dashboardManager = DashboardManager.shared
    @ObservedObject var libraryManager = LibraryManager.shared
    @State private var refreshID = UUID()

    var currentlyReading: [LibraryItem] {
        libraryManager.libraryItems.filter { $0.status == "reading" }.prefix(3).map { $0 }
    }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Welcome Header
                    welcomeHeader

                    // Quick Stats Grid
                    if let stats = dashboardManager.stats {
                        quickStatsGrid(stats: stats)
                    }

                    // Currently Reading Section
                    if !currentlyReading.isEmpty {
                        currentlyReadingSection
                    }

                    // Recent Activity Preview
                    if !dashboardManager.recentActivity.isEmpty {
                        recentActivitySection
                    }

                    // Recent Achievements
                    if !dashboardManager.achievements.isEmpty {
                        recentAchievementsSection
                    }

                    // Bottom padding to prevent tab bar overlap
                    Color.clear
                        .frame(height: 80)
                }
                .padding(.vertical)
            }
            .background(themeColors.background)
            .navigationTitle("Dashboard")
            .refreshable {
                await loadAllData()
            }
            .task {
                await loadAllDataIfNeeded()
            }
            .onChange(of: authManager.currentUser?.id) { _ in
                Task {
                    await loadAllData()
                }
            }
            .overlay {
                if dashboardManager.isLoading || libraryManager.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(themeColors.background.opacity(0.8))
                }
            }
        }
    }

    // MARK: - Welcome Header
    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back,")
                        .font(.title3)
                        .foregroundColor(themeColors.textSecondary)

                    Text(authManager.currentUser?.name ?? "Reader")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(themeColors.textPrimary)
                }

                Spacer()

                // Avatar
                AsyncImage(url: URL(string: authManager.currentUser?.avatarUrl ?? "")) { image in
                    image.resizable()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(themeColors.primary)
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [themeColors.primary.opacity(0.1), themeColors.background],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .padding(.horizontal)
    }

    // MARK: - Quick Stats Grid
    private func quickStatsGrid(stats: UserStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Stats")
                    .font(.headline)
                    .foregroundColor(themeColors.textPrimary)

                Spacer()

                NavigationLink(destination: StatsView(userId: stats.id)) {
                    Text("View All")
                        .font(.caption)
                        .foregroundColor(themeColors.primary)
                }
            }
            .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                QuickStatCard(
                    value: "\(stats.booksCompleted)",
                    label: "Books",
                    icon: "checkmark.circle.fill",
                    color: themeColors.success,
                    gradient: [themeColors.success.opacity(0.3), themeColors.success.opacity(0.1)]
                )

                QuickStatCard(
                    value: "\(stats.pagesRead)",
                    label: "Pages",
                    icon: "book.fill",
                    color: themeColors.primary,
                    gradient: [themeColors.primary.opacity(0.3), themeColors.primary.opacity(0.1)]
                )

                QuickStatCard(
                    value: "\(stats.points)",
                    label: "Points",
                    icon: "star.fill",
                    color: themeColors.warning,
                    gradient: [themeColors.warning.opacity(0.3), themeColors.warning.opacity(0.1)]
                )

                QuickStatCard(
                    value: "\(stats.booksAdded)",
                    label: "Added",
                    icon: "plus.circle.fill",
                    color: themeColors.accent,
                    gradient: [themeColors.accent.opacity(0.3), themeColors.accent.opacity(0.1)]
                )
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Currently Reading Section
    private var currentlyReadingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Currently Reading")
                    .font(.headline)
                    .foregroundColor(themeColors.textPrimary)

                Spacer()

                NavigationLink(destination: LibraryView()) {
                    Text("View Library")
                        .font(.caption)
                        .foregroundColor(themeColors.primary)
                }
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(currentlyReading, id: \.id) { item in
                        CompactBookCard(item: item)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Recent Activity Section
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Posts")
                    .font(.headline)
                    .foregroundColor(themeColors.textPrimary)

                Spacer()

                NavigationLink(destination: ActivityFeedView()) {
                    Text("View All")
                        .font(.caption)
                        .foregroundColor(themeColors.primary)
                }
            }
            .padding(.horizontal)

            VStack(spacing: 8) {
                ForEach(dashboardManager.recentActivity.prefix(3), id: \.id) { activity in
                    CompactActivityCard(activity: activity)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Recent Achievements Section
    private var recentAchievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Achievements")
                    .font(.headline)
                    .foregroundColor(themeColors.textPrimary)

                Spacer()

                NavigationLink(destination: AchievementsView()) {
                    Text("View All")
                        .font(.caption)
                        .foregroundColor(themeColors.primary)
                }
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(dashboardManager.achievements.prefix(5), id: \.id) { achievement in
                        CompactAchievementCard(achievement: achievement)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Data Loading
    private func loadAllDataIfNeeded() async {
        guard let userId = authManager.currentUser?.id else { return }

        async let dashboardTask = dashboardManager.loadDashboardIfNeeded(userId: userId)
        async let libraryTask = libraryManager.loadLibraryIfNeeded()

        _ = await [dashboardTask, libraryTask]

        await MainActor.run {
            refreshID = UUID()
        }
    }

    private func loadAllData() async {
        guard let userId = authManager.currentUser?.id else { return }

        async let dashboardTask = dashboardManager.loadDashboard(userId: userId)
        async let libraryTask = libraryManager.loadLibrary()

        _ = await [dashboardTask, libraryTask]

        await MainActor.run {
            refreshID = UUID()
        }
    }
}

// MARK: - Quick Stat Card
struct QuickStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    let gradient: [Color]
    @Environment(\.themeColors) var themeColors

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(themeColors.textPrimary)

                Text(label)
                    .font(.caption)
                    .foregroundColor(themeColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Compact Book Card
struct CompactBookCard: View {
    let item: LibraryItem
    @Environment(\.themeColors) var themeColors

    var progressPercentage: Double {
        guard let totalPages = item.book?.totalPages, totalPages > 0 else { return 0 }
        return Double(item.currentPage) / Double(totalPages)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Book Cover
            if let coverUrl = item.book?.effectiveCoverUrl, let url = URL(string: coverUrl) {
                let _ = print("🖼️ Dashboard loading cover for \(item.book?.title ?? "Unknown"): \(coverUrl)")
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 100, height: 140)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 140)
                            .clipped()
                            .cornerRadius(8)
                    case .failure(let error):
                        let _ = print("❌ Dashboard failed to load cover for \(item.book?.title ?? "Unknown"): \(error)")
                        Image(systemName: "book.fill")
                            .font(.system(size: 40))
                            .foregroundColor(themeColors.textSecondary)
                            .frame(width: 100, height: 140)
                            .background(themeColors.border.opacity(0.3))
                            .cornerRadius(8)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity)
            } else {
                Image(systemName: "book.fill")
                    .font(.system(size: 40))
                    .foregroundColor(themeColors.textSecondary)
                    .frame(width: 100, height: 140)
                    .background(themeColors.border.opacity(0.3))
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity)
            }

            Text(item.book?.title ?? "Unknown")
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
                .frame(height: 40)

            if let author = item.book?.author {
                Text(author)
                    .font(.caption)
                    .foregroundColor(themeColors.textSecondary)
                    .lineLimit(1)
            }

            VStack(alignment: .leading, spacing: 4) {
                ProgressView(value: progressPercentage)
                    .tint(themeColors.primary)

                Text("\(Int(progressPercentage * 100))% complete")
                    .font(.caption2)
                    .foregroundColor(themeColors.textSecondary)
            }
        }
        .padding()
        .frame(width: 160)
        .background(themeColors.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeColors.border, lineWidth: 1)
        )
    }
}

// MARK: - Compact Activity Card
struct CompactActivityCard: View {
    let activity: Activity
    @Environment(\.themeColors) var themeColors

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: activity.avatarURL)) { image in
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

            VStack(alignment: .leading, spacing: 4) {
                Text(activity.bestUserName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let content = activity.content {
                    Text(content.stripHTML())
                        .font(.caption)
                        .foregroundColor(themeColors.textSecondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            if let date = activity.dateRecorded {
                Text(date.toRelativeTime())
                    .font(.caption2)
                    .foregroundColor(themeColors.textSecondary)
            }
        }
        .padding()
        .background(themeColors.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Compact Achievement Card
struct CompactAchievementCard: View {
    let achievement: Achievement
    @Environment(\.themeColors) var themeColors

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: (achievement.isUnlocked ?? false) ? "trophy.fill" : "lock.fill")
                .font(.largeTitle)
                .foregroundColor((achievement.isUnlocked ?? false) ? themeColors.warning : themeColors.textSecondary)

            Text(achievement.name)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)

            if achievement.reward > 0 {
                Text("+\(achievement.reward) pts")
                    .font(.caption2)
                    .foregroundColor(themeColors.primary)
            }
        }
        .padding()
        .frame(width: 100, height: 120)
        .background(
            (achievement.isUnlocked ?? false)
                ? LinearGradient(colors: [themeColors.warning.opacity(0.2), themeColors.warning.opacity(0.05)], startPoint: .top, endPoint: .bottom)
                : LinearGradient(colors: [themeColors.cardBackground, themeColors.cardBackground], startPoint: .top, endPoint: .bottom)
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke((achievement.isUnlocked ?? false) ? themeColors.warning.opacity(0.5) : themeColors.border, lineWidth: 1)
        )
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthManager.shared)
}