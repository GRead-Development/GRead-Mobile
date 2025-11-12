import SwiftUI

struct UnlocksView: View {
    @ObservedObject var themeManager = ThemeManager.shared
    @Environment(\.themeColors) var themeColors
    @State private var selectedTab = 0
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                Picker("Cosmetics Type", selection: $selectedTab) {
                    Text("Themes").tag(0)
                    Text("Icons").tag(1)
                    Text("All").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                // Content based on selected tab
                if isLoading {
                    ProgressView()
                        .frame(maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(themeColors.warning)
                        Text(errorMessage)
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(themeColors.cardBackground)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            switch selectedTab {
                            case 0:
                                ThemesGridView()
                            case 1:
                                IconsGridView()
                            default:
                                ThemesGridView()
                                IconsGridView()
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Unlockables")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            await loadCosmetics()
        }
    }

    private func loadCosmetics() async {
        isLoading = true
        errorMessage = nil

        do {
            let cosmetics = try await APIManager.shared.getAvailableCosmetics()
            await MainActor.run {
                themeManager.availableCosmetics = cosmetics
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load cosmetics: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

// MARK: - Themes Grid View

struct ThemesGridView: View {
    @ObservedObject var themeManager = ThemeManager.shared
    @Environment(\.themeColors) var themeColors
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var unlockedThemes: [AppTheme] {
        themeManager.allThemes.filter { theme in
            themeManager.isThemeUnlocked(theme.id)
        }
    }

    var lockedThemes: [AppTheme] {
        themeManager.allThemes.filter { theme in
            !themeManager.isThemeUnlocked(theme.id)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !unlockedThemes.isEmpty {
                Text("Unlocked Themes")
                    .font(.headline)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(unlockedThemes) { theme in
                        ThemeCardView(theme: theme, isUnlocked: true)
                    }
                }
            }

            if !lockedThemes.isEmpty {
                if !unlockedThemes.isEmpty {
                    Divider()
                }

                Text("Locked Themes")
                    .font(.headline)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(lockedThemes) { theme in
                        LockedThemeCardView(theme: theme)
                    }
                }
            }
        }
    }
}

// MARK: - Theme Card View

struct ThemeCardView: View {
    @ObservedObject var themeManager = ThemeManager.shared
    @Environment(\.themeColors) var themeColors
    let theme: AppTheme
    let isUnlocked: Bool

    var isActive: Bool {
        themeManager.currentTheme.id == theme.id
    }

    var body: some View {
        VStack(spacing: 8) {
            // Color preview
            HStack(spacing: 4) {
                Circle()
                    .fill(theme.primary)
                Circle()
                    .fill(theme.secondary)
                Circle()
                    .fill(theme.accent)
                Circle()
                    .fill(theme.background)
                    .overlay(Circle().stroke(themeColors.textSecondary, lineWidth: 0.5))
            }
            .frame(height: 40)

            VStack(spacing: 4) {
                Text(theme.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(theme.description)
                    .font(.caption)
                    .foregroundColor(themeColors.textSecondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if isActive {
                Text("Active")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(themeColors.primary)
                    .cornerRadius(6)
            } else if isUnlocked {
                Button(action: {
                    themeManager.applyTheme(theme)
                }) {
                    Text("Apply")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(themeColors.cardBackground)
                        .foregroundColor(.primary)
                        .cornerRadius(6)
                }
            }
        }
        .padding(12)
        .background(isActive ? themeColors.primary.opacity(0.1) : themeColors.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? themeColors.primary : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Locked Theme Card View

struct LockedThemeCardView: View {
    @Environment(\.themeColors) var themeColors
    let theme: AppTheme

    var body: some View {
        VStack(spacing: 8) {
            // Color preview (greyed out)
            HStack(spacing: 4) {
                Circle()
                    .fill(themeColors.textSecondary.opacity(0.3))
                Circle()
                    .fill(themeColors.textSecondary.opacity(0.3))
                Circle()
                    .fill(themeColors.textSecondary.opacity(0.3))
                Circle()
                    .fill(themeColors.textSecondary.opacity(0.3))
            }
            .frame(height: 40)

            VStack(spacing: 4) {
                Text(theme.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(theme.description)
                    .font(.caption)
                    .foregroundColor(themeColors.textSecondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 4) {
                Image(systemName: "lock.fill")
                    .font(.caption)
                Text("Locked")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(themeColors.textSecondary.opacity(0.2))
            .foregroundColor(themeColors.textSecondary)
            .cornerRadius(6)
        }
        .padding(12)
        .background(themeColors.cardBackground.opacity(0.5))
        .cornerRadius(12)
        .opacity(0.7)
    }
}

// MARK: - Icons Grid View

struct IconsGridView: View {
    @ObservedObject var themeManager = ThemeManager.shared
    @Environment(\.themeColors) var themeColors
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var unlockedIcons: [String] {
        themeManager.userCosmetics.unlockedCosmetics.filter { id in
            !themeManager.allThemes.contains { $0.id == id }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Custom Icons")
                .font(.headline)

            if unlockedIcons.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 32))
                        .foregroundColor(themeColors.warning)
                    Text("No custom icons unlocked yet")
                        .font(.subheadline)
                    Text("Unlock more cosmetics by progressing in the app")
                        .font(.caption)
                        .foregroundColor(themeColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
                .background(themeColors.cardBackground)
                .cornerRadius(12)
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(unlockedIcons, id: \.self) { iconId in
                        IconCardView(iconId: iconId)
                    }
                }
            }
        }
    }
}

// MARK: - Icon Card View

struct IconCardView: View {
    @ObservedObject var themeManager = ThemeManager.shared
    @Environment(\.themeColors) var themeColors
    let iconId: String

    var isActive: Bool {
        themeManager.userCosmetics.activeIcon == iconId
    }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(themeColors.primary)

            Text(iconId)
                .font(.caption2)
                .lineLimit(1)

            if isActive {
                Text("Active")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .background(themeColors.primary)
                    .cornerRadius(4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(isActive ? themeColors.primary.opacity(0.1) : themeColors.cardBackground)
        .cornerRadius(8)
    }
}

#Preview {
    UnlocksView()
}
