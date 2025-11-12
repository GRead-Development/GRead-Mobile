//
//  StatsView.swift
//  GRead
//
//  Created by apple on 11/8/25.
//

import SwiftUI

struct StatsView: View {
    let userId: Int
    @State private var stats: UserStats?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @ObservedObject var themeManager = ThemeManager.shared
    @Environment(\.themeColors) var themeColors

    var body: some View {
        Group {
            if let stats = stats {
                statsContent(stats)
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else if let errorMessage = errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(themeColors.warning)
                    Text("Failed to load stats")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(themeColors.textSecondary)
                    Button("Retry") {
                        loadStats()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.fill")
                        .font(.largeTitle)
                        .foregroundColor(themeColors.primary)
                    Text("No stats available")
                        .font(.headline)
                    Button("Load Stats") {
                        loadStats()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
        }
        .task {
            loadStats()
        }
    }

    @ViewBuilder
    private func statsContent(_ stats: UserStats) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with avatar and name
                    VStack(spacing: 12) {
                        AsyncImage(url: URL(string: stats.avatarUrl)) { image in
                            image.resizable()
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(themeColors.textSecondary)
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())

                        VStack(spacing: 4) {
                            Text(stats.displayName)
                                .font(.title2)
                                .fontWeight(.bold)

                            HStack(spacing: 12) {
                                StatBadge(
                                    label: "Points",
                                    value: "\(stats.points)",
                                    icon: "star.fill",
                                    color: themeColors.warning
                                )
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal)
                    .background(themeColors.cardBackground)

                    Divider()

                    // Stats Grid
                    VStack(spacing: 16) {
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                StatCard(
                                    label: "Books Completed",
                                    value: "\(stats.booksCompleted)",
                                    icon: "checkmark.circle.fill",
                                    color: themeColors.success
                                )
                                StatCard(
                                    label: "Pages Read",
                                    value: "\(stats.pagesRead)",
                                    icon: "book.fill",
                                    color: themeColors.primary
                                )
                            }

                            HStack(spacing: 12) {
                                StatCard(
                                    label: "Books Added",
                                    value: "\(stats.booksAdded)",
                                    icon: "plus.circle.fill",
                                    color: themeColors.accent
                                )
                                StatCard(
                                    label: "Approved Reports",
                                    value: "\(stats.approvedReports)",
                                    icon: "flag.fill",
                                    color: themeColors.error
                                )
                            }
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal)
                    }

                    // Unlocks Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "lock.open.fill")
                                .foregroundColor(themeColors.warning)
                            Text("Available Unlocks")
                                .font(.headline)
                        }

                        VStack(spacing: 8) {
                            ForEach(themeManager.allThemes.filter { $0.unlockRequirement != nil }) { theme in
                                if let requirement = theme.unlockRequirement {
                                    UnlockProgressRow(
                                        title: theme.name,
                                        icon: "paintpalette.fill",
                                        stats: stats,
                                        requirement: requirement
                                    )
                                }
                            }
                        }
                    }
                    .padding()
                    .background(themeColors.cardBackground)
                    .cornerRadius(12)
                    .padding()

                    Spacer(minLength: 20)
                }
            }
        }
        .task {
            // Check for new unlocks when stats load
            themeManager.checkAndUnlockCosmetics(stats: stats)
        }
    }

    private func loadStats() {
        Task {
            isLoading = true
            errorMessage = nil

            do {
                stats = try await APIManager.shared.getUserStats(userId: userId)
            } catch {
                errorMessage = error.localizedDescription
            }

            isLoading = false
        }
    }
}

// MARK: - Components

struct StatCard: View {
    @Environment(\.themeColors) var themeColors
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundColor(themeColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(themeColors.cardBackground)
        .cornerRadius(12)
    }
}

struct StatBadge: View {
    @Environment(\.themeColors) var themeColors
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            VStack(spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(themeColors.textSecondary)
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(themeColors.background)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(themeColors.border, lineWidth: 1))
    }
}

struct UnlockProgressRow: View {
    @Environment(\.themeColors) var themeColors
    let title: String
    let icon: String
    let stats: UserStats
    let requirement: UnlockRequirement

    var currentValue: Int {
        switch requirement.stat {
        case "booksCompleted":
            return stats.booksCompleted
        case "pagesRead":
            return stats.pagesRead
        case "points":
            return stats.points
        case "booksAdded":
            return stats.booksAdded
        case "approvedReports":
            return stats.approvedReports
        default:
            return 0
        }
    }

    var isUnlocked: Bool {
        requirement.isMet(by: stats)
    }

    var progress: Double {
        guard requirement.value > 0 else { return 0 }
        return Double(currentValue) / Double(requirement.value)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(themeColors.primary)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("\(currentValue) / \(requirement.value) \(requirement.label)")
                        .font(.caption)
                        .foregroundColor(themeColors.textSecondary)
                }

                Spacer()

                if isUnlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(themeColors.success)
                        .font(.title3)
                }
            }

            // Progress bar
            ProgressView(value: min(progress, 1.0))
                .tint(isUnlocked ? themeColors.success : themeColors.primary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isUnlocked ? themeColors.success.opacity(0.1) : .white)
        .cornerRadius(8)
    }
}

#Preview {
    StatsView(userId: 1)
}
