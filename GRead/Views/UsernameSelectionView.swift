import Foundation
import UIKit
import SwiftUI

struct UsernameSelectionView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.themeColors) var themeColors
    @State private var username = ""
    @State private var isLoading = false
    @State private var isCheckingAvailability = false
    @State private var errorMessage: String?
    @State private var isAvailable: Bool?
    @State private var checkTask: Task<Void, Never>?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 20)

                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(themeColors.primary)

                        Text("Choose Your Username")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("This will be your unique identity on GRead")
                            .font(.caption)
                            .foregroundColor(themeColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.vertical, 24)

                    // Username Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.caption)
                            .foregroundColor(themeColors.textSecondary)
                            .padding(.leading, 4)

                        HStack {
                            Image(systemName: "at")
                                .foregroundColor(themeColors.textSecondary)
                                .frame(width: 20)

                            TextField("Enter username", text: $username)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .onChange(of: username) { newValue in
                                    // Reset availability check
                                    isAvailable = nil
                                    errorMessage = nil

                                    // Cancel previous check
                                    checkTask?.cancel()

                                    // Only check if username is valid length
                                    guard newValue.count >= 3 else { return }

                                    // Debounce username check
                                    checkTask = Task {
                                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                                        guard !Task.isCancelled else { return }
                                        await checkUsername(newValue)
                                    }
                                }

                            // Availability indicator
                            if isCheckingAvailability {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else if let available = isAvailable {
                                Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(available ? themeColors.success : themeColors.error)
                            }
                        }
                        .padding(14)
                        .background(themeColors.inputBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(getBorderColor(), lineWidth: 1)
                        )
                        .shadow(color: themeColors.shadowColor, radius: 2, x: 0, y: 1)

                        // Username requirements
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Username must:")
                                .font(.caption2)
                                .foregroundColor(themeColors.textSecondary)
                            Text("• Be at least 3 characters long")
                                .font(.caption2)
                                .foregroundColor(username.count >= 3 ? themeColors.success : themeColors.textSecondary)
                            Text("• Contain only letters, numbers, and underscores")
                                .font(.caption2)
                                .foregroundColor(isValidFormat(username) ? themeColors.success : themeColors.textSecondary)
                        }
                        .padding(.leading, 4)
                    }
                    .padding(.horizontal, 24)

                    // Suggested usernames
                    if let suggested = authManager.suggestedUsername, username.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Suggestions")
                                .font(.caption)
                                .foregroundColor(themeColors.textSecondary)
                                .padding(.leading, 4)

                            Button(action: {
                                username = suggested
                            }) {
                                HStack {
                                    Image(systemName: "sparkles")
                                    Text(suggested)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Image(systemName: "arrow.right.circle.fill")
                                }
                                .padding(14)
                                .background(themeColors.primary.opacity(0.1))
                                .foregroundColor(themeColors.primary)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(themeColors.primary.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                    }

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

                    // Continue Button
                    Button(action: completeSignup) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Continue")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(canContinue ? themeColors.primary : themeColors.textSecondary.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: themeColors.primary.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .disabled(!canContinue || isLoading)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    Spacer()
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .onAppear {
            // Pre-fill with suggested username
            if let suggested = authManager.suggestedUsername {
                username = suggested
            }
        }
    }

    private var canContinue: Bool {
        !username.isEmpty &&
        username.count >= 3 &&
        isValidFormat(username) &&
        isAvailable == true &&
        !isCheckingAvailability
    }

    private func getBorderColor() -> Color {
        if username.isEmpty {
            return themeColors.border
        }
        if isCheckingAvailability {
            return themeColors.border
        }
        if let available = isAvailable {
            return available ? themeColors.success : themeColors.error
        }
        return themeColors.border
    }

    private func isValidFormat(_ username: String) -> Bool {
        let usernameRegex = "^[a-zA-Z0-9_]+$"
        let usernamePredicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
        return usernamePredicate.evaluate(with: username)
    }

    private func checkUsername(_ username: String) async {
        guard isValidFormat(username) else {
            await MainActor.run {
                isAvailable = false
                errorMessage = "Username can only contain letters, numbers, and underscores"
            }
            return
        }

        await MainActor.run {
            isCheckingAvailability = true
        }

        do {
            let available = try await authManager.checkUsernameAvailability(username: username)
            await MainActor.run {
                isAvailable = available
                isCheckingAvailability = false
                if !available {
                    errorMessage = "This username is already taken"
                } else {
                    errorMessage = nil
                }
            }
        } catch {
            await MainActor.run {
                isCheckingAvailability = false
                errorMessage = "Could not check username availability"
            }
        }
    }

    private func completeSignup() {
        isLoading = true
        errorMessage = nil

        // Hide keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        Task {
            do {
                try await authManager.completeUsernameSelection(username: username)
            } catch let error as AuthError {
                await MainActor.run {
                    errorMessage = error.errorDescription
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to complete signup. Please try again."
                    isLoading = false
                }
            }
        }
    }
}
