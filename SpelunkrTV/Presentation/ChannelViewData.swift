import Foundation

struct ChannelViewData: Identifiable, Equatable, Sendable {
    let id: String
    let number: Int
    let name: String
    let description: String
    let category: String
    let logoURL: URL?
    let accentHex: String
    let current: ProgramViewData?
    let next: ProgramViewData?
    let scheduleError: String?

    var dial: String {
        number.formatted(.number.grouping(.never).precision(.integerLength(2...)))
    }
}
