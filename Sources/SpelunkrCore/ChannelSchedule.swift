import Foundation
import Synchronization

/// A validated, synchronized channel. Resolution is safe from multiple tasks.
public final class ChannelSchedule: Sendable {
    public let channelID: String
    private let state: Mutex<ScheduleState>

    public init(channelID: String, versions: [ScheduleVersion], audioBase: URL = URL(string: "https://audio.spelunkr.tv/bumps/")!) throws {
        guard !versions.isEmpty else { throw BroadcastError.invalidSchedule("no published version") }
        for version in versions {
            let manifest = version.manifest
            guard (1...5).contains(manifest.engine) else { throw BroadcastError.unsupportedEngine(manifest.engine) }
            guard manifest.channel == channelID, manifest.version == nil || manifest.version == version.pointer.v else {
                throw BroadcastError.invalidSchedule("version does not match the channel")
            }
            guard !manifest.items.isEmpty, manifest.items.allSatisfy({ $0.duration > 0 && $0.duration <= 31_536_000 }) else {
                throw BroadcastError.invalidSchedule("invalid program duration")
            }
            guard manifest.items.indices.contains(version.pointer.startIndex ?? 0) else { throw BroadcastError.invalidSchedule("invalid starting program") }
            if let block = manifest.block {
                guard block.lengthMs > 0, block.cardMs > 0, (block.stings ?? []).allSatisfy({ $0.lengthMs > 0 }) else {
                    throw BroadcastError.invalidSchedule("invalid program block")
                }
            }
            if let ads = manifest.ads {
                guard ads.slices.allSatisfy({ $0.lengthMs > 0 && ($0.inMs ?? 0) >= 0 }), (ads.gapMs ?? 0) >= 0 else {
                    throw BroadcastError.invalidSchedule("invalid advertisement timing")
                }
            }
        }
        self.channelID = channelID
        self.state = Mutex(ScheduleState(versions: versions.sorted { $0.pointer.v < $1.pointer.v }.map { VersionState($0, audioBase: audioBase) }))
    }

    public func airing(at date: Date = Date()) -> Airing {
        state.withLock { $0.airing(at: Int64((date.timeIntervalSince1970 * 1_000).rounded())) }
    }

    /// Future program listings, excluding the current airing and all interstitials.
    public func upcoming(at date: Date = Date(), count: Int = 3) -> [Airing] {
        guard count > 0 else { return [] }
        return state.withLock { state in
            let current = state.airing(at: Int64((date.timeIntervalSince1970 * 1_000).rounded()))
            var time = Int64((current.endDate.timeIntervalSince1970 * 1_000).rounded())
            var result: [Airing] = []
            for _ in 0..<(min(count, 100) * 8 + 16) {
                let airing = state.airing(at: time)
                if airing.kind == .video { result.append(airing) }
                if result.count >= min(count, 100) { break }
                time = Int64((airing.endDate.timeIntervalSince1970 * 1_000).rounded())
            }
            return result
        }
    }
}

private struct ScheduleState {
    var versions: [VersionState]

    mutating func airing(at time: Int64) -> Airing {
        let index = versions.lastIndex { $0.version.pointer.effectiveAtMs <= time }
            ?? versions.indices.min { versions[$0].version.pointer.effectiveAtMs < versions[$1].version.pointer.effectiveAtMs }!
        let currentVersion = versions[index].version.pointer.v
        let boundary = versions.filter { $0.version.pointer.v > currentVersion && $0.version.pointer.effectiveAtMs > time }.map { $0.version.pointer.effectiveAtMs }.min()
        return versions[index].airing(at: time, boundary: boundary)
    }
}

private struct ScheduleEntry: Sendable {
    let kind: Airing.Kind
    let program: Program?
    let advertisement: Advertisement?
    let slides: [String]
    let slideCues: [SlideCue]
    let audioCues: [AudioCue]
    let offsetMs: Int64
    let durationMs: Int64
}

private struct BroadcastCycle: Sendable {
    let startMs: Int64
    let lengthMs: Int64
    let entries: [ScheduleEntry]
}

private struct AdCarry: Sendable {
    var fromMs: Int64?
    var recent: [(index: Int, time: Int64)] = []
}

private struct VersionState {
    let version: ScheduleVersion
    let audioBase: URL
    let adPlan: AdvertisementPlan?
    var forward: [BroadcastCycle] = []
    var backward: [BroadcastCycle] = []
    var deckCarry = BumpDeck()
    var adCarry = AdCarry()

    init(_ version: ScheduleVersion, audioBase: URL) {
        self.version = version
        self.audioBase = audioBase
        if let pool = version.manifest.ads, !pool.slices.isEmpty {
            adPlan = AdvertisementPlan(pool: pool, items: version.manifest.items, block: version.manifest.block, channel: version.manifest.channel)
        } else { adPlan = nil }
    }

    mutating func airing(at time: Int64, boundary: Int64?) -> Airing {
        let cycleIndex: Int
        let cycle: BroadcastCycle
        if time >= version.pointer.epochMs {
            while forward.last.map({ time >= $0.startMs + $0.lengthMs }) ?? true {
                let start = forward.last.map { $0.startMs + $0.lengthMs } ?? version.pointer.epochMs
                forward.append(buildCycle(index: forward.count, startMs: start))
            }
            cycleIndex = forward.lastIndex { $0.startMs <= time }!
            cycle = forward[cycleIndex]
        } else {
            while backward.last.map({ time < $0.startMs }) ?? true {
                let end = backward.last?.startMs ?? version.pointer.epochMs
                let built = buildCycle(index: -(backward.count + 1), startMs: 0)
                backward.append(BroadcastCycle(startMs: end - built.lengthMs, lengthMs: built.lengthMs, entries: built.entries))
            }
            let index = backward.firstIndex { $0.startMs <= time }!
            cycleIndex = -(index + 1)
            cycle = backward[index]
        }
        let elapsed = time - cycle.startMs
        let index = cycle.entries.lastIndex { $0.offsetMs <= elapsed } ?? 0
        let entry = cycle.entries[index]
        let start = cycle.startMs + entry.offsetMs
        let end = min(start + entry.durationMs, boundary ?? Int64.max)
        let offset = Double(time - start) / 1_000
        let title: String
        switch entry.kind {
        case .video: title = entry.program?.title ?? "On Air"
        case .bump: title = "Station Break"
        case .upNext: title = "Up Next"
        case .advertisement: title = "From the Archives"
        }
        let airingID = "\(version.manifest.channel):\(version.pointer.v):\(cycleIndex):\(index)"
        let audio = entry.audioCues.enumerated().compactMap { cueIndex, cue in
            cue.playback(at: offset, id: "\(airingID):audio:\(cueIndex)", base: audioBase)
        }.first
        let slide = entry.slideCues.first { Double($0.startMs) <= offset * 1_000 && Double($0.endMs) > offset * 1_000 }?.text
        return Airing(
            id: airingID,
            kind: entry.kind, program: entry.program, title: title,
            startDate: Date(timeIntervalSince1970: Double(start) / 1_000),
            endDate: Date(timeIntervalSince1970: Double(end) / 1_000), offset: offset,
            mediaOffset: offset + Double(entry.program?.inS ?? 0) + Double(entry.advertisement?.inMs ?? 0) / 1_000,
            slides: entry.slides, mediaURL: entry.program?.mediaURL ?? entry.advertisement?.mediaURL,
            advertisementGainDb: entry.advertisement?.gainDb,
            audio: audio, currentSlide: slide
        )
    }

    private mutating func buildCycle(index cycleIndex: Int, startMs: Int64) -> BroadcastCycle {
        let manifest = version.manifest
        let firstIndex = cycleIndex == 0 ? version.pointer.startIndex ?? 0 : 0
        let items = Array(manifest.items.dropFirst(firstIndex))
        let seed = "\(version.pointer.v).\(cycleIndex)"
        let channelBumps = manifest.bumps ?? []
        let platformBumps = version.platform?.bumps ?? []
        let hasBumps = !channelBumps.isEmpty && !platformBumps.isEmpty
        // The published decade pools are ordered chronologically, then the default pool.
        let channelAudio = manifest.audioOverlay == true
            ? (manifest.audioPools ?? [:]).keys.sorted().flatMap { manifest.audioPools?[$0] ?? [] }
            : manifest.audio ?? []
        let platformAudio = version.platform?.audio ?? []
        var entries: [ScheduleEntry] = []
        var elapsed: Int64 = 0
        var blockElapsed: Int64 = 0
        var adElapsed: Int64 = 0
        var deck = cycleIndex >= 1 ? deckCarry : BumpDeck()
        deck.rounds = 0
        var carry = cycleIndex >= 1 ? adCarry : AdCarry()
        var used = Set(carry.recent.map(\.index))
        var lastAdFrom = carry.fromMs
        var recent: [(index: Int, time: Int64)] = []
        func append(_ kind: Airing.Kind, duration: Int64, program: Program? = nil, advertisement: Advertisement? = nil, slides: [String] = [], presentation: (slides: [SlideCue], audio: [AudioCue]) = ([], [])) {
            entries.append(ScheduleEntry(kind: kind, program: program, advertisement: advertisement, slides: slides, slideCues: presentation.slides, audioCues: presentation.audio, offsetMs: elapsed, durationMs: duration))
            elapsed += duration
        }
        for (index, item) in items.enumerated() {
            let breakIndex = firstIndex + index
            let duration = Int64(item.duration) * 1_000
            let overlay = manifest.audioOverlay == true
                ? BroadcastAudio.overlay(program: item, pools: manifest.audioPools ?? [:], videoIndex: breakIndex, channel: manifest.channel, seed: seed)
                : []
            append(.video, duration: duration, program: item, presentation: ([], overlay))
            blockElapsed += duration; adElapsed += duration
            guard hasBumps else { continue }
            if let block = manifest.block, index < items.count - 1, blockElapsed < block.lengthMs {
                var random = BroadcastRandom(seed: "\(manifest.channel)-card-\(breakIndex)-\(seed)")
                let stings = block.stings ?? []
                let sting = stings.isEmpty ? nil : stings[random.index(count: stings.count)]
                let cardDuration = sting?.lengthMs ?? block.cardMs
                var sound: [AudioCue] = []
                if let sting, let file = sting.track {
                    let track = AudioTrack(id: nil, file: nil, filename: file, title: sting.title, artist: sting.artist, license: sting.license, duration: nil)
                    sound = [AudioCue(track: track, startMs: 0, endMs: cardDuration, mediaStart: Double(sting.startMs ?? 0) / 1_000, volume: 0.3, fade: 0)]
                }
                append(.upNext, duration: cardDuration, slides: ["Up next", items[index + 1].title], presentation: ([SlideCue(text: items[index + 1].title, startMs: 0, endMs: cardDuration)], sound))
                blockElapsed += cardDuration; adElapsed += cardDuration
                continue
            }
            blockElapsed = 0
            let time = cycleIndex < 0 ? version.pointer.epochMs : startMs + elapsed
            let channelBump = manifest.engine >= 5
                ? deck.take(from: channelBumps, channel: manifest.channel, seed: seed, at: time)
                : BumpDeck.pick(from: channelBumps, breakIndex: breakIndex, channel: manifest.channel, seed: seed, at: time)
            guard let channelBump,
                  let platformBump = BumpDeck.pick(from: platformBumps, breakIndex: breakIndex, channel: "spelunkr", seed: seed, at: time) else { continue }
            let next = index < items.count - 1 ? items[index + 1] : manifest.items[0]
            if let adPlan, item.offAir != true, next.offAir != true, adElapsed >= (adPlan.pool.gapMs ?? 1_200_000) {
                let selected = adPlan.pick(used: &used, year: AdvertisementPlan.year(item.year), now: startMs + elapsed, since: lastAdFrom ?? startMs + elapsed - adElapsed)
                let advertisement = adPlan.pool.slices[selected]
                lastAdFrom = nil
                recent.append((selected, startMs + elapsed))
                let opening = BroadcastAudio.presentation(channel: channelBump, platform: nil, channelPool: channelAudio, platformPool: [], breakIndex: breakIndex, seed: seed)
                append(.bump, duration: 5_500 + BumpDeck.duration(channelBump), slides: channelBump.slides.map(\.text), presentation: opening)
                append(.advertisement, duration: advertisement.lengthMs, advertisement: advertisement)
                let closeDuration = 2_000 + BumpDeck.duration(platformBump)
                let closing = BroadcastAudio.presentation(channel: nil, platform: platformBump, channelPool: [], platformPool: platformAudio, breakIndex: breakIndex, seed: seed)
                append(.bump, duration: closeDuration, slides: platformBump.slides.map(\.text), presentation: closing)
                adElapsed = closeDuration
                carry.fromMs = startMs + elapsed
            } else {
                let breakDuration = 7_800 + BumpDeck.duration(channelBump) + BumpDeck.duration(platformBump)
                let presentation = BroadcastAudio.presentation(channel: channelBump, platform: platformBump, channelPool: channelAudio, platformPool: platformAudio, breakIndex: breakIndex, seed: seed)
                append(.bump, duration: breakDuration, slides: channelBump.slides.map(\.text) + platformBump.slides.map(\.text), presentation: presentation)
                adElapsed += breakDuration
            }
        }
        if cycleIndex >= 0 {
            deckCarry = deck
            if recent.isEmpty { carry.fromMs = lastAdFrom ?? startMs }
            carry.recent = (carry.recent + recent).filter { $0.time >= startMs + elapsed - 86_400_000 }
            adCarry = carry
        }
        return BroadcastCycle(startMs: startMs, lengthMs: elapsed, entries: entries)
    }
}
