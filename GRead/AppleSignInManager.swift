import Foundation
import AuthenticationServices
import SwiftUI
import Combine

class AppleSignInManager: NSObject, ObservableObject {
    static let shared = AppleSignInManager()

    @Published var appleUserIdentifier: String?
    @Published var appleEmail: String?
    @Published var appleFullName: PersonNameComponents?

    private override init() {
        super.init()
    }

    /// Start Sign in with Apple authentication flow
    func signInWithApple(completion: @escaping (Result<AppleSignInResult, Error>) -> Void) {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self

        // Store completion handler for use in delegate methods
        self.completionHandler = completion

        // Get the window scene to present the authorization controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    private var completionHandler: ((Result<AppleSignInResult, Error>) -> Void)?
}

// MARK: - ASAuthorizationControllerDelegate
extension AppleSignInManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            completionHandler?(.failure(AppleSignInError.invalidCredential))
            return
        }

        // Extract user identifier
        let userIdentifier = appleIDCredential.user

        // Extract identity token
        guard let identityTokenData = appleIDCredential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            completionHandler?(.failure(AppleSignInError.missingToken))
            return
        }

        // Extract authorization code
        guard let authCodeData = appleIDCredential.authorizationCode,
              let authCode = String(data: authCodeData, encoding: .utf8) else {
            completionHandler?(.failure(AppleSignInError.missingAuthCode))
            return
        }

        // Store user information
        appleUserIdentifier = userIdentifier

        // Email and name are only provided on first sign in
        if let email = appleIDCredential.email {
            appleEmail = email
        }

        if let fullName = appleIDCredential.fullName {
            appleFullName = fullName
        }

        let result = AppleSignInResult(
            userIdentifier: userIdentifier,
            identityToken: identityToken,
            authorizationCode: authCode,
            email: appleIDCredential.email,
            fullName: appleIDCredential.fullName
        )

        Logger.debug("Apple Sign In successful - User: \(userIdentifier)")
        completionHandler?(.success(result))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Logger.error("Apple Sign In failed: \(error.localizedDescription)")

        // Check if user cancelled
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                completionHandler?(.failure(AppleSignInError.userCancelled))
                return
            case .unknown:
                completionHandler?(.failure(AppleSignInError.unknown))
                return
            default:
                break
            }
        }

        completionHandler?(.failure(error))
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AppleSignInManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return UIWindow()
        }
        return window
    }
}

// MARK: - Supporting Types

struct AppleSignInResult: Identifiable {
    var id: String { userIdentifier }

    let userIdentifier: String
    let identityToken: String
    let authorizationCode: String
    let email: String?
    let fullName: PersonNameComponents?

    var fullNameString: String? {
        guard let fullName = fullName else { return nil }

        var components: [String] = []
        if let givenName = fullName.givenName {
            components.append(givenName)
        }
        if let familyName = fullName.familyName {
            components.append(familyName)
        }

        return components.isEmpty ? nil : components.joined(separator: " ")
    }
}

enum AppleSignInError: LocalizedError {
    case invalidCredential
    case missingToken
    case missingAuthCode
    case userCancelled
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid Apple ID credential"
        case .missingToken:
            return "Missing identity token"
        case .missingAuthCode:
            return "Missing authorization code"
        case .userCancelled:
            return "Sign in was cancelled"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
