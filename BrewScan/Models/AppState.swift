import Foundation
import Combine

class AppState: ObservableObject {
    static let shared = AppState()

    // MARK: - Published Properties

    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding) }
    }

    /// Date the free trial started (set once, never overwritten)
    @Published var trialStartDate: Date? {
        didSet {
            if let date = trialStartDate {
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: Keys.trialStartDate)
            }
        }
    }

    // MARK: - Trial Computed Properties

    private static let trialDuration: TimeInterval = 7 * 24 * 60 * 60 // 7 days

    var isTrialActive: Bool {
        guard let start = trialStartDate else { return false }
        return Date().timeIntervalSince(start) < Self.trialDuration
    }

    var isTrialExpired: Bool {
        guard let start = trialStartDate else { return false }
        return Date().timeIntervalSince(start) >= Self.trialDuration
    }

    var trialDaysRemaining: Int {
        guard let start = trialStartDate else { return 0 }
        let elapsed = Date().timeIntervalSince(start)
        let remaining = Self.trialDuration - elapsed
        return max(0, Int(ceil(remaining / (24 * 60 * 60))))
    }

    /// Trial-only access. Subscription access is checked from StoreKitService in the UI layer.
    var hasAccess: Bool {
        isTrialActive
    }

    func startTrial() {
        guard trialStartDate == nil else { return } // only start once
        trialStartDate = Date()
    }

    @Published var userProfile: UserProfile? {
        didSet { persistUserProfile() }
    }

    @Published var savedScans: [SavedScan] {
        didSet { persistSavedScans() }
    }

    @Published var savedRecipeIds: Set<String> {
        didSet {
            UserDefaults.standard.set(
                Array(savedRecipeIds).joined(separator: ","),
                forKey: Keys.savedRecipeIds
            )
        }
    }

    @Published var favoritePodIds: Set<String> {
        didSet {
            UserDefaults.standard.set(
                Array(favoritePodIds).joined(separator: ","),
                forKey: Keys.favoritePodIds
            )
        }
    }

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let hasCompletedOnboarding = "brewscan.hasCompletedOnboarding"
        static let savedRecipeIds         = "brewscan.savedRecipeIds"
        static let favoritePodIds         = "brewscan.favoritePodIds"
        static let trialStartDate         = "brewscan.trialStartDate"
    }

    // MARK: - File URLs

    private var userProfileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("userProfile.json")
    }

    private var savedScansURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("savedScans.json")
    }

    // MARK: - Init

    private init() {
        // Load UserDefaults values
        let onboarded = UserDefaults.standard.bool(forKey: Keys.hasCompletedOnboarding)
        self.hasCompletedOnboarding = onboarded

        let trialTs = UserDefaults.standard.double(forKey: Keys.trialStartDate)
        self.trialStartDate = trialTs > 0 ? Date(timeIntervalSince1970: trialTs) : nil

        let recipeString = UserDefaults.standard.string(forKey: Keys.savedRecipeIds) ?? ""
        self.savedRecipeIds = recipeString.isEmpty ? [] : Set(recipeString.split(separator: ",").map(String.init))

        let podString = UserDefaults.standard.string(forKey: Keys.favoritePodIds) ?? ""
        self.favoritePodIds = podString.isEmpty ? [] : Set(podString.split(separator: ",").map(String.init))

        // Load JSON files
        self.userProfile = Self.loadJSON(from: FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("userProfile.json"))

        self.savedScans = Self.loadJSON(from: FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("savedScans.json")) ?? []
    }

    // MARK: - Public Actions

    func saveProfile(_ profile: UserProfile) {
        self.userProfile = profile
    }

    func saveScan(_ scan: SavedScan) {
        savedScans.insert(scan, at: 0)
    }

    func toggleSavedRecipe(_ recipeId: String) {
        if savedRecipeIds.contains(recipeId) {
            savedRecipeIds.remove(recipeId)
        } else {
            savedRecipeIds.insert(recipeId)
        }
    }

    func toggleFavoritePod(_ podId: String) {
        if favoritePodIds.contains(podId) {
            favoritePodIds.remove(podId)
        } else {
            favoritePodIds.insert(podId)
        }
    }

    func isRecipeSaved(_ recipeId: String) -> Bool {
        savedRecipeIds.contains(recipeId)
    }

    func isPodFavorite(_ podId: String) -> Bool {
        favoritePodIds.contains(podId)
    }

    func deleteScan(at offsets: IndexSet) {
        for offset in offsets.sorted(by: >) where savedScans.indices.contains(offset) {
            savedScans.remove(at: offset)
        }
    }

    func deleteScans(ids: Set<UUID>) {
        savedScans.removeAll { ids.contains($0.id) }
    }

    // MARK: - Persistence Helpers

    private func persistUserProfile() {
        guard let profile = userProfile else { return }
        Self.saveJSON(profile, to: userProfileURL)
    }

    private func persistSavedScans() {
        Self.saveJSON(savedScans, to: savedScansURL)
    }

    private static func saveJSON<T: Encodable>(_ value: T, to url: URL) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(value)
            try data.write(to: url, options: .atomic)
        } catch {
            print("[AppState] Failed to save JSON to \(url.lastPathComponent): \(error)")
        }
    }

    private static func loadJSON<T: Decodable>(from url: URL) -> T? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(T.self, from: data)
        } catch {
            print("[AppState] Failed to load JSON from \(url.lastPathComponent): \(error)")
            return nil
        }
    }
}
