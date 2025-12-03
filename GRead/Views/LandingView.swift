import SwiftUI
import AuthenticationServices

struct LandingView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.themeColors) var themeColors
    @State private var showLoginRegister = false
    @State private var showUsernameSelection = false
    @State private var appleSignInResult: AppleSignInResult?
    @State private var isSigningIn = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Top Section with Logo
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 40)

                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 80))
                        .foregroundColor(themeColors.primary)

                    VStack(spacing: 12) {
                        Text("GRead")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("It's just fun.")
                            .font(.subheadline)
                            .foregroundColor(themeColors.textSecondary)
                    }

                    Spacer()
                        .frame(height: 20)
                }
                .frame(maxWidth: .infinity)

                // Bottom Section with Buttons
                VStack(spacing: 16) {
                    // Sign in with Apple Button
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            handleAppleSignIn(result: result)
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 1)
                    )

                    // Divider
                    HStack {
                        VStack { Divider() }
                        Text("or")
                            .foregroundColor(themeColors.textSecondary)
                            .font(.caption)
                        VStack { Divider() }
                    }
                    .padding(.vertical, 4)

                    // Sign In / Register Button
                    NavigationLink(destination: LoginRegisterView()) {
                        HStack {
                            Image(systemName: "person.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Sign In / Register")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(themeColors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }

                    // Continue as Guest Button
                    Button(action: continueAsGuest) {
                        HStack {
                            Image(systemName: "eyes")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Browse as Guest")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(themeColors.textSecondary)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }

                    // Error Message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(themeColors.error)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showUsernameSelection) {
                if let result = appleSignInResult {
                    AppleUsernameSelectionView(appleSignInResult: result)
                        .environmentObject(authManager)
                }
            }
        }
    }

    private func continueAsGuest() {
        authManager.enterGuestMode()
    }

    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        guard !isSigningIn else { return }

        isSigningIn = true
        errorMessage = nil

        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Invalid Apple ID credential"
                isSigningIn = false
                return
            }

            // Extract identity token
            guard let identityTokenData = appleIDCredential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                errorMessage = "Missing identity token"
                isSigningIn = false
                return
            }

            // Extract authorization code
            guard let authCodeData = appleIDCredential.authorizationCode,
                  let authCode = String(data: authCodeData, encoding: .utf8) else {
                errorMessage = "Missing authorization code"
                isSigningIn = false
                return
            }

            let userIdentifier = appleIDCredential.user

            // Try to login first
            Task {
                do {
                    Logger.debug("Attempting Apple login with user ID: \(userIdentifier)")
                    try await authManager.loginWithApple(
                        identityToken: identityToken,
                        authorizationCode: authCode,
                        userIdentifier: userIdentifier
                    )
                    // Login successful
                    Logger.debug("Apple login successful!")
                    await MainActor.run {
                        isSigningIn = false
                    }
                } catch let error as AuthError {
                    Logger.error("Apple login AuthError: \(error)")
                    // If user not found, need to register
                    if case .userNotFound = error {
                        await MainActor.run {
                            appleSignInResult = AppleSignInResult(
                                userIdentifier: userIdentifier,
                                identityToken: identityToken,
                                authorizationCode: authCode,
                                email: appleIDCredential.email,
                                fullName: appleIDCredential.fullName
                            )
                            showUsernameSelection = true
                            isSigningIn = false
                        }
                    } else {
                        await MainActor.run {
                            errorMessage = "Login error: \(error.localizedDescription)"
                            isSigningIn = false
                        }
                    }
                } catch {
                    Logger.error("Apple login general error: \(error)")
                    await MainActor.run {
                        errorMessage = "Sign in failed: \(error.localizedDescription)"
                        isSigningIn = false
                    }
                }
            }

        case .failure(let error):
            if let authError = error as? ASAuthorizationError {
                switch authError.code {
                case .canceled:
                    // User cancelled, no error message needed
                    break
                default:
                    errorMessage = "Sign in failed: \(error.localizedDescription)"
                }
            } else {
                errorMessage = "Sign in failed: \(error.localizedDescription)"
            }
            isSigningIn = false
        }
    }
}

#Preview {
    LandingView()
        .environmentObject(AuthManager.shared)
}
