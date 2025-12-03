
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
}

@main
struct GReadApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var themeManager = ThemeManager.shared
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
                    textPrimary: themeManager.currentTheme.effectiveIsDarkTheme ? Color(hex: "#FFFFFF") : Color(hex: "#1A1A1A"),
                    textSecondary: themeManager.currentTheme.effectiveIsDarkTheme ? Color(hex: "#CCCCCC") : Color(hex: "#666666"),
                    border: themeManager.currentTheme.effectiveIsDarkTheme ? Color(hex: "#444444") : Color(hex: "#EEEEEE"),
                    success: .green,
                    warning: .yellow,
                    error: .red,
                    cardBackground: themeManager.currentTheme.effectiveIsDarkTheme ? Color(hex: "#1E1E1E") : Color(hex: "#F8F9FA"),
                    shadowColor: Color.black.opacity(0.15),
                    headerBackground: themeManager.currentTheme.effectiveIsDarkTheme ? Color(hex: "#1E1E1E") : Color(hex: "#F0E6FF"),
                    navigationBackground: themeManager.currentTheme.effectiveIsDarkTheme ? Color(hex: "#1E1E1E") : Color(hex: "#F8F9FA"),
                    buttonBackground: themeManager.currentTheme.primary,
                    inputBackground: themeManager.currentTheme.effectiveIsDarkTheme ? Color(hex: "#2A2A2A") : Color(hex: "#F5F5F5"),
                    surfaceBackground: themeManager.currentTheme.effectiveIsDarkTheme ? Color(hex: "#1E1E1E") : Color(hex: "#F8F9FA")
                ))
                // Apply preferred color scheme based on current theme
                .preferredColorScheme(themeManager.currentTheme.effectiveIsDarkTheme ? .dark : .light)
                // Force view refresh when theme changes
                .id(themeManager.currentTheme.id)

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
