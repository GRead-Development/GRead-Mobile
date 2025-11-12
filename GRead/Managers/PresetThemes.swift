import SwiftUI

/// Preset color themes for GRead
struct PresetThemes {
    // Light theme (default) - white base with vibrant accents
    static let light = ThemeColors(
        primary: Color(hex: "#6C5CE7"),      // Vibrant purple
        secondary: Color(hex: "#A29BFE"),    // Light purple
        accent: Color(hex: "#FF6B9D"),       // Pink accent
        background: Color(hex: "#FFFFFF"),   // Pure white
        textPrimary: Color(hex: "#2D3436"),  // Dark gray text
        textSecondary: Color(hex: "#636E72"), // Medium gray
        border: Color(hex: "#EEEEEE"),       // Light border
        success: Color(hex: "#00B894"),      // Green
        warning: Color(hex: "#FDCB6E"),      // Yellow
        error: Color(hex: "#E84393"),        // Red-pink
        cardBackground: Color(hex: "#F8F9FA"), // Very light gray
        shadowColor: Color.black.opacity(0.08)
    )

    // Dark theme - charcoal base with cool accents
    static let dark = ThemeColors(
        primary: Color(hex: "#A29BFE"),      // Light purple
        secondary: Color(hex: "#74B9FF"),    // Light blue
        accent: Color(hex: "#FF7675"),       // Coral
        background: Color(hex: "#FFFFFF"),   // White background
        textPrimary: Color(hex: "#1A1A1A"),  // Dark text
        textSecondary: Color(hex: "#555555"), // Medium gray
        border: Color(hex: "#DDDDDD"),       // Light border
        success: Color(hex: "#00D2D3"),      // Cyan
        warning: Color(hex: "#FDCB6E"),      // Yellow
        error: Color(hex: "#FF7675"),        // Coral
        cardBackground: Color(hex: "#F0F0F0"), // Light gray surfaces
        shadowColor: Color.black.opacity(0.1)
    )

    // Fun/quirky theme - rainbow inspired
    static let rainbow = ThemeColors(
        primary: Color(hex: "#FF6B6B"),      // Red
        secondary: Color(hex: "#4ECDC4"),    // Turquoise
        accent: Color(hex: "#FFE66D"),       // Yellow
        background: Color(hex: "#FFFFFF"),
        textPrimary: Color(hex: "#2C3E50"),
        textSecondary: Color(hex: "#7F8C8D"),
        border: Color(hex: "#ECF0F1"),
        success: Color(hex: "#2ECC71"),
        warning: Color(hex: "#F39C12"),
        error: Color(hex: "#E74C3C"),
        cardBackground: Color(hex: "#F5F5F5"),
        shadowColor: Color.black.opacity(0.1)
    )

    // Soft/calm theme - pastels
    static let soft = ThemeColors(
        primary: Color(hex: "#C7CEEA"),      // Soft purple
        secondary: Color(hex: "#B5EAD7"),    // Soft mint
        accent: Color(hex: "#FFDFD3"),       // Soft peach
        background: Color(hex: "#FFFCF2"),   // Off-white
        textPrimary: Color(hex: "#4A4A4A"),
        textSecondary: Color(hex: "#8B8B8B"),
        border: Color(hex: "#F0E6D2"),
        success: Color(hex: "#A8D8EA"),
        warning: Color(hex: "#FFD3B6"),
        error: Color(hex: "#FFAAA5"),
        cardBackground: Color(hex: "#FEFAF0"),
        shadowColor: Color.black.opacity(0.06)
    )
}

// MARK: - Theme Modifiers for UI Elements

extension View {
    /// Apply smooth, cute animation style
    func withCuteAnimation() -> some View {
        self.animation(.easeInOut(duration: 0.3), value: UUID())
    }

    /// Add cute shadow with offset
    func withCuteShadow(_ color: Color = Color.black.opacity(0.15)) -> some View {
        self.shadow(color: color, radius: 8, x: 0, y: 4)
    }

    /// Cute corner radius
    func withCuteCorners(_ radius: CGFloat = 12) -> some View {
        self.cornerRadius(radius)
    }

    /// Cute card styling
    func cuteCard(backgroundColor: Color, shadowColor: Color) -> some View {
        self
            .padding()
            .background(backgroundColor)
            .withCuteCorners(12)
            .withCuteShadow(shadowColor)
    }
}
