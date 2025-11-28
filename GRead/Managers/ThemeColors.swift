import SwiftUI

struct ThemeColors {
    let primary: Color
    let secondary: Color
    let accent: Color
    let background: Color

    // Text and border colors - adapt based on background brightness
    let textPrimary: Color
    let textSecondary: Color
    let border: Color

    // Status colors
    let success: Color
    let warning: Color
    let error: Color

    // Additional colors for cute/quirky design
    let cardBackground: Color
    let shadowColor: Color
    let completedBackground: Color

    // UI Element Colors - Tagged System
    let headerBackground: Color
    let navigationBackground: Color
    let buttonBackground: Color
    let inputBackground: Color
    let surfaceBackground: Color

    // Initialize with all colors
    init(primary: Color, secondary: Color, accent: Color, background: Color,
         textPrimary: Color? = nil, textSecondary: Color? = nil, border: Color? = nil,
         success: Color = .green, warning: Color = .yellow, error: Color = .red,
         cardBackground: Color? = nil, shadowColor: Color? = nil, completedBackground: Color? = nil,
         headerBackground: Color? = nil, navigationBackground: Color? = nil,
         buttonBackground: Color? = nil, inputBackground: Color? = nil,
         surfaceBackground: Color? = nil) {
        self.primary = primary
        self.secondary = secondary
        self.accent = accent
        self.background = background
        self.textPrimary = textPrimary ?? (background == Color(hex: "#FFFFFF") ? Color(hex: "#1A1A1A") : .white)
        self.textSecondary = textSecondary ?? (background == Color(hex: "#FFFFFF") ? Color(hex: "#666666") : Color(hex: "#AAAAAA"))
        self.border = border ?? (background == Color(hex: "#FFFFFF") ? Color(hex: "#EEEEEE") : Color(hex: "#333333"))
        self.success = success
        self.warning = warning
        self.error = error
        self.cardBackground = cardBackground ?? (background == Color(hex: "#FFFFFF") ? Color(hex: "#F8F9FA") : Color(hex: "#1E1E1E"))
        self.shadowColor = shadowColor ?? Color.black.opacity(0.15)
        self.completedBackground = completedBackground ?? success.opacity(0.15)

        // Tagged UI elements with smart defaults
        self.headerBackground = headerBackground ?? Color(hex: "#F0E6FF")
        self.navigationBackground = navigationBackground ?? cardBackground ?? (background == Color(hex: "#FFFFFF") ? Color(hex: "#F8F9FA") : Color(hex: "#1E1E1E"))
        self.buttonBackground = buttonBackground ?? primary
        self.inputBackground = inputBackground ?? Color(hex: "#F5F5F5")
        self.surfaceBackground = surfaceBackground ?? cardBackground ?? (background == Color(hex: "#FFFFFF") ? Color(hex: "#F8F9FA") : Color(hex: "#1E1E1E"))
    }
}

// MARK: - Environment Key
struct ThemeColorsKey: EnvironmentKey {
    static let defaultValue = ThemeColors(
        primary: Color(hex: "#007AFF"),
        secondary: Color(hex: "#5AC8FA"),
        accent: Color(hex: "#34C759"),
        background: Color(hex: "#FFFFFF")
    )
}

extension EnvironmentValues {
    var themeColors: ThemeColors {
        get { self[ThemeColorsKey.self] }
        set { self[ThemeColorsKey.self] = newValue }
    }
}

// MARK: - View Extension
extension View {
    func withThemeColors(_ theme: AppTheme) -> some View {
        let themeColors = ThemeColors(
            primary: theme.primary,
            secondary: theme.secondary,
            accent: theme.accent,
            background: theme.background
        )
        return environment(\.themeColors, themeColors)
    }
}
