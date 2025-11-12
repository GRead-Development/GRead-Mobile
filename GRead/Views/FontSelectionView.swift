import SwiftUI

struct FontSelectionView: View {
    @ObservedObject var themeManager = ThemeManager.shared
    @Environment(\.dismiss) var dismiss
    @Environment(\.themeColors) var themeColors

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Current Font Display
                    VStack(spacing: 12) {
                        Text("Current Font")
                            .font(.headline)
                            .foregroundColor(themeColors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if let currentFont = themeManager.currentFont {
                            VStack(spacing: 8) {
                                Text("GRead is great")
                                    .font(.custom(currentFont.fontFamily, size: 18))
                                    .foregroundColor(themeColors.textPrimary)
                                    .padding(12)
                                    .frame(maxWidth: .infinity)
                                    .background(themeColors.primary.opacity(0.1))
                                    .cornerRadius(8)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(currentFont.name)
                                        .font(.headline)
                                        .foregroundColor(themeColors.textPrimary)
                                    Text(currentFont.description)
                                        .font(.caption)
                                        .foregroundColor(themeColors.textSecondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(12)
                            .background(themeColors.background)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(themeColors.primary, lineWidth: 2)
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    // Available Fonts
                    VStack(spacing: 12) {
                        Text("Available Fonts")
                            .font(.headline)
                            .foregroundColor(themeColors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            ForEach(themeManager.allFonts) { font in
                                FontSelectionCard(
                                    font: font,
                                    isSelected: themeManager.currentFont?.id == font.id,
                                    isUnlocked: themeManager.isFontUnlocked(font.id),
                                    themeColors: themeColors,
                                    onSelect: {
                                        themeManager.setActiveFont(font.id)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }

                    Spacer()
                        .frame(height: 20)
                }
            }
            .scrollContentBackground(.hidden)
            .background(themeColors.background)
            .navigationTitle("Font Selection")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct FontSelectionCard: View {
    let font: AppFont
    let isSelected: Bool
    let isUnlocked: Bool
    let themeColors: ThemeColors
    let onSelect: () -> Void
    let hapticFeedback = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        VStack(spacing: 12) {
            // Font Preview
            Text("The quick brown fox")
                .font(.custom(font.fontFamily, size: 16))
                .foregroundColor(themeColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(themeColors.primary.opacity(0.05))
                .cornerRadius(6)

            // Font Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(font.name)
                            .font(.headline)
                            .foregroundColor(themeColors.textPrimary)
                        Text(font.description)
                            .font(.caption)
                            .foregroundColor(themeColors.textSecondary)
                    }

                    Spacer()

                    if isUnlocked {
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(themeColors.primary)
                        } else {
                            Button(action: {
                                hapticFeedback.impactOccurred()
                                onSelect()
                            }) {
                                Text("Select")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(themeColors.primary)
                                    .cornerRadius(6)
                            }
                        }
                    } else {
                        VStack(spacing: 2) {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundColor(themeColors.warning)
                            Text("Locked")
                                .font(.caption2)
                                .foregroundColor(themeColors.warning)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(
            isSelected
                ? themeColors.primary.opacity(0.1)
                : themeColors.background
        )
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isSelected ? themeColors.primary : themeColors.border,
                    lineWidth: isSelected ? 2 : 1
                )
        )
    }
}

#if DEBUG
struct FontSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        FontSelectionView()
    }
}
#endif
