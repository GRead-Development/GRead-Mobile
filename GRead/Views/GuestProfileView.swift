import SwiftUI

struct GuestProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.themeColors) var themeColors
    @State private var showingLoginRegister = false

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.gray.opacity(0.5))

                Text("Guest User")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("You are browsing the app as a guest")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.top, 40)

            Spacer()

            Button(action: { showingLoginRegister = true }) {
                HStack {
                    Image(systemName: "person.fill")
                    Text("Sign In or Create Account")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(themeColors.primary)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeColors.background)
        .navigationTitle("Profile")
        .sheet(isPresented: $showingLoginRegister) {
            LoginRegisterView()
                .environmentObject(authManager)
        }
    }

    private func logout() {
        authManager.logout()
    }
}

#Preview {
    GuestProfileView()
        .environmentObject(AuthManager.shared)
}
