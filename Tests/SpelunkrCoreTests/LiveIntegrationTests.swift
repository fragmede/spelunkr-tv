import Foundation
import Testing
import SpelunkrCore

struct LiveIntegrationTests {
    @Test(.enabled(if: ProcessInfo.processInfo.environment["SPELUNKR_LIVE_TESTS"] == "1"))
    func everyPublishedChannelLoadsAndResolves() async throws {
        let client = CatalogClient()
        let catalog = try await client.loadCatalog()
        #expect(!catalog.channels.isEmpty)
        for channel in catalog.channels where channel.comingSoon != true {
            let schedule = try await client.loadSchedule(for: channel)
            let airing = schedule.airing()
            #expect(airing.endDate > Date(), Comment(rawValue: channel.id))
            if airing.kind == .video || airing.kind == .advertisement {
                #expect(airing.mediaURL?.scheme == "https", Comment(rawValue: channel.id))
            }
            #expect(schedule.upcoming(count: 1).count == 1, Comment(rawValue: channel.id))
        }
        print("Verified \(catalog.channels.count) real channels; catalog source: \(catalog.source.rawValue).")
    }
}
