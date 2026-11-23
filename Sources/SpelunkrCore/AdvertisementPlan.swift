import Foundation

struct AdvertisementPlan: Sendable {
    struct Tier: Sendable {
        let indices: [Int]
        let places: [Int64]
        let roundMs: Int64
        let healthy: Bool
    }

    private static let scale: Int64 = 1_000_000
    private static let day: Int64 = 86_400_000
    private static let fortnight: Int64 = 1_209_600_000
    let pool: AdvertisementPool
    let phases: [Int64]
    let start: Int64
    let cycleMs: Double
    let byYear: [Int: Int]
    let unknownYearCount: Int

    init(pool: AdvertisementPool, items: [Program], block: BroadcastBlock?, channel: String) {
        self.pool = pool
        var phases = [Int64](repeating: 0, count: pool.slices.count)
        let hashes = pool.slices.map { ad -> Int64 in
            var random = BroadcastRandom(seed: "ad-\(ad.id)")
            return Int64(floor(random.next() * Double(Self.scale)))
        }
        let sorted = pool.slices.indices.sorted {
            if hashes[$0] != hashes[$1] { return hashes[$0] < hashes[$1] }
            if pool.slices[$0].id != pool.slices[$1].id { return pool.slices[$0].id < pool.slices[$1].id }
            return $0 < $1
        }
        for (rank, index) in sorted.enumerated() { phases[index] = Int64(rank) * Self.scale / Int64(pool.slices.count) }
        self.phases = phases
        self.start = Int64(pool.start ?? Int(BroadcastRandom.hash("ads-\(channel)") % 1_000)) * 1_000

        let average = Double(pool.slices.reduce(Int64(0)) { $0 + $1.lengthMs }) / Double(pool.slices.count)
        var cycle: Double = 0
        var sinceAd: Int64 = 0
        var inBlock: Int64 = 0
        var years: [Int: Int] = [:]
        var unknown = 0
        for (index, item) in items.enumerated() {
            let duration = Int64(item.duration) * 1_000
            cycle += Double(duration); sinceAd += duration; inBlock += duration
            if let block, index < items.count - 1, inBlock < block.lengthMs {
                cycle += Double(block.cardMs); sinceAd += block.cardMs; inBlock += block.cardMs
                continue
            }
            inBlock = 0
            let next = items[(index + 1) % items.count]
            if item.offAir != true, next.offAir != true, sinceAd >= (pool.gapMs ?? 1_200_000) {
                if let year = Self.year(item.year) { years[year, default: 0] += 1 } else { unknown += 1 }
                cycle += 20_000 + average
                sinceAd = 10_000
            } else {
                cycle += 20_000; sinceAd += 20_000
            }
        }
        self.cycleMs = cycle
        self.byYear = years
        self.unknownYearCount = unknown
    }

    static func year(_ text: String?) -> Int? {
        guard let text else { return nil }
        return Int(text.trimmingCharacters(in: .whitespaces).prefix { $0.isNumber || $0 == "-" })
    }

    private func tiers(for year: Int?) -> [Tier] {
        let tolerances: [Int?] = year == nil ? [nil] : [3, 6] + (pool.decades.map { [-$0] } ?? []) + [nil]
        let tiers = tolerances.map { tolerance -> Tier in
            func matches(_ candidate: Int?) -> Bool {
                guard let tolerance else { return true }
                guard let year, let candidate else { return false }
                return tolerance < 0 ? abs(candidate / 10 - year / 10) <= -tolerance : abs(candidate - year) <= tolerance
            }
            let eligible = pool.slices.indices.filter { pool.slices[$0].anywhere == true || matches(Self.year(pool.slices[$0].year)) }.sorted {
                phases[$0] == phases[$1] ? pool.slices[$0].id < pool.slices[$1].id : phases[$0] < phases[$1]
            }
            let occurrences = byYear.reduce(0) { $0 + (matches($1.key) ? $1.value : 0) } + (matches(nil) ? unknownYearCount : 0)
            let required = cycleMs > 0 ? Double(occurrences) * Double(Self.fortnight) / cycleMs : 0
            let healthy = !eligible.isEmpty && Double(eligible.count) >= required
            let roundMs = healthy || eligible.isEmpty ? Self.fortnight : max(3_600_000, Int64(floor(Double(eligible.count) * cycleMs / Double(max(1, occurrences)))))
            return Tier(indices: eligible, places: eligible.map { phases[$0] }, roundMs: roundMs, healthy: healthy)
        }
        return Array(tiers.dropFirst(tiers.firstIndex(where: \.healthy) ?? max(0, tiers.count - 1)))
    }

    func pick(used: inout Set<Int>, year: Int?, now: Int64, since: Int64) -> Int {
        if used.count >= phases.count { used.removeAll() }
        let tiers = tiers(for: year).filter { !$0.indices.isEmpty }
        var origins: [Int] = []
        for tier in tiers {
            let beginning = phase(at: since, period: tier.roundMs)
            let ending = phase(at: now, period: tier.roundMs)
            let span = now <= since ? 0 : now - since >= tier.roundMs ? Self.scale : modulo(ending - beginning, Self.scale)
            let lookback = min(Self.day, tier.roundMs) * Self.scale / tier.roundMs
            let origin = tier.places.firstIndex { $0 >= beginning + 1 } ?? tier.places.count
            origins.append(origin)
            for step in 0..<tier.indices.count {
                let index = (origin + step) % tier.indices.count
                let distance = modulo(tier.places[index] - beginning, Self.scale)
                if (distance == 0 ? Self.scale : distance) > span { break }
                if used.insert(tier.indices[index]).inserted { return tier.indices[index] }
            }
            for step in 1...tier.indices.count {
                let index = (origin - step + tier.indices.count * 2) % tier.indices.count
                if modulo(beginning - tier.places[index], Self.scale) >= lookback { break }
                if used.insert(tier.indices[index]).inserted { return tier.indices[index] }
            }
        }
        for (tierIndex, tier) in tiers.enumerated() {
            for step in 1...tier.indices.count {
                let index = (origins[tierIndex] - step + tier.indices.count * 2) % tier.indices.count
                if used.insert(tier.indices[index]).inserted { return tier.indices[index] }
            }
        }
        return 0
    }

    private func phase(at time: Int64, period: Int64) -> Int64 {
        (modulo(time, period) * Self.scale / period + start) % Self.scale
    }

    private func modulo(_ value: Int64, _ modulus: Int64) -> Int64 { (value % modulus + modulus) % modulus }
}
