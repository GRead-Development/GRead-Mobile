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
    @ObservedObject var profileManager = ProfileManager.shared
    @State private var refreshID = UUID()
    @State private var showBarcodeScanner = false
    @State private var selectedBook: LibraryItem?
    @State private var showProgressEditor = false

    var currentlyReading: [LibraryItem] {
        libraryManager.libraryItems.filter { $0.status == "reading" }.prefix(3).map { $0 }
    }

    var closestAchievements: [Achievement] {
        // Get unearned achievements sorted by progress percentage (highest first)
        dashboardManager.achievements
            .filter { achievement in
                if let isUnlocked = achievement.isUnlocked, isUnlocked {
                    return false // Skip already unlocked
                }
                return true
            }
            .sorted { achievement1, achievement2 in
                let progress1 = achievement1.progress?.percentage ?? 0
                let progress2 = achievement2.progress?.percentage ?? 0
                return progress1 > progress2 // Higher progress first
            }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Welcome Header
                welcomeHeader

                // Quick Stats Grid
                if let stats = dashboardManager.stats {
                    quickStatsGrid(stats: stats)
                }

                // Quick Actions
                quickActionsSection

                // Currently Reading Section
                if !currentlyReading.isEmpty {
                    currentlyReadingSection
                }

                // Closest Achievements (removed Recent Posts)
                if !closestAchievements.isEmpty {
                    closestAchievementsSection
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
        .fullScreenCover(isPresented: $showBarcodeScanner) {
            BarcodeScannerView()
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showProgressEditor) {
            if let book = selectedBook {
                ProgressEditorSheet(
                    isPresented: $showProgressEditor,
                    currentPage: book.currentPage,
                    totalPages: book.book?.totalPages ?? 0,
                    onSave: { newPage in
                        updateProgress(item: book, currentPage: newPage)
                        showProgressEditor = false
                    }
                )
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

                // Avatar - uses profileManager for most up-to-date avatar
                AsyncImage(url: URL(string: profileManager.userProfile?.avatarUrl ?? authManager.currentUser?.avatarUrl ?? "")) { image in
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

    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(themeColors.textPrimary)
                .padding(.horizontal)

            HStack(spacing: 12) {
                Button(action: {
                    showBarcodeScanner = true
                }) {
                    HStack {
                        Image(systemName: "barcode.viewfinder")
                            .font(.title2)
                            .foregroundColor(themeColors.primary)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Scan Book")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(themeColors.textPrimary)
                            Text("Add by barcode")
                                .font(.caption)
                                .foregroundColor(themeColors.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
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
                .buttonStyle(PlainButtonStyle())
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
                        if let bookId = item.book?.id {
                            NavigationLink(destination: BookDetailView(bookId: bookId)) {
                                CompactBookCard(item: item, onTap: nil)
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            CompactBookCard(item: item, onTap: nil)
                        }
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

    // MARK: - Closest Achievements Section
    private var closestAchievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Almost There")
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
                    ForEach(closestAchievements, id: \.id) { achievement in
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
        async let profileTask = profileManager.loadProfileIfNeeded()

        _ = await [dashboardTask, libraryTask, profileTask]

        await MainActor.run {
            refreshID = UUID()
        }
    }

    private func loadAllData() async {
        guard let userId = authManager.currentUser?.id else { return }

        async let dashboardTask = dashboardManager.loadDashboard(userId: userId)
        async let libraryTask = libraryManager.loadLibrary()
        async let profileTask = profileManager.loadProfile()

        _ = await [dashboardTask, libraryTask, profileTask]

        await MainActor.run {
            refreshID = UUID()
        }
    }

    private func updateProgress(item: LibraryItem, currentPage: Int) {
        Task {
            do {
                guard let bookId = item.book?.id else { return }
                try await libraryManager.updateProgress(bookId: bookId, currentPage: currentPage)

                await MainActor.run {
                    refreshID = UUID()
                }
            } catch {
                Logger.error("Failed to update progress: \(error.localizedDescription)")
            }
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
    let onTap: (() -> Void)?
    @Environment(\.themeColors) var themeColors

    init(item: LibraryItem, onTap: (() -> Void)? = nil) {
        self.item = item
        self.onTap = onTap
    }

    var progressPercentage: Double {
        guard let totalPages = item.book?.totalPages, totalPages > 0 else { return 0 }
        return Double(item.currentPage) / Double(totalPages)
    }

    var body: some View {
        Button(action: {
            onTap?()
        }) {
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
        .buttonStyle(PlainButtonStyle())
        .disabled(onTap == nil)
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
