import Foundation

struct AuthUser: Codable, Equatable {
    let id: String
    let email: String
    let name: String
    let createdAt: Date?
}

struct AuthSession: Codable, Equatable {
    let token: String
    let user: AuthUser
}

struct LoginRequestResponse: Decodable {
    let ok: Bool
    let email: String
    let expiresAt: Date
    let emailSent: Bool
    let devCode: String?
    let devMagicLink: String?
}

struct AuthResponse: Decodable {
    let ok: Bool
    let token: String
    let user: AuthUser
}

struct AuthErrorResponse: Decodable {
    let error: String
}
