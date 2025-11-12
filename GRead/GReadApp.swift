
import SwiftUI

@main
struct GReadApp: App {
    @StateObject private var authManager = AuthManager.shared
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main app content
                Group {
                    if authManager.isAuthenticated {
                        MainTabView()
                            .environmentObject(authManager)
                    } else if authManager.isGuestMode {
                        MainTabView()
                            .environmentObject(authManager)
                    } else {
                        LandingView()
                            .environmentObject(authManager)
                    }
                }
                .environmentObject(themeManager)
                .environment(\.themeColors, ThemeColors(
                    primary: themeManager.currentTheme.primary,
                    secondary: themeManager.currentTheme.secondary,
                    accent: themeManager.currentTheme.accent,
                    background: themeManager.currentTheme.background,
                    textPrimary: themeManager.currentTheme.isDarkTheme ? Color(hex: "#FFFFFF") : Color(hex: "#1A1A1A"),
                    textSecondary: themeManager.currentTheme.isDarkTheme ? Color(hex: "#CCCCCC") : Color(hex: "#666666"),
                    border: themeManager.currentTheme.isDarkTheme ? Color(hex: "#444444") : Color(hex: "#EEEEEE")
                ))
                // Force light color scheme to ensure custom themes control the UI appearance
                .preferredColorScheme(.light)

                // Splash screen overlay
                if showSplash {
                    SplashScreenView()
                        .onAppear {
                            // Dismiss splash after animation completes (3 seconds total)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                withAnimation(.easeOut(duration: 0.5)) {
                                    showSplash = false
                                }
                            }
                        }
                }
            }
        }
    }
}
