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

    /// Sends a 6-digit OTP to the email.
    func requestOTP(email: String) async throws {
        let _: AuthRequestResponse = try await post(
            path: "/auth/request",
            body: [
                "email": email
            ]
        )
    }

    /// Verifies the OTP and returns a session.
    func verifyOTP(email: String, token: String) async throws -> AuthSession {
        let response: AuthVerifyResponse = try await post(
            path: "/auth/verify-code",
            body: [
                "email": email,
                "code": token
            ]
        )

        let session = AuthSession(
            token: response.token,
            user: response.user
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
        clearSession()
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
        body: [String: Any]
    ) async throws -> T {
        let baseURL = Config.authBaseURL
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        guard !baseURL.isEmpty, let url = URL(string: baseURL + path) else {
            throw AuthServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AuthServiceError.invalidResponse }

        if (200..<300).contains(http.statusCode) {
            if data.isEmpty {
                return EmptyResponse() as! T
            }
            return try decoder.decode(T.self, from: data)
        }

        if let errorResponse = try? decoder.decode(AuthErrorResponse.self, from: data) {
            throw AuthServiceError.message(errorResponse.error ?? errorResponse.message ?? "Sign in failed. Try again.")
        }

        throw AuthServiceError.message("Sign in failed. Try again.")
    }
}

struct EmptyResponse: Decodable {}

private struct AuthRequestResponse: Decodable {
    let ok: Bool
    let email: String
    let expiresAt: Date
}

private struct AuthVerifyResponse: Decodable {
    let ok: Bool
    let token: String
    let user: AuthUser
}

private struct AuthErrorResponse: Decodable {
    let error: String?
    let message: String?
}

enum AuthServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case message(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The PodSnap AI login server is not configured."
        case .invalidResponse:
            return "The login server did not respond correctly."
        case .message(let value):
            return value
        }
    }
}
