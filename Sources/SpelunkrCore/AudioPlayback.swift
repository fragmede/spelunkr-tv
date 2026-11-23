import Foundation

public struct AudioPlayback: Identifiable, Sendable {
    public let id: String
    public let url: URL
    public let offset: Double
    public let volume: Double
    public let title: String
    public let artist: String
    public let license: String?
}

public struct AudioTrack: Codable, Sendable {
    public let id: String?
    public let file: String?
    public let filename: String?
    public let title: String?
    public let artist: String?
    public let license: String?
    public let duration: Double?

    func mediaURL(base: URL) -> URL? {
        if let filename {
            if filename.hasPrefix("https://archive.org/download/") { return URL(string: filename) }
            return base.appendingPathComponent(filename)
        }
        return id.flatMap { ArchiveURL.media(identifier: $0, file: file) }
    }
}

struct AudioCue: Sendable {
    let track: AudioTrack
    let startMs: Int64
    let endMs: Int64
    let mediaStart: Double
    let volume: Double
    let fade: Double

    func playback(at offset: Double, id: String, base: URL) -> AudioPlayback? {
        let elapsed = offset - Double(startMs) / 1_000
        let remaining = Double(endMs) / 1_000 - offset
        guard elapsed >= 0, remaining > 0, let url = track.mediaURL(base: base) else { return nil }
        let envelope = fade > 0 ? min(1, elapsed / fade, remaining / fade) : 1
        return AudioPlayback(id: id, url: url, offset: mediaStart + elapsed, volume: volume * max(0, envelope), title: track.title ?? "", artist: track.artist ?? "", license: track.license)
    }
}

struct SlideCue: Sendable {
    let text: String
    let startMs: Int64
    let endMs: Int64
}
