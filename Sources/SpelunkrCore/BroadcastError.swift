import Foundation

public enum BroadcastError: Error, LocalizedError, Sendable {
    case unsupportedEngine(Int)
    case invalidSchedule(String)
    case unavailable
    case invalidPath
    case http(Int)

    public var errorDescription: String? {
        switch self {
        case .unsupportedEngine: "Spelunkr has updated its broadcast format. This app needs an update."
        case .invalidSchedule(let reason): "This channel's schedule is unavailable: \(reason)"
        case .unavailable: "The channel guide could not be reached. Check your connection and try again."
        case .invalidPath: "The channel guide returned an invalid resource address."
        case .http(let code): "The broadcast server returned HTTP \(code)."
        }
    }
}
