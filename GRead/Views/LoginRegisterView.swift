import SwiftUI

struct LoginRegisterView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Login Tab
                LoginView()
                    .environmentObject(authManager)
                    .tabItem {
                        Label("Login", systemImage: "person.fill")
                    }
                    .tag(0)

                // Register Tab
                RegistrationView()
                    .environmentObject(authManager)
                    .tabItem {
                        Label("Sign Up", systemImage: "person.badge.plus.fill")
                    }
                    .tag(1)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
}
