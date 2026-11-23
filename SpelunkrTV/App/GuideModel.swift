import Foundation
import Observation
import SpelunkrCore

@MainActor
@Observable
final class GuideModel {
    private(set) var channels: [ChannelViewData] = []
    var focusedChannelID: String?
    var selectedCategory: String?
    var searchText = ""
    var showingFavorites = false
    private(set) var favoriteIDs: Set<String>
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var statusMessage: String?
    private(set) var lastUpdated: Date?

    @ObservationIgnored private let client: CatalogClient
    @ObservationIgnored private let favorites: FavoritesStore
    @ObservationIgnored private var catalogChannels: [Channel] = []
    @ObservationIgnored private var schedules: [String: ChannelSchedule] = [:]
    @ObservationIgnored private var scheduleErrors: [String: String] = [:]

    init(client: CatalogClient = CatalogClient(), favorites: FavoritesStore = FavoritesStore()) {
        self.client = client
        self.favorites = favorites
        favoriteIDs = favorites.load()
    }

    var visibleChannels: [ChannelViewData] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return channels.filter { channel in
            (!showingFavorites || favoriteIDs.contains(channel.id))
                && (selectedCategory == nil || channel.category == selectedCategory)
                && (query.isEmpty || channel.name.localizedStandardContains(query)
                    || channel.description.localizedStandardContains(query)
                    || channel.current?.title.localizedStandardContains(query) == true
                    || String(channel.number).localizedStandardContains(query))
        }
    }

    var selectedChannel: ChannelViewData? {
        let visible = visibleChannels
        return visible.first { $0.id == focusedChannelID } ?? visible.first
    }

    var categoryOptions: [String] {
        Array(Set(channels.map(\.category))).sorted()
    }

    func toggleFavorite(_ channelID: String) {
        if favoriteIDs.contains(channelID) {
            favoriteIDs.remove(channelID)
        } else {
            favoriteIDs.insert(channelID)
        }
        favorites.save(favoriteIDs)
    }

    func run() async {
        await refresh()
        while !Task.isCancelled {
            do {
                try await Task.sleep(for: .seconds(15))
            } catch {
                return
            }
            if let lastUpdated, Date.now.timeIntervalSince(lastUpdated) >= 900 {
                await refresh()
            } else {
                updateAiring()
            }
        }
    }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let catalog = try await client.loadCatalog()
            try Task.checkCancellation()
            let previousChannels = Dictionary(uniqueKeysWithValues: catalogChannels.map { ($0.id, $0) })
            catalogChannels = catalog.channels.sorted { $0.number < $1.number }
            let activeIDs = Set(catalogChannels.map(\.id))
            schedules = schedules.filter { activeIDs.contains($0.key) }
            scheduleErrors = scheduleErrors.filter { activeIDs.contains($0.key) }
            for channel in catalogChannels where previousChannels[channel.id]?.versions != channel.versions {
                schedules[channel.id] = nil
                scheduleErrors[channel.id] = nil
            }
            updateAiring()
            await loadSchedules()
            try Task.checkCancellation()
            lastUpdated = .now
            let failed = scheduleErrors.count
            if failed > 0 {
                statusMessage = "\(failed) channels couldn’t be updated. Try refreshing the guide."
            } else if catalog.source == .snapshot {
                statusMessage = "Using Spelunkr’s backup broadcast catalog."
            } else {
                statusMessage = nil
            }
        } catch is CancellationError {
            return
        } catch {
            errorMessage = "We couldn’t reach Spelunkr. Check your connection and try again."
            if !channels.isEmpty {
                statusMessage = "Showing the last available guide."
            }
        }
    }

    func updateAiring(at date: Date = .now) {
        channels = catalogChannels.map { channel in
            let schedule = schedules[channel.id]
            return ChannelViewData(
                id: channel.id,
                number: channel.number,
                name: channel.name,
                description: channel.description,
                category: channel.category,
                logoURL: channel.logoURL,
                accentHex: channel.colorHex,
                current: schedule.map { present($0.airing(at: date)) },
                next: schedule?.upcoming(at: date, count: 5).first(where: { $0.kind == .video }).map(present),
                scheduleError: scheduleErrors[channel.id]
            )
        }
    }

    func channel(id: String) -> Channel? {
        catalogChannels.first { $0.id == id }
    }

    func adjacentChannel(to id: String, direction: Int) -> Channel? {
        let lineup = visibleChannels.contains { $0.id == id } ? visibleChannels : channels
        guard !lineup.isEmpty else { return nil }
        let index = lineup.firstIndex(where: { $0.id == id }) ?? (direction > 0 ? -1 : 0)
        let nextIndex = (index + direction % lineup.count + lineup.count) % lineup.count
        return channel(id: lineup[nextIndex].id)
    }

    func cachedSchedule(for channelID: String) -> ChannelSchedule? {
        schedules[channelID]
    }

    func schedule(for channelID: String, reload: Bool = false) async throws -> ChannelSchedule {
        if !reload, let schedule = schedules[channelID] {
            return schedule
        }
        guard let channel = channel(id: channelID) else {
            throw CocoaError(.fileNoSuchFile)
        }
        let result = try await client.loadSchedule(for: channel)
        try Task.checkCancellation()
        // A catalog refresh may have changed this channel while its request was
        // in flight. Never publish the old manifest over a newer schedule.
        guard self.channel(id: channelID)?.versions == channel.versions else {
            return try await schedule(for: channelID, reload: reload)
        }
        schedules[channelID] = result
        scheduleErrors[channelID] = nil
        updateAiring()
        return result
    }

    private func loadSchedules() async {
        // Bound parallel requests to avoid overwhelming the public data hosts.
        let client = client
        await withTaskGroup(of: (String, Result<ChannelSchedule, Error>).self) { group in
            var iterator = catalogChannels.makeIterator()
            for _ in 0..<4 {
                if let channel = iterator.next() {
                    group.addTask { (channel.id, await Self.fetch(channel, client: client)) }
                }
            }
            for await (id, result) in group {
                if Task.isCancelled {
                    group.cancelAll()
                    return
                }
                switch result {
                case .success(let schedule):
                    schedules[id] = schedule
                    scheduleErrors[id] = nil
                case .failure:
                    scheduleErrors[id] = "Schedule unavailable. Select this channel to try again."
                }
                updateAiring()
                if let channel = iterator.next() {
                    group.addTask { (channel.id, await Self.fetch(channel, client: client)) }
                }
            }
        }
    }

    nonisolated private static func fetch(_ channel: Channel, client: CatalogClient) async -> Result<ChannelSchedule, Error> {
        do {
            return .success(try await client.loadSchedule(for: channel))
        } catch {
            return .failure(error)
        }
    }

    private func present(_ airing: Airing) -> ProgramViewData {
        ProgramViewData(
            id: airing.id,
            title: airing.title,
            subtitle: nil,
            startsAt: airing.startDate,
            endsAt: airing.endDate,
            thumbnailURL: airing.program?.thumbnailURL,
            isInterstitial: airing.kind != .video
        )
    }
}
