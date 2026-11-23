import Foundation

public struct Program: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let duration: Int
    public let year: String?
    public let mp4: String?
    public let file: String?
    public let inS: Int?
    public let outS: Int?
    public let offAir: Bool?
    public let mature: Bool?

    public var mediaURL: URL? { ArchiveURL.media(identifier: id, file: file ?? mp4) }
    public var archiveURL: URL? { ArchiveURL.page(identifier: id) }
    public var thumbnailURL: URL? { ArchiveURL.thumbnail(identifier: id) }
}
