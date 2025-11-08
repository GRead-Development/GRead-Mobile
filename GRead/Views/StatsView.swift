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
                        .foregroundColor(.orange)
                    Text("Failed to load stats")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.gray)
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
                        .foregroundColor(.blue)
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
            await loadStats()
        }
    }

    @ViewBuilder
    private func statsContent(_ stats: UserStats) -> some View {
        VStack(spacing: 0) {
            // Header with avatar and name
            VStack(spacing: 12) {
                AsyncImage(url: URL(string: stats.avatarUrl)) { image in
                    image.resizable()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.gray)
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
                            color: .yellow
                        )
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal)
            .background(Color(.systemGray6))

            Divider()

            // Stats Grid
            VStack(spacing: 16) {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        StatCard(
                            label: "Books Completed",
                            value: "\(stats.booksCompleted)",
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                        StatCard(
                            label: "Pages Read",
                            value: "\(stats.pagesRead)",
                            icon: "book.fill",
                            color: .blue
                        )
                    }

                    HStack(spacing: 12) {
                        StatCard(
                            label: "Books Added",
                            value: "\(stats.booksAdded)",
                            icon: "plus.circle.fill",
                            color: .purple
                        )
                        StatCard(
                            label: "Approved Reports",
                            value: "\(stats.approvedReports)",
                            icon: "flag.fill",
                            color: .red
                        )
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal)
            }

            Spacer()
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
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StatBadge: View {
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
                    .foregroundColor(.gray)
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray3), lineWidth: 1))
    }
}

#Preview {
    StatsView(userId: 1)
}
