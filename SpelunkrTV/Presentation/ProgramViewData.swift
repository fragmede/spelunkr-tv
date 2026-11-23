import Foundation

struct ProgramViewData: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let subtitle: String?
    let startsAt: Date
    let endsAt: Date
    let thumbnailURL: URL?
    let isInterstitial: Bool

    func progress(at date: Date) -> Double {
        let duration = endsAt.timeIntervalSince(startsAt)
        guard duration > 0 else { return 0 }
        return min(1, max(0, date.timeIntervalSince(startsAt) / duration))
    }
}
