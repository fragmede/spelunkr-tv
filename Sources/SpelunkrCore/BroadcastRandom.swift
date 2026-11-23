import Foundation

/// Matches the site's signed UTF-16 string hash and Mulberry32 PRNG.
struct BroadcastRandom {
    private var state: UInt32

    init(seed: String) { state = Self.hash(seed) }

    static func hash(_ value: String) -> UInt32 {
        value.utf16.reduce(UInt32(0)) { ($0 &* 31) &+ UInt32($1) }
    }

    mutating func next() -> Double {
        state = state &+ 1_831_565_813
        var value = (state ^ (state >> 15)) &* (1 | state)
        value ^= value &+ ((value ^ (value >> 7)) &* (61 | value))
        return Double(value ^ (value >> 14)) / 4_294_967_296
    }

    mutating func index(count: Int) -> Int { Int(floor(next() * Double(count))) }
}
