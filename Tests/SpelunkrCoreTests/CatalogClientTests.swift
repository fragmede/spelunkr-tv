import Foundation
import Testing
@testable import SpelunkrCore

struct CatalogClientTests {
    @Test func blockedCDNFallsBackToPublishedSnapshot() async throws {
        let transport = MockTransport(liveStatus: 403)
        let result = try await CatalogClient(transport: transport).loadCatalog()
        #expect(result.source == .snapshot)
        #expect(result.generatedAt != nil)
        #expect(result.channels.map(\.id) == ["test-channel"])
        #expect(await transport.hosts == ["data.spelunkr.tv", "spelunkr.tv"])
    }

    @Test func successfulLiveCatalogIsNotLabeledSnapshot() async throws {
        let transport = MockTransport(liveStatus: 200)
        let result = try await CatalogClient(transport: transport).loadCatalog()
        #expect(result.source == .live)
        #expect(await transport.hosts == ["data.spelunkr.tv"])
    }

    @Test func htmlChallengeAlsoFallsBack() async throws {
        let transport = MockTransport(liveStatus: 200, liveData: Data("<html>Challenge</html>".utf8))
        let result = try await CatalogClient(transport: transport).loadCatalog()
        #expect(result.source == .snapshot)
    }

    @Test(arguments: ["https://media.example.test/station-music/", "http://media.example.test/station-music/", ""])
    func lineupAudioBaseReachesScheduledPlayback(address: String) async throws {
        let client = CatalogClient(transport: AudioBaseTransport(address: address))
        let catalog = try await client.loadCatalog()
        let channel = try #require(catalog.channels.first)
        let schedule = try await client.loadSchedule(for: channel)
        // Ten seconds of video, then a 3.5-second bumper intro, then the music.
        let airing = schedule.airing(at: Date(timeIntervalSince1970: 1_795_305_614.5))
        let audio = try #require(airing.audio)
        let expectedBase = address.hasPrefix("https://") ? address : "https://audio.spelunkr.tv/bumps/"
        #expect(audio.url.absoluteString == expectedBase + "theme.mp3")
    }

    @Test func cancellationDoesNotStartFallbackRequest() async throws {
        let transport = MockTransport(liveStatus: 200)
        let task = Task {
            while !Task.isCancelled { await Task.yield() }
            return try await CatalogClient(transport: transport).loadCatalog()
        }
        task.cancel()
        do {
            _ = try await task.value
            Issue.record("A canceled catalog request succeeded")
        } catch is CancellationError {
            #expect(await transport.hosts.isEmpty)
        }
    }
}

private struct AudioBaseTransport: HTTPTransport {
    let address: String

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let url = request.url!
        let data: Data
        switch url.lastPathComponent {
        case "lineup.json":
            var payload = try #require(JSONSerialization.jsonObject(with: MockTransport.lineup) as? [String: Any])
            if !address.isEmpty { payload["audioBase"] = address }
            data = try JSONSerialization.data(withJSONObject: payload)
        case "v1.json":
            data = Data(#"{"engine":5,"channel":"test-channel","version":1,"items":[{"id":"tape","title":"Tape","duration":10,"file":"tape.mp4"}],"bumps":[{"id":"b1","slides":[{"text":"Hello"}]}],"audio":[{"filename":"theme.mp3","title":"Theme","artist":"Artist"}],"platform":"platform/test.json"}"#.utf8)
        default:
            data = Data(#"{"bumps":[{"id":"p1","slides":[{"text":"Spelunkr"}]}]}"#.utf8)
        }
        return (data, HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }
}

private actor MockTransport: HTTPTransport {
    let liveStatus: Int
    let liveData: Data?
    var hosts: [String] = []
    static let lineup = Data(##"{"engine":5,"generatedAt":"2026-11-20T20:51:17.287Z","channels":[{"id":"test-channel","name":"TEST","description":"A test channel","color":"#00FF00","dial":2,"versions":[{"v":1,"manifest":"manifests/test-channel/v1.json","epochMs":1795305600000,"effectiveAtMs":1795305600000}]}]}"##.utf8)

    init(liveStatus: Int, liveData: Data? = nil) {
        self.liveStatus = liveStatus
        self.liveData = liveData
    }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let url = request.url!
        hosts.append(url.host!)
        let live = url.host == "data.spelunkr.tv"
        return (live ? liveData ?? Self.lineup : Self.lineup, HTTPURLResponse(url: url, statusCode: live ? liveStatus : 200, httpVersion: nil, headerFields: nil)!)
    }
}
