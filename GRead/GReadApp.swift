
import SwiftUI

@main
struct GReadApp: App {
    @StateObject private var authManager = AuthManager.shared
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main app content
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
