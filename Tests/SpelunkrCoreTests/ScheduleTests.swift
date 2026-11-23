import Foundation
import Testing
@testable import SpelunkrCore

struct ScheduleTests {
    @Test func websiteScheduleParity() throws {
        let fixtures = try fixtures()
        for fixture in fixtures {
            let schedule = try ChannelSchedule(channelID: "test-channel", versions: fixture.versions.map(\.value))
            for expected in fixture.expected {
                let actual = schedule.airing(at: Date(timeIntervalSince1970: Double(expected.atMs) / 1_000))
                let context = Comment(rawValue: "\(fixture.name) at \(expected.atMs)")
                #expect(actual.id == "test-channel:\(expected.key)", context)
                #expect(actual.kind == expected.airingKind, context)
                #expect(actual.program?.id == expected.programID, context)
                #expect(Int64((actual.startDate.timeIntervalSince1970 * 1_000).rounded()) == expected.startMs, context)
                #expect(Int64((actual.endDate.timeIntervalSince1970 * 1_000).rounded()) == expected.endMs, context)
                #expect(abs(actual.offset - expected.offset) < 0.000_01, context)
                #expect(abs(actual.mediaOffset - expected.mediaOffset) < 0.000_01, context)
                if actual.kind == .bump { #expect(actual.slides == expected.slides, context) }
                if let key = expected.audioKey {
                    #expect(actual.audio != nil, context)
                    #expect(actual.audio?.url.absoluteString.contains(key) == true, context)
                    if let offset = expected.audioOffset { #expect(abs((actual.audio?.offset ?? -1) - offset) < 0.000_01, context) }
                } else {
                    #expect(actual.audio == nil, context)
                }
                if actual.kind == .bump { #expect(actual.currentSlide == expected.currentSlide, context) }
                if let adID = expected.adID {
                    let ad = fixture.versions.flatMap { $0.manifest.ads?.slices ?? [] }.first { $0.id == adID }
                    #expect(actual.mediaURL == ad?.mediaURL, context)
                }
            }
        }
    }

    @Test func upcomingExcludesCurrentAndInterstitials() throws {
        let fixture = try #require(fixtures().first { $0.name == "ads" })
        let schedule = try ChannelSchedule(channelID: "test-channel", versions: fixture.versions.map(\.value))
        let date = Date(timeIntervalSince1970: Double(fixture.versions[0].pointer.epochMs) / 1_000)
        let current = schedule.airing(at: date)
        let upcoming = schedule.upcoming(at: date, count: 3)
        #expect(upcoming.count == 3)
        #expect(upcoming.allSatisfy { $0.kind == .video && $0.id != current.id && $0.startDate >= current.endDate })
    }

    @Test func archiveURLsEncodeEachMediaIdentifierAndFilename() throws {
        let program = try JSONDecoder().decode(Program.self, from: Data(#"{"id":"tape #one","title":"A tape","duration":90,"file":"folder/a & b?.mp4"}"#.utf8))
        #expect(program.mediaURL?.absoluteString == "https://archive.org/download/tape%20%23one/folder%2Fa%20%26%20b%3F.mp4")
        #expect(program.archiveURL?.absoluteString == "https://archive.org/details/tape%20%23one")
        #expect(program.thumbnailURL?.absoluteString == "https://archive.org/services/img/tape%20%23one")
    }

    @Test func invalidDurationFailsInsteadOfLoopingForever() throws {
        let fixture = try #require(fixtures().first)
        let data = try JSONEncoder().encode(fixture.versions[0].manifest)
        var dictionary = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        dictionary["items"] = [["id": "bad", "title": "Bad", "duration": 0]]
        let manifest = try JSONDecoder().decode(Manifest.self, from: JSONSerialization.data(withJSONObject: dictionary))
        #expect(throws: BroadcastError.self) {
            try ChannelSchedule(channelID: "test-channel", versions: [ScheduleVersion(pointer: fixture.versions[0].pointer, manifest: manifest, platform: nil)])
        }
    }

    private func fixtures() throws -> [ParityFixture] {
        let url = try #require(Bundle.module.url(forResource: "schedule-parity", withExtension: "json", subdirectory: "Fixtures"))
        return try JSONDecoder().decode([ParityFixture].self, from: Data(contentsOf: url))
    }
}

private struct ParityFixture: Decodable {
    let name: String
    let versions: [VersionFixture]
    let expected: [ExpectedAiring]
}

private struct VersionFixture: Decodable {
    let pointer: SchedulePointer
    let manifest: Manifest
    let platform: PlatformManifest?
    var value: ScheduleVersion { ScheduleVersion(pointer: pointer, manifest: manifest, platform: platform) }
}

private struct ExpectedAiring: Decodable {
    let atMs: Int64
    let key: String
    let kind: String
    let programID: String?
    let adID: String?
    let startMs: Int64
    let endMs: Int64
    let offset: Double
    let mediaOffset: Double
    let slides: [String]
    let audioKey: String?
    let audioOffset: Double?
    let currentSlide: String?
    var airingKind: Airing.Kind {
        switch kind {
        case "bump-break": .bump
        case "up-next": .upNext
        case "ad": .advertisement
        default: .video
        }
    }
}
