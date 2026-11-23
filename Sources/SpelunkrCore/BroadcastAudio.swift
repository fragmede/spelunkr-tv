import Foundation

enum BroadcastAudio {
    static func overlay(program: Program, pools: [String: [AudioTrack]], videoIndex: Int, channel: String, seed: String) -> [AudioCue] {
        let decade = AdvertisementPlan.year(program.year).map { "\(($0 / 10) * 10)s" }
        var pool = decade.flatMap { pools[$0] } ?? []
        if pool.isEmpty { pool = pools["default"] ?? [] }
        guard !pool.isEmpty else { return [] }
        var random = BroadcastRandom(seed: "\(channel)-audio-\(videoIndex)-\(seed)")
        if pool.count > 1 {
            for index in stride(from: pool.count - 1, through: 1, by: -1) { pool.swapAt(index, random.index(count: index + 1)) }
        }
        var elapsed: Int64 = 0
        var result: [AudioCue] = []
        for index in 0..<(pool.count * 3) {
            guard elapsed < Int64(program.duration) * 1_000 else { break }
            let track = pool[index % pool.count]
            guard let duration = track.duration, duration.isFinite, duration > 0 else { continue }
            let end = elapsed + Int64((duration * 1_000).rounded())
            result.append(AudioCue(track: track, startMs: elapsed, endMs: end, mediaStart: 0, volume: 1, fade: 0))
            elapsed = end
        }
        return result
    }

    static func bumpTrack(_ bump: Bump, pool: [AudioTrack], breakIndex: Int, seed: String) -> (AudioTrack, Double)? {
        guard !pool.isEmpty else { return nil }
        if let slide = bump.slides.first(where: { $0.track != nil }), let track = pool.first(where: { $0.filename == slide.track }) {
            let offset = slide.trackAt ?? 0
            return (track, offset > 0 && offset < 10 ? offset : 0)
        }
        var random = BroadcastRandom(seed: "\(bump.id)-audio-\(breakIndex)-\(seed)")
        let track = pool[random.index(count: pool.count)]
        return (track, floor(random.next() * 60))
    }

    static func presentation(channel: Bump?, platform: Bump?, channelPool: [AudioTrack], platformPool: [AudioTrack], breakIndex: Int, seed: String) -> (slides: [SlideCue], audio: [AudioCue]) {
        var slides: [SlideCue] = []
        var audio: [AudioCue] = []
        var cursor: Int64 = channel == nil ? 0 : 3_500
        for (bump, pool) in [(channel, channelPool), (platform, platformPool)] {
            guard let bump else { continue }
            let start = cursor
            for (index, slide) in bump.slides.enumerated() {
                let end = cursor + BumpDeck.slideDuration(slide.text) + (index == 0 ? 1_000 : 0)
                slides.append(SlideCue(text: slide.text, startMs: cursor, endMs: end))
                cursor = end
            }
            cursor += 1_000
            if let (track, mediaStart) = bumpTrack(bump, pool: pool, breakIndex: breakIndex, seed: seed) {
                audio.append(AudioCue(track: track, startMs: start, endMs: cursor, mediaStart: mediaStart, volume: 0.3, fade: 2))
            }
            if bump.id == channel?.id && platform != nil { cursor += 300 }
        }
        return (slides, audio)
    }
}
