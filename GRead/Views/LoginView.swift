import Foundation
import UIKit
import SwiftUI
import AuthenticationServices
struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.themeColors) var themeColors
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showPassword = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 20)

                    // Login Form
                    VStack(spacing: 16) {
                        // Username Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username")
                                .font(.caption)
                                .foregroundColor(themeColors.textSecondary)
                                .padding(.leading, 4)

                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(themeColors.textSecondary)
                                    .frame(width: 20)

                                TextField("Enter your username", text: $username)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .textContentType(.username)
                            }
                            .padding(14)
                            .background(themeColors.inputBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(themeColors.border, lineWidth: 1)
                            )
                            .shadow(color: themeColors.shadowColor, radius: 2, x: 0, y: 1)
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.caption)
                                .foregroundColor(themeColors.textSecondary)
                                .padding(.leading, 4)

                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(themeColors.textSecondary)
                                    .frame(width: 20)

                                if showPassword {
                                    TextField("Enter your password", text: $password)
                                        .textContentType(.password)
                                } else {
                                    SecureField("Enter your password", text: $password)
                                        .textContentType(.password)
                                }

                                Button {
                                    showPassword.toggle()
                                } label: {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(themeColors.textSecondary)
                                }
                            }
                            .padding(14)
                            .background(themeColors.inputBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(themeColors.border, lineWidth: 1)
                            )
                            .shadow(color: themeColors.shadowColor, radius: 2, x: 0, y: 1)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Error Message
                    if let error = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(themeColors.error)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(themeColors.error)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(themeColors.error.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(themeColors.error.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal, 24)
                    }

                    // Login Button
                    Button(action: login) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Login")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(
                            (username.isEmpty || password.isEmpty || isLoading) ?
                            themeColors.textSecondary.opacity(0.3) : themeColors.primary
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: themeColors.primary.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .disabled(isLoading || username.isEmpty || password.isEmpty)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    // Divider
                    HStack {
                        Rectangle()
                            .fill(themeColors.border)
                            .frame(height: 1)
                        Text("OR")
                            .font(.caption)
                            .foregroundColor(themeColors.textSecondary)
                            .padding(.horizontal, 12)
                        Rectangle()
                            .fill(themeColors.border)
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)

                    // Apple Sign In Button
                    AppleSignInButton(onSignIn: handleAppleSignIn)
                        .padding(.horizontal, 24)
                        .disabled(isLoading)

                    Spacer()
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
    
    private func login() {
        isLoading = true
        errorMessage = nil

        // Hide keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        Task {
            do {
                try await authManager.login(username: username, password: password)
            } catch let error as AuthError {
                await MainActor.run {
                    errorMessage = error.errorDescription
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Login failed. Please try again."
                    isLoading = false
                }
            }
        }
    }

    private func handleAppleSignIn(_ credential: ASAuthorizationAppleIDCredential) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await authManager.signInWithApple(credential: credential)
            } catch let error as AuthError {
                await MainActor.run {
                    errorMessage = error.errorDescription
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Apple Sign In failed. Please try again."
                    isLoading = false
                }
            }
        }
    }

}
