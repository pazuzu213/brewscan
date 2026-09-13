import Foundation

enum MachineType: String, Codable, CaseIterable {
    case nespresso = "Nespresso"
    case keurig = "Keurig"
    case other = "Other"
    case original = "Original"
    case vertuo = "Vertuo"

    static let onboardingCases: [MachineType] = [.nespresso, .keurig, .other]

    var displayName: String {
        switch self {
        case .original, .vertuo:
            return "Nespresso"
        default:
            return rawValue
        }
    }
}

enum BrewStrength: String, Codable, CaseIterable {
    case light = "Light"
    case medium = "Medium"
    case strong = "Strong"
    case intense = "Intense"
}

struct UserProfile: Codable, Equatable {
    var name: String
    var email: String
    var machineType: MachineType
    var milkPreference: Bool
    var preferredStrength: BrewStrength
    var createdAt: Date

    static let empty = UserProfile(
        name: "",
        email: "",
        machineType: .nespresso,
        milkPreference: false,
        preferredStrength: .medium,
        createdAt: Date()
    )
}
