import SwiftUI

struct ThemeColors {
    let primary: Color
    let secondary: Color
    let accent: Color
    let background: Color

    // Additional utility colors
    var textPrimary: Color { .black }
    var textSecondary: Color { .gray }
    var border: Color { Color(.systemGray4) }
    var success: Color { .green }
    var warning: Color { .yellow }
    var error: Color { .red }
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
        environment(\.themeColors, ThemeColors(
            primary: theme.primary,
            secondary: theme.secondary,
            accent: theme.accent,
            background: theme.background
        ))
    }
}
