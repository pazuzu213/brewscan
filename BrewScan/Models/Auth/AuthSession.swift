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
