import Foundation

struct ScanNote: Codable, Identifiable {
    var id: UUID
    var date: Date
    var text: String
}

struct SavedScan: Codable, Identifiable {
    var id: UUID
    var date: Date
    var podName: String
    var podId: String?
    var podColor: String  // hex
    var confidence: Double
    var line: String      // e.g. "Original Line"
    var intensity: Int
    var notes: [ScanNote]

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        podName: String,
        podId: String? = nil,
        podColor: String,
        confidence: Double,
        line: String,
        intensity: Int,
        notes: [ScanNote] = []
    ) {
        self.id = id
        self.date = date
        self.podName = podName
        self.podId = podId
        self.podColor = podColor
        self.confidence = confidence
        self.line = line
        self.intensity = intensity
        self.notes = notes
    }

    // Backward-compatible decoding — existing saved scans without `notes` default to []
    enum CodingKeys: String, CodingKey {
        case id, date, podName, podId, podColor, confidence, line, intensity, notes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id         = try c.decode(UUID.self,   forKey: .id)
        date       = try c.decode(Date.self,   forKey: .date)
        podName    = try c.decode(String.self, forKey: .podName)
        podId      = try c.decodeIfPresent(String.self, forKey: .podId)
        podColor   = try c.decode(String.self, forKey: .podColor)
        confidence = try c.decode(Double.self, forKey: .confidence)
        line       = try c.decode(String.self, forKey: .line)
        intensity  = try c.decode(Int.self,    forKey: .intensity)
        notes      = (try? c.decode([ScanNote].self, forKey: .notes)) ?? []
    }
}
