import SwiftUI

struct ThemeSelectionView: View {
    @ObservedObject var themeManager = ThemeManager.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Unlocked themes
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Unlocked Themes")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            ForEach(themeManager.allThemes) { theme in
                                if themeManager.isThemeUnlocked(theme.id) {
                                    ThemeSelectionRow(theme: theme)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Locked themes section
                    let lockedThemes = themeManager.allThemes.filter {
                        !themeManager.isThemeUnlocked($0.id)
                    }

                    if !lockedThemes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Locked Themes")
                                .font(.headline)
                                .padding(.horizontal)

                            VStack(spacing: 12) {
                                ForEach(lockedThemes) { theme in
                                    LockedThemeSelectionRow(theme: theme)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Select Theme")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Theme Selection Row

struct ThemeSelectionRow: View {
    @ObservedObject var themeManager = ThemeManager.shared
    let theme: AppTheme

    var isActive: Bool {
        themeManager.currentTheme.id == theme.id
    }

    var body: some View {
        Button(action: {
            themeManager.applyTheme(theme)
        }) {
            HStack(spacing: 12) {
                // Color preview
                HStack(spacing: 3) {
                    Circle()
                        .fill(theme.primary)
                        .frame(width: 12, height: 12)
                    Circle()
                        .fill(theme.secondary)
                        .frame(width: 12, height: 12)
                    Circle()
                        .fill(theme.accent)
                        .frame(width: 12, height: 12)
                    if #available(iOS 17.0, *) {
                        Circle()
                            .fill(theme.background)
                            .stroke(Color.gray, lineWidth: 0.5)
                            .frame(width: 12, height: 12)
                    } else {
                        // Fallback on earlier versions
                    }
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(6)

                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(theme.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .padding(12)
            .background(isActive ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isActive ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .foregroundColor(.primary)
    }
}

// MARK: - Locked Theme Selection Row

struct LockedThemeSelectionRow: View {
    let theme: AppTheme

    var body: some View {
        HStack(spacing: 12) {
            // Color preview (greyed out)
            HStack(spacing: 3) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 12, height: 12)
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 12, height: 12)
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 12, height: 12)
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 12, height: 12)
            }
            .padding(8)
            .background(Color(.systemGray6).opacity(0.5))
            .cornerRadius(6)

            VStack(alignment: .leading, spacing: 2) {
                Text(theme.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(theme.description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "lock.fill")
                    .font(.caption)
                Text("Locked")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.gray)
        }
        .padding(12)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
        .opacity(0.6)
    }
}

//#Preview {
  //  ThemeSelectionView()
//}
