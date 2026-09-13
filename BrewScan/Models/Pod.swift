import SwiftUI

struct Pod: Codable, Identifiable {
    let id: String
    let name: String
    let system: String?
    let line: String
    let intensity: Int
    let color: String
    let origin: String
    let roast: String
    let tastingNotes: [String]
    let aromaProfile: String
    let bodyLevel: Int
    let acidityLevel: Int
    let bitternessLevel: Int
    let description: String
    let recommendedCupSize: String
    let brewTemp: String
    let recipeIds: [String]
    let imageColor: String

    var intensityLabel: String {
        switch intensity {
        case 1...3:
            return "Light"
        case 4...6:
            return "Medium"
        case 7...8:
            return "Strong"
        case 9...10:
            return "Intense"
        case 11...13:
            return "Very Intense"
        default:
            return "Medium"
        }
    }

    var systemName: String {
        if let system, !system.isEmpty {
            return system
        }
        return ["Original", "Vertuo"].contains(line) ? "Nespresso" : line
    }

    var intensityScale: Int {
        systemName == "Nespresso" ? 13 : 10
    }

    var displayLine: String {
        systemName == "Nespresso" ? line : "\(systemName) \(line)"
    }

    var swiftUIColor: Color {
        Color(hex: color)
    }

    var lineColor: Color {
        switch systemName {
        case "Keurig":
            return Color(hex: "#2F7D32")
        case "Other":
            return Color(hex: "#5C6BC0")
        default:
            return line == "Original" ? Color(hex: "#8B1A1A") : Color(hex: "#1A4D2E")
        }
    }
}
