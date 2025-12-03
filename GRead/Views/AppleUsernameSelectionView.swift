import SwiftUI

struct AppleUsernameSelectionView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.themeColors) var themeColors
    @Environment(\.dismiss) var dismiss

    let appleSignInResult: AppleSignInResult

    @State private var username: String = ""
    @State private var isRegistering = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 60))
                        .foregroundColor(themeColors.primary)

                    Text("Choose Your Username")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("You're almost done! Pick a unique username to complete your registration.")
                        .font(.subheadline)
                        .foregroundColor(themeColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)

                // User Info from Apple (if available)
                if let email = appleSignInResult.email {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.caption)
                            .foregroundColor(themeColors.textSecondary)
                        Text(email)
                            .font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(themeColors.cardBackground)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                if let fullName = appleSignInResult.fullNameString {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.caption)
                            .foregroundColor(themeColors.textSecondary)
                        Text(fullName)
                            .font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(themeColors.cardBackground)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                // Username Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Username")
                        .font(.caption)
                        .foregroundColor(themeColors.textSecondary)

                    TextField("Enter username", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .textContentType(.username)
                }
                .padding(.horizontal)

                // Error Message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(themeColors.error)
                        .padding(.horizontal)
                }

                Spacer()

                // Register Button
                Button(action: completeRegistration) {
                    if isRegistering {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(themeColors.primary)
                            .cornerRadius(12)
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Complete Registration")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(username.isEmpty ? themeColors.textSecondary : themeColors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .disabled(username.isEmpty || isRegistering)
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .navigationTitle("Setup Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isRegistering)
                }
            }
        }
    }

    private func completeRegistration() {
        guard !username.isEmpty else { return }

        isRegistering = true
        errorMessage = nil

        Task {
            do {
                try await authManager.registerWithApple(
                    identityToken: appleSignInResult.identityToken,
                    authorizationCode: appleSignInResult.authorizationCode,
                    userIdentifier: appleSignInResult.userIdentifier,
                    email: appleSignInResult.email,
                    fullName: appleSignInResult.fullNameString,
                    username: username
                )

                await MainActor.run {
                    dismiss()
                }
            } catch let error as AuthError {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isRegistering = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Registration failed. Please try again."
                    isRegistering = false
                }
            }
        }
    }
}

#Preview {
    AppleUsernameSelectionView(
        appleSignInResult: AppleSignInResult(
            userIdentifier: "test_user",
            identityToken: "token",
            authorizationCode: "code",
            email: "test@example.com",
            fullName: nil
        )
    )
    .environmentObject(AuthManager.shared)
}
