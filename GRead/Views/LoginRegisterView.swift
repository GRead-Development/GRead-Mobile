import SwiftUI

struct LoginRegisterView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with Logo
                VStack(spacing: 12) {
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("GRead")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("It's just fun.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 24)

                Divider()

                // Tab View
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
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
}
