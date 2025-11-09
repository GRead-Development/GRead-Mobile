
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
                    background: themeManager.currentTheme.background
                ))

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
