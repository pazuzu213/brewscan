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
    var rating: Int?
    var imageData: Data?
    var brand: String?
    var origin: String?
    var summary: String?
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
        rating: Int? = nil,
        imageData: Data? = nil,
        brand: String? = nil,
        origin: String? = nil,
        summary: String? = nil,
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
        self.rating = rating
        self.imageData = imageData
        self.brand = brand
        self.origin = origin
        self.summary = summary
        self.notes = notes
    }

    // Backward-compatible decoding — existing saved scans without newer fields still load.
    enum CodingKeys: String, CodingKey {
        case id, date, podName, podId, podColor, confidence, line, intensity, rating, imageData, brand, origin, summary, notes
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
        rating     = try c.decodeIfPresent(Int.self, forKey: .rating)
        imageData  = try c.decodeIfPresent(Data.self, forKey: .imageData)
        brand      = try c.decodeIfPresent(String.self, forKey: .brand)
        origin     = try c.decodeIfPresent(String.self, forKey: .origin)
        summary    = try c.decodeIfPresent(String.self, forKey: .summary)
        notes      = (try? c.decode([ScanNote].self, forKey: .notes)) ?? []
    }
}
