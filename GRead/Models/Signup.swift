import Foundation

// MARK: - Signup
struct Signup: Codable, Identifiable {
    let id: Int
    let userLogin: String?
    let userEmail: String?
    let registered: String?
    let activationKey: String?
    let meta: SignupMeta?

    enum CodingKeys: String, CodingKey {
        case id, meta
        case userLogin = "user_login"
        case userEmail = "user_email"
        case registered
        case activationKey = "activation_key"
    }
}

struct SignupMeta: Codable {
    let fieldId: Int?
    let value: String?

    enum CodingKeys: String, CodingKey {
        case fieldId = "field_id"
        case value
    }
}

// MARK: - Signup Response
struct SignupResponse: Codable {
    let success: Bool?
    let message: String?
    let userId: Int?
    let activationKey: String?

    enum CodingKeys: String, CodingKey {
        case success, message
        case userId = "user_id"
        case activationKey = "activation_key"
    }
}

// MARK: - Activation Response
struct ActivationResponse: Codable {
    let activated: Bool?
    let message: String?
    let userId: Int?

    enum CodingKeys: String, CodingKey {
        case activated, message
        case userId = "user_id"
    }
}

// MARK: - Resend Activation Response
struct ResendActivationResponse: Codable {
    let sent: Bool?
    let message: String?
}
