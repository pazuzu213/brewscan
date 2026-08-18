import Foundation

final class AuthService {
    static let shared = AuthService()

    private let sessionService = "com.sunnydays.brewscan.auth"
    private let sessionAccount = "session"

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private init() {}

    func requestLogin(email: String, name: String?) async throws -> LoginRequestResponse {
        try await post(
            path: "/auth/request",
            body: [
                "email": email,
                "name": name ?? ""
            ],
            responseType: LoginRequestResponse.self
        )
    }

    func verifyCode(email: String, code: String) async throws -> AuthSession {
        let response = try await post(
            path: "/auth/verify-code",
            body: [
                "email": email,
                "code": code
            ],
            responseType: AuthResponse.self
        )
        return AuthSession(token: response.token, user: response.user)
    }

    func verifyMagicToken(_ token: String) async throws -> AuthSession {
        let response = try await post(
            path: "/auth/verify-magic",
            body: ["token": token],
            responseType: AuthResponse.self
        )
        return AuthSession(token: response.token, user: response.user)
    }

    func saveSession(_ session: AuthSession) {
        guard let data = try? encoder.encode(session) else { return }
        KeychainStore.save(data, service: sessionService, account: sessionAccount)
    }

    func loadSession() -> AuthSession? {
        guard let data = KeychainStore.load(service: sessionService, account: sessionAccount) else { return nil }
        return try? decoder.decode(AuthSession.self, from: data)
    }

    func clearSession() {
        KeychainStore.delete(service: sessionService, account: sessionAccount)
    }

    private func post<T: Decodable>(
        path: String,
        body: [String: String],
        responseType: T.Type
    ) async throws -> T {
        guard let url = URL(string: Config.authBaseURL + path) else {
            throw AuthServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AuthServiceError.invalidResponse }

        if (200..<300).contains(http.statusCode) {
            return try decoder.decode(responseType, from: data)
        }

        if let errorResponse = try? decoder.decode(AuthErrorResponse.self, from: data) {
            throw AuthServiceError.message(errorResponse.error)
        }

        throw AuthServiceError.message("Login failed. Try again.")
    }
}

enum AuthServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case message(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The login server URL is not valid."
        case .invalidResponse:
            return "The login server did not respond correctly."
        case .message(let value):
            return value
        }
    }
}
