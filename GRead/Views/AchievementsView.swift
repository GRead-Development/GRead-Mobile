//
//  AchievementsView.swift
//  GRead
//
//  Created by apple on 11/15/25.
//

import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var achievements: UserAchievementsResponse?
    @State private var leaderboard: [LeaderboardEntry] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedFilter: AchievementFilter = .all
    @State private var showLeaderboard = false
    @Environment(\.themeColors) var themeColors

    enum AchievementFilter: String, CaseIterable {
        case all = "All"
        case unlocked = "Unlocked"
        case locked = "Locked"

        var apiValue: String {
            switch self {
            case .all: return "all"
            case .unlocked: return "unlocked"
            case .locked: return "locked"
            }
        }
    }

    var body: some View {
        ZStack {
            themeColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                if authManager.isAuthenticated {
                    authenticatedContent
                } else {
                    guestContent
                }
            }
        }
        .navigationTitle("Achievements")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showLeaderboard.toggle() }) {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(themeColors.primary)
                }
            }
        }
        .sheet(isPresented: $showLeaderboard) {
            LeaderboardView()
                .environmentObject(authManager)
        }
    }

    private var authenticatedContent: some View {
        Group {
            if let achievements = achievements {
                achievementsContent(achievements)
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else if let errorMessage = errorMessage {
                errorView(errorMessage)
            } else {
                emptyView
            }
        }
        .task {
            await loadAchievements()
        }
    }

    private var guestContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 80))
                .foregroundColor(themeColors.primary.opacity(0.5))

            Text("Sign in to track achievements")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Create an account to unlock achievements and compete on the leaderboard")
                .font(.body)
                .foregroundColor(themeColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button("View Leaderboard") {
                showLeaderboard = true
            }
            .buttonStyle(.borderedProminent)
            .tint(themeColors.primary)
            .padding(.top)
        }
        .padding()
    }

    @ViewBuilder
    private func achievementsContent(_ data: UserAchievementsResponse) -> some View {
        VStack(spacing: 0) {
            // Header stats
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(data.unlockedCount)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(themeColors.primary)
                    Text("Unlocked")
                        .font(.caption)
                        .foregroundColor(themeColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(themeColors.cardBackground)
                .cornerRadius(12)

                VStack(spacing: 4) {
                    Text("\(data.total)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(themeColors.accent)
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(themeColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(themeColors.cardBackground)
                .cornerRadius(12)
            }
            .padding()

            // Filter picker
            Picker("Filter", selection: $selectedFilter) {
                ForEach(AchievementFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: selectedFilter) { _ in
                Task {
                    await loadAchievements()
                }
            }

            // Achievements list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredAchievements) { achievement in
                        AchievementCard(achievement: achievement)
                    }
                }
                .padding()
            }
        }
    }

    private var filteredAchievements: [Achievement] {
        guard let achievements = achievements?.achievements else { return [] }
        return achievements
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(themeColors.warning)
            Text("Failed to load achievements")
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundColor(themeColors.textSecondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task {
                    await loadAchievements()
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .font(.largeTitle)
                .foregroundColor(themeColors.primary)
            Text("No achievements yet")
                .font(.headline)
            Button("Load Achievements") {
                Task {
                    await loadAchievements()
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private func loadAchievements() async {
        isLoading = true
        errorMessage = nil

        do {
            // Get current user ID from auth manager
            guard let userId = authManager.currentUser?.id else {
                errorMessage = "User not logged in"
                isLoading = false
                return
            }

            // Use the user-specific endpoint since /me/achievements doesn't exist
            achievements = try await APIManager.shared.getUserAchievements(userId: userId, filter: selectedFilter.apiValue)
        } catch {
            // If it fails, provide helpful error message
            if let apiError = error as? APIError {
                switch apiError {
                case .httpError(404):
                    errorMessage = "Achievement endpoints not available. Please contact the administrator."
                default:
                    errorMessage = error.localizedDescription
                }
            } else {
                errorMessage = error.localizedDescription
            }

            Logger.error("Failed to load achievements: \(error.localizedDescription)")

            // Log the full error for debugging
            if let urlError = error as? URLError {
                Logger.error("URL Error Code: \(urlError.code)")
            }
        }

        isLoading = false
    }
}

// MARK: - Achievement Card Component

struct AchievementCard: View {
    let achievement: Achievement
    @Environment(\.themeColors) var themeColors
    @State private var showConfetti = false

    private var isUnlocked: Bool {
        achievement.isUnlocked ?? false
    }

    private var progressPercentage: Double {
        achievement.progress?.percentage ?? 0
    }

    private var confettiColors: [Color] {
        [
            themeColors.primary,
            themeColors.secondary,
            themeColors.accent,
            Color(red: 1.0, green: 0.84, blue: 0.0), // Gold
            .green,
            .purple
        ]
    }

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(hexColor(achievement.icon.color).opacity(isUnlocked ? 1.0 : 0.3))
                    .frame(width: 60, height: 60)

                Text(achievement.icon.symbol)
                    .font(.system(size: 30))
                    .opacity(isUnlocked ? 1.0 : 0.5)
            }
            .scaleEffect(showConfetti ? 1.2 : 1.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showConfetti)

            // Details
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(achievement.name)
                        .font(.headline)
                        .foregroundColor(isUnlocked ? themeColors.textPrimary : themeColors.textSecondary)

                    Spacer()

                    if isUnlocked {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(themeColors.success)
                            .font(.title3)
                            .scaleEffect(showConfetti ? 1.3 : 1.0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showConfetti)
                    }
                }

                if !achievement.description.isEmpty {
                    Text(achievement.description)
                        .font(.caption)
                        .foregroundColor(themeColors.textSecondary)
                        .lineLimit(2)
                }

                // Progress bar for locked achievements
                if !isUnlocked, let progress = achievement.progress {
                    VStack(spacing: 4) {
                        HStack {
                            Text("\(progress.current) / \(progress.required)")
                                .font(.caption2)
                                .foregroundColor(themeColors.textSecondary)
                            Spacer()
                            Text("\(Int(progressPercentage))%")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(themeColors.primary)
                        }

                        ProgressView(value: progressPercentage / 100.0)
                            .tint(themeColors.primary)
                    }
                }

                // Reward
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(themeColors.warning)
                    Text("\(achievement.reward) points")
                        .font(.caption)
                        .foregroundColor(themeColors.textSecondary)

                    if let dateUnlocked = achievement.dateUnlocked, isUnlocked {
                        Spacer()
                        Text("Unlocked \(formatDate(dateUnlocked))")
                            .font(.caption2)
                            .foregroundColor(themeColors.textSecondary)
                    }
                }
            }
        }
        .padding()
        .background(isUnlocked ? themeColors.cardBackground : themeColors.cardBackground.opacity(0.6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isUnlocked ? themeColors.success.opacity(0.3) : themeColors.border, lineWidth: 1)
        )
        .confetti(isActive: $showConfetti, colors: confettiColors, particleCount: 30, duration: 2.5)
        .onTapGesture {
            if isUnlocked {
                triggerCelebration()
            }
        }
        .onAppear {
            // Trigger confetti for newly unlocked achievements
            if isUnlocked {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if let dateUnlocked = achievement.dateUnlocked {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                        if let date = formatter.date(from: dateUnlocked) {
                            let timeSinceUnlock = Date().timeIntervalSince(date)
                            // Only show confetti if unlocked within last 5 seconds
                            if timeSinceUnlock < 5 {
                                triggerCelebration()
                            }
                        }
                    }
                }
            }
        }
    }

    private func triggerCelebration() {
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Show confetti
        showConfetti = true
    }

    private func hexColor(_ hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (128, 128, 128)
        }
        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        guard let date = formatter.date(from: dateString) else {
            return dateString
        }

        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .hour, .minute], from: date, to: now)

        if let days = components.day, days > 0 {
            return "\(days)d ago"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)m ago"
        } else {
            return "just now"
        }
    }
}

// MARK: - Leaderboard View

struct LeaderboardView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.themeColors) var themeColors
    @State private var leaderboard: [LeaderboardEntry] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ZStack {
                themeColors.background.ignoresSafeArea()

                VStack {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let errorMessage = errorMessage {
                        errorView(errorMessage)
                    } else if leaderboard.isEmpty {
                        emptyView
                    } else {
                        leaderboardList
                    }
                }
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadLeaderboard()
            }
        }
    }

    private var leaderboardList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(leaderboard) { entry in
                    LeaderboardRow(entry: entry)
                }
            }
            .padding()
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(themeColors.warning)
            Text("Failed to load leaderboard")
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundColor(themeColors.textSecondary)
            Button("Retry") {
                Task { await loadLeaderboard() }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.fill")
                .font(.largeTitle)
                .foregroundColor(themeColors.primary)
            Text("No leaderboard data")
                .font(.headline)
        }
        .padding()
    }

    private func loadLeaderboard() async {
        isLoading = true
        errorMessage = nil

        do {
            leaderboard = try await APIManager.shared.getAchievementsLeaderboard(limit: 50)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Leaderboard Row Component

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    @Environment(\.themeColors) var themeColors

    private var rankColor: Color {
        switch entry.rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return themeColors.textSecondary
        }
    }

    private var rankIcon: String? {
        switch entry.rank {
        case 1: return "crown.fill"
        case 2: return "medal.fill"
        case 3: return "medal.fill"
        default: return nil
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            // Rank
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.2))
                    .frame(width: 40, height: 40)

                if let icon = rankIcon {
                    Image(systemName: icon)
                        .foregroundColor(rankColor)
                        .font(.title3)
                } else {
                    Text("\(entry.rank)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(rankColor)
                }
            }

            // Avatar
            AsyncImage(url: URL(string: entry.userAvatarUrl)) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(themeColors.textSecondary)
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())

            // Name and achievement count
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.userName)
                    .font(.headline)
                    .foregroundColor(themeColors.textPrimary)

                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .font(.caption2)
                        .foregroundColor(themeColors.warning)
                    Text("\(entry.achievementCount) achievements")
                        .font(.caption)
                        .foregroundColor(themeColors.textSecondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(themeColors.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(entry.rank <= 3 ? rankColor.opacity(0.3) : themeColors.border, lineWidth: 1)
        )
    }
}

#Preview {
    AchievementsView()
        .environmentObject(AuthManager.shared)
}
