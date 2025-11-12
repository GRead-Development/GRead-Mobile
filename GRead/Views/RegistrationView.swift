import Foundation
import UIKit
import SwiftUI

struct RegistrationView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.themeColors) var themeColors
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var agreedToTerms = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showPassword = false
    @State private var showConfirmPassword = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 20)

                // Registration Form
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

                            TextField("Choose a username", text: $username)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
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

                    // Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.caption)
                            .foregroundColor(themeColors.textSecondary)
                            .padding(.leading, 4)

                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(themeColors.textSecondary)
                                .frame(width: 20)

                            TextField("Enter your email", text: $email)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
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
                                TextField("Create a password", text: $password)
                                    .textContentType(.newPassword)
                            } else {
                                SecureField("Create a password", text: $password)
                                    .textContentType(.newPassword)
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

                    // Confirm Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(.caption)
                            .foregroundColor(themeColors.textSecondary)
                            .padding(.leading, 4)

                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(themeColors.textSecondary)
                                .frame(width: 20)

                            if showConfirmPassword {
                                TextField("Confirm your password", text: $confirmPassword)
                                    .textContentType(.newPassword)
                            } else {
                                SecureField("Confirm your password", text: $confirmPassword)
                                    .textContentType(.newPassword)
                            }

                            Button {
                                showConfirmPassword.toggle()
                            } label: {
                                Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
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

                // Message (Error or Success)
                if let error = errorMessage {
                    let isSuccessMessage = error.lowercased().contains("account created") || error.lowercased().contains("check your email")
                    let messageColor = isSuccessMessage ? themeColors.success : themeColors.error

                    HStack(spacing: 8) {
                        Image(systemName: isSuccessMessage ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(messageColor)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(messageColor)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(messageColor.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(messageColor.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                }

                // Terms of Service Agreement
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                            .foregroundColor(agreedToTerms ? themeColors.primary : themeColors.textSecondary)
                            .font(.title3)
                            .onTapGesture {
                                agreedToTerms.toggle()
                            }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 0) {
                                Text("I agree to the ")
                                    .font(.caption)
                                    .foregroundColor(themeColors.textSecondary)

                                Link("Terms of Service", destination: URL(string: "https://gread.fun/tos")!)
                                    .font(.caption)
                                    .foregroundColor(themeColors.primary)
                            }
                        }

                        Spacer()
                    }
                    .padding()
                    .background(themeColors.textSecondary.opacity(0.05))
                    .cornerRadius(10)
                    .onTapGesture {
                        agreedToTerms.toggle()
                    }
                }
                .padding(.horizontal, 24)

                // Sign Up Button
                Button(action: register) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Sign Up")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(isFormValid && agreedToTerms && !isLoading ? themeColors.primary : themeColors.textSecondary.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: themeColors.primary.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .disabled(!isFormValid || !agreedToTerms || isLoading)
                .padding(.horizontal, 24)
                .padding(.top, 8)

                Spacer()
            }
        }
    }

    private var isFormValid: Bool {
        !username.isEmpty && !email.isEmpty && !password.isEmpty &&
        password == confirmPassword && password.count >= 6
    }

    private func register() {
        isLoading = true
        errorMessage = nil

        // Hide keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        // Validate passwords match
        if password != confirmPassword {
            errorMessage = "Passwords do not match"
            isLoading = false
            return
        }

        // Validate email format
        if !isValidEmail(email) {
            errorMessage = "Please enter a valid email address"
            isLoading = false
            return
        }

        Task {
            do {
                try await authManager.register(username: username, email: email, password: password)
            } catch let error as AuthError {
                await MainActor.run {
                    errorMessage = error.errorDescription
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Registration failed. Please try again."
                    isLoading = false
                }
            }
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

}
