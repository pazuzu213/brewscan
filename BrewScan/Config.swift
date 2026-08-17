import Foundation

struct Config {
    /// Reads from OPENAI_API_KEY env var (set in Xcode Cloud secrets),
    /// falls back to the hardcoded key for local development.
    static let openAIKey: String = {
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        // Local dev fallback — never committed with real key in CI
        return "YOUR_LOCAL_KEY_HERE"
    }()

    static let openAIBaseURL = "https://api.openai.com/v1"
    static let openAIModel   = "gpt-4o-mini"
}
