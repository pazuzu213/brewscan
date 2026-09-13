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

    // MARK: - OTP Auth (email only, no password)

    /// Sends a 6-digit OTP to the email. Creates the Sunny Days account on first use.
    func requestOTP(email: String) async throws {
        let _: EmptyResponse = try await post(
            path: "/auth/v1/otp",
            body: [
                "email": email,
                "create_user": true,
                "data": ["source_app": Config.supabaseAppID]
            ]
        )
    }

    /// Verifies the OTP and returns a session.
    func verifyOTP(email: String, token: String) async throws -> AuthSession {
        let response: SupabaseAuthResponse = try await post(
            path: "/auth/v1/verify",
            body: [
                "type": "email",
                "email": email,
                "token": token
            ]
        )

        let session = AuthSession(
            token: response.accessToken,
            user: AuthUser(
                id: response.user.id,
                email: response.user.email,
                name: "",
                createdAt: nil
            )
        )
        saveSession(session)
        return session
    }

    // MARK: - Session Management

    func loadSession() -> AuthSession? {
        guard let data = KeychainStore.load(service: sessionService, account: sessionAccount) else { return nil }
        return try? decoder.decode(AuthSession.self, from: data)
    }

    func signOut() async throws {
        let session = loadSession()
        clearSession()

        if let session {
            let _: EmptyResponse = try await post(
                path: "/auth/v1/logout",
                body: [:],
                bearerToken: session.token
            )
        }
    }

    func saveSession(_ session: AuthSession) {
        guard let data = try? encoder.encode(session) else { return }
        KeychainStore.save(data, service: sessionService, account: sessionAccount)
    }

    func clearSession() {
        KeychainStore.delete(service: sessionService, account: sessionAccount)
    }

    // MARK: - Private

    private func post<T: Decodable>(
        path: String,
        body: [String: Any],
        bearerToken: String? = nil
    ) async throws -> T {
        guard let url = URL(string: Config.supabaseURL + path) else {
            throw AuthServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(bearerToken ?? Config.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AuthServiceError.invalidResponse }

        if (200..<300).contains(http.statusCode) {
            if data.isEmpty {
                return EmptyResponse() as! T
            }
            return try decoder.decode(T.self, from: data)
        }

        if let errorResponse = try? decoder.decode(SupabaseErrorResponse.self, from: data) {
            throw AuthServiceError.message(errorResponse.message ?? errorResponse.msg ?? "Sign in failed. Try again.")
        }

        throw AuthServiceError.message("Sign in failed. Try again.")
    }
}

struct EmptyResponse: Decodable {}

private struct SupabaseAuthResponse: Decodable {
    let accessToken: String
    let user: SupabaseUser

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case user
    }
}

private struct SupabaseUser: Decodable {
    let id: String
    let email: String
}

private struct SupabaseErrorResponse: Decodable {
    let message: String?
    let msg: String?
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
