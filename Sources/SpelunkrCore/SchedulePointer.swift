import Foundation

public struct SchedulePointer: Codable, Hashable, Sendable {
    public let v: Int
    public let manifest: String
    public let details: String?
    public let epochMs: Int64
    public let effectiveAtMs: Int64
    public let startIndex: Int?
}
