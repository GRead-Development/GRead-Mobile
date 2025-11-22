import SwiftUI
import AuthenticationServices

struct AppleSignInButton: View {
    @Environment(\.themeColors) var themeColors
    var onSignIn: (ASAuthorizationAppleIDCredential) -> Void

    var body: some View {
        SignInWithAppleButton(
            .signIn,
            onRequest: { request in
                request.requestedScopes = [.fullName, .email]
            },
            onCompletion: { result in
                switch result {
                case .success(let authorization):
                    if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                        onSignIn(appleIDCredential)
                    }
                case .failure(let error):
                    Logger.error("Apple Sign In error: \(error.localizedDescription)")
                }
            }
        )
        .signInWithAppleButtonStyle(.black)
        .frame(height: 50)
        .cornerRadius(12)
        .shadow(color: themeColors.shadowColor, radius: 4, x: 0, y: 2)
    }
}
