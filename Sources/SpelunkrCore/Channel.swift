import Foundation

public struct Channel: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let description: String
    public let color: String
    public let emoji: String?
    public let family: String?
    public let dial: Int?
    public let comingSoon: Bool?
    public let debugOnly: Bool?
    public let audioOverlay: Bool?
    public let versions: [SchedulePointer]

    public var number: Int { dial ?? 0 }
    public var colorHex: String { color }
    public var logoURL: URL? { nil }
    public var category: String {
        switch family {
        case "rewind": "Rewind"
        case "tv-series": "TV Series"
        case "film": "Movies"
        case "archive": "The Archive"
        default: "Other"
        }
    }
}
