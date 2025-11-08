
import SwiftUI

@main
struct GReadApp: App {
    @StateObject private var authManager = AuthManager.shared

    var body: some Scene {
        WindowGroup {
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
    }
}
