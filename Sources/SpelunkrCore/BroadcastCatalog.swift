import Foundation

public struct BroadcastCatalog: Sendable {
    public enum Source: String, Sendable { case live, snapshot }

    public let channels: [Channel]
    public let generatedAt: Date?
    public let source: Source
    public var sourceURL: URL { source == .live ? CatalogClient.liveURL : CatalogClient.snapshotURL }
}

struct LineupPayload: Decodable, Sendable {
    let engine: Int
    let generatedAt: String
    let channels: [Channel]
    let audioBase: String?
}
