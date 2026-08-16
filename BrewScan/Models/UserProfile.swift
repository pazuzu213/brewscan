import Foundation

enum MachineType: String, Codable, CaseIterable {
    case original = "Original"
    case vertuo = "Vertuo"
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
        machineType: .original,
        milkPreference: false,
        preferredStrength: .medium,
        createdAt: Date()
    )
}
