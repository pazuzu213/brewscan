import Foundation

struct SavedScan: Codable, Identifiable {
    var id: UUID
    var date: Date
    var podName: String
    var podId: String?
    var podColor: String  // hex
    var confidence: Double
    var line: String      // e.g. "Original Line"
    var intensity: Int
}
