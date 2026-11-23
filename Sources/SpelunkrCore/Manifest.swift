import Foundation

public struct Manifest: Codable, Sendable {
    public let engine: Int
    public let channel: String
    public let version: Int?
    public let items: [Program]
    public let bumps: [Bump]?
    public let platform: String?
    public let block: BroadcastBlock?
    public let ads: AdvertisementPool?
    public let audio: [AudioTrack]?
    public let audioPools: [String: [AudioTrack]]?
    public let audioOverlay: Bool?
}

public struct PlatformManifest: Codable, Sendable {
    public let bumps: [Bump]
    public let audio: [AudioTrack]?
}

public struct Bump: Codable, Hashable, Sendable {
    public let id: String
    public let slides: [BumpSlide]
    public let active: Bool?
    public let date_range: [String]?
}

public struct BumpSlide: Codable, Hashable, Sendable {
    public let text: String
    public let track: String?
    public let trackAt: Double?
}

public struct BroadcastBlock: Codable, Sendable {
    public let lengthMs: Int64
    public let cardMs: Int64
    public let stings: [Sting]?
}

public struct Sting: Codable, Sendable {
    public let lengthMs: Int64
    public let startMs: Int64?
    public let track: String?
    public let title: String?
    public let artist: String?
    public let license: String?
}

public struct AdvertisementPool: Codable, Sendable {
    public let slices: [Advertisement]
    public let start: Int?
    public let gapMs: Int64?
    public let decades: Int?
}

public struct Advertisement: Codable, Sendable {
    public let id: String
    public let tape: String
    public let file: String
    public let inMs: Int64?
    public let lengthMs: Int64
    public let year: String?
    public let anywhere: Bool?
    public let gainDb: Double?

    public var mediaURL: URL? { ArchiveURL.media(identifier: tape, file: file) }
}
