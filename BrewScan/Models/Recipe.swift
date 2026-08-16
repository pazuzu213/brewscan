import Foundation

struct Recipe: Codable, Identifiable {
    let id: String
    let name: String
    let compatiblePodIds: [String]
    let difficulty: String
    let prepTime: String
    let ingredients: [String]
    let steps: [String]
    let emoji: String

    var difficultyColor: String {
        switch difficulty {
        case "Easy":
            return "#2E7D32"
        case "Medium":
            return "#F57F17"
        case "Hard":
            return "#C62828"
        default:
            return "#2E7D32"
        }
    }
}
