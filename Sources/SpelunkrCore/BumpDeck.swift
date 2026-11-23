import Foundation

struct BumpDeck: Sendable {
    var order: [Bump] = []
    var position = 0
    var seasonalKey: String?
    var recent: [Bump] = []
    var rounds = 0

    mutating func take(from bumps: [Bump], channel: String, seed: String, at time: Int64) -> Bump? {
        let eligible = Self.eligible(bumps, at: time)
        guard !eligible.isEmpty else { return nil }
        let key = bumps.filter { $0.active != false && $0.date_range != nil && Self.inSeason($0, at: time) }.map(\.id).joined(separator: "|")
        if key != seasonalKey || position >= order.count {
            order = shuffled(eligible, seed: "\(channel)-deck-\(seed)-\(rounds)")
            rounds += 1
            position = 0
            seasonalKey = key
        }
        let bump = order[position]
        position += 1
        recent.append(bump)
        if recent.count > order.count { recent.removeFirst() }
        return bump
    }

    private func shuffled(_ input: [Bump], seed: String) -> [Bump] {
        var random = BroadcastRandom(seed: seed)
        var result = input
        if result.count > 1 {
            for index in stride(from: result.count - 1, through: 1, by: -1) {
                result.swapAt(index, random.index(count: index + 1))
            }
        }
        let half = result.count / 2
        let recentCount = min(half, recent.count)
        guard recentCount > 0 else { return result }
        var earliest: [String: Int] = [:]
        for distance in stride(from: recentCount, through: 1, by: -1) {
            earliest[recent[recent.count - distance].id] = half + 1 - distance
        }
        for distance in 1...recentCount {
            let bump = recent[recent.count - distance]
            guard let index = result.firstIndex(where: { $0.id == bump.id }), index < earliest[bump.id, default: 0] else { continue }
            let candidates = (earliest[bump.id, default: 0]..<result.count).filter { earliest[result[$0].id, default: 0] <= index }
            if !candidates.isEmpty { result.swapAt(index, candidates[random.index(count: candidates.count)]) }
        }
        return result
    }

    static func pick(from bumps: [Bump], breakIndex: Int, channel: String, seed: String, at time: Int64) -> Bump? {
        let eligible = eligible(bumps, at: time)
        guard !eligible.isEmpty else { return nil }
        var random = BroadcastRandom(seed: "\(channel)-break-\(breakIndex)-\(seed)")
        return eligible[random.index(count: eligible.count)]
    }

    static func eligible(_ bumps: [Bump], at time: Int64) -> [Bump] {
        bumps.filter { $0.active != false && ($0.date_range == nil || inSeason($0, at: time)) }
    }

    static func inSeason(_ bump: Bump, at time: Int64) -> Bool {
        guard let range = bump.date_range, range.count == 2 else { return true }
        let from = range[0], to = range[1]
        if from.count > 5 {
            guard let start = ISO8601DateFormatter().date(from: "\(from)T00:00:00Z"),
                  let end = ISO8601DateFormatter().date(from: "\(to)T23:59:59Z") else { return false }
            return Double(time) >= start.timeIntervalSince1970 * 1_000 && Double(time) <= end.timeIntervalSince1970 * 1_000 + 999
        }
        let start = Int(from.replacingOccurrences(of: "-", with: "")) ?? 0
        let end = Int(to.replacingOccurrences(of: "-", with: "")) ?? 0
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = Date(timeIntervalSince1970: Double(time) / 1_000)
        let value = calendar.component(.month, from: date) * 100 + calendar.component(.day, from: date)
        return start <= end ? value >= start && value <= end : value >= start || value <= end
    }

    static func slideDuration(_ text: String) -> Int64 { max(2_500, 1_500 + Int64(text.utf16.count) * 55) }

    static func duration(_ bump: Bump) -> Int64 { bump.slides.reduce(0) { $0 + slideDuration($1.text) } }
}
