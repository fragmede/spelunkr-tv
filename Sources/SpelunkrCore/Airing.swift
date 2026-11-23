import Foundation

public struct Airing: Identifiable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case video
        case bump
        case upNext
        case advertisement
    }

    public let id: String
    public let kind: Kind
    public let program: Program?
    public let title: String
    public let startDate: Date
    public let endDate: Date
    public let offset: Double
    public let mediaOffset: Double
    public let slides: [String]
    public let mediaURL: URL?
    public let advertisementGainDb: Double?
    public let audio: AudioPlayback?
    /// Nil during the black gaps around a station break.
    public let currentSlide: String?

    public var remaining: Double { max(0, endDate.timeIntervalSince(startDate) - offset) }
    public var progress: Double { min(1, max(0, offset / max(0.001, endDate.timeIntervalSince(startDate)))) }
}
