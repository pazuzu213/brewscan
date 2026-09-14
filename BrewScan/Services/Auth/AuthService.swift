import Foundation

final class AuthService {
    static let shared = AuthService()

    private let sessionService = "com.sunnydays.brewscan.auth"
    private let sessionAccount = "session"

    private let supabaseURL = "https://nknhwybaaouyuakcmreu.supabase.co"
    private let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5rbmh3eWJhYW91eXVha2NtcmV1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODkyNDI5MTAsImV4cCI6MjEwNDgxODkxMH0.ZAHRXJ0JiC6aoORYEkzg1dlC8Bul5rQ2eCZLo6gC2h0"

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private init() {}

    // MARK: - OTP Auth (Supabase native)

    /// Sends a 6-digit OTP to the email via Supabase.
    func requestOTP(email: String) async throws {
        let url = URL(string: "\(supabaseURL)/auth/v1/otp")!
        var req = supabaseRequest(url: url)
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "create_user": true
        ])

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw AuthServiceError.invalidResponse }

        guard (200..<300).contains(http.statusCode) else {
            let msg = parseErrorMessage(data) ?? "Failed to send code. Please try again."
            throw AuthServiceError.message(msg)
        }
    }

    /// Verifies the 6-digit OTP and returns a session.
    func verifyOTP(email: String, token: String) async throws -> AuthSession {
        let url = URL(string: "\(supabaseURL)/auth/v1/verify")!
        var req = supabaseRequest(url: url)
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "token": token,
            "type": "email"
        ])

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw AuthServiceError.invalidResponse }

        if (200..<300).contains(http.statusCode) {
            let supaSession = try decoder.decode(SupabaseSessionResponse.self, from: data)
            let nameFromEmail = String(email.split(separator: "@").first ?? "User")
            let session = AuthSession(
                token: supaSession.accessToken,
                user: AuthUser(
                    id: supaSession.user.id,
                    email: supaSession.user.email,
                    name: nameFromEmail,
                    createdAt: supaSession.user.createdAt
                )
            )
            saveSession(session)
            return session
        }

        let msg = parseErrorMessage(data) ?? "Incorrect code. Please try again."
        throw AuthServiceError.message(msg)
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

    private func supabaseRequest(url: URL) -> URLRequest {
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        return req
    }

    private func parseErrorMessage(_ data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return json["error_description"] as? String
            ?? json["msg"] as? String
            ?? json["message"] as? String
            ?? json["error"] as? String
    }
}

// MARK: - Supabase Response Models

private struct SupabaseSessionResponse: Decodable {
    let accessToken: String
    let user: SupabaseUser
}

private struct SupabaseUser: Decodable {
    let id: String
    let email: String
    let createdAt: Date?
}

// MARK: - Errors

enum AuthServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case message(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Auth configuration error."
        case .invalidResponse:
            return "The server did not respond correctly."
        case .message(let value):
            return value
        }
    }
}
