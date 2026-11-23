import Foundation

public protocol HTTPTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

public struct URLSessionTransport: HTTPTransport {
    public init() {}
    public func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw BroadcastError.unavailable }
        return (data, response)
    }
}

public struct CatalogClient: Sendable {
    private let transport: any HTTPTransport
    private let resources = ResourceCache()
    public static let liveURL = URL(string: "https://data.spelunkr.tv/")!
    public static let snapshotURL = URL(string: "https://spelunkr.tv/broadcast/")!

    public init(transport: any HTTPTransport = URLSessionTransport()) { self.transport = transport }

    public func loadCatalog() async throws -> BroadcastCatalog {
        let (payload, source): (LineupPayload, BroadcastCatalog.Source) = try await fetch("lineup.json", cached: false)
        guard (1...5).contains(payload.engine) else { throw BroadcastError.unsupportedEngine(payload.engine) }
        let channels = payload.channels.filter { $0.debugOnly != true && !$0.versions.isEmpty }.sorted { $0.number < $1.number }
        guard !channels.isEmpty else { throw BroadcastError.unavailable }
        if let address = payload.audioBase, let url = URL(string: address), url.scheme == "https", url.host != nil {
            await resources.setAudioBase(url)
        }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return BroadcastCatalog(channels: channels, generatedAt: formatter.date(from: payload.generatedAt), source: source)
    }

    public func loadSchedule(for channel: Channel) async throws -> ChannelSchedule {
        let versions = try await withThrowingTaskGroup(of: ScheduleVersion.self) { group in
            for pointer in channel.versions {
                group.addTask {
                    let (manifest, _): (Manifest, BroadcastCatalog.Source) = try await fetch(pointer.manifest)
                    let platform: PlatformManifest?
                    if let path = manifest.platform { platform = try await fetch(path).0 } else { platform = nil }
                    return ScheduleVersion(pointer: pointer, manifest: manifest, platform: platform)
                }
            }
            var result: [ScheduleVersion] = []
            for try await version in group { result.append(version) }
            return result
        }
        return try ChannelSchedule(channelID: channel.id, versions: versions, audioBase: await resources.audioBase)
    }

    private func fetch<Value: Decodable & Sendable>(_ path: String, cached: Bool = true) async throws -> (Value, BroadcastCatalog.Source) {
        guard !path.isEmpty, !path.hasPrefix("/"), !path.contains(".."),
              path.unicodeScalars.allSatisfy({ CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._/")).contains($0) }) else { throw BroadcastError.invalidPath }
        if cached, let entry = await resources.get(path), let value = try? JSONDecoder().decode(Value.self, from: entry.data) { return (value, entry.source) }
        var lastError: any Error = BroadcastError.unavailable
        for (base, source) in [(Self.liveURL, BroadcastCatalog.Source.live), (Self.snapshotURL, .snapshot)] {
            try Task.checkCancellation()
            var request = URLRequest(url: base.appendingPathComponent(path))
            request.timeoutInterval = source == .live ? 4 : 15
            request.cachePolicy = cached ? .useProtocolCachePolicy : .reloadIgnoringLocalCacheData
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            do {
                let (data, response) = try await transport.data(for: request)
                guard (200..<300).contains(response.statusCode) else { throw BroadcastError.http(response.statusCode) }
                let value = try JSONDecoder().decode(Value.self, from: data)
                if cached { await resources.set(path, data: data, source: source) }
                return (value, source)
            } catch {
                try Task.checkCancellation()
                lastError = error
            }
        }
        throw lastError
    }
}

private actor ResourceCache {
    struct Entry: Sendable { let data: Data; let source: BroadcastCatalog.Source }
    var entries: [String: Entry] = [:]
    var audioBase = URL(string: "https://audio.spelunkr.tv/bumps/")!
    func get(_ key: String) -> Entry? { entries[key] }
    func set(_ key: String, data: Data, source: BroadcastCatalog.Source) { entries[key] = Entry(data: data, source: source) }
    func setAudioBase(_ url: URL) { audioBase = url }
}
