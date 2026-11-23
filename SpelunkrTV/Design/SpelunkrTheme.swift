import SwiftUI

enum SpelunkrTheme {
    static let background = Color(red: 0.035, green: 0.025, blue: 0.075)
    static let surface = Color(red: 0.10, green: 0.075, blue: 0.18)
    static let raisedSurface = Color(red: 0.16, green: 0.12, blue: 0.27)
    static let accent = Color(red: 0.97, green: 0.91, blue: 0.37)
    static let secondary = Color(red: 0.73, green: 0.71, blue: 0.80)
    static let pageInset: Double = 64
    static let spacing: Double = 18
    static let cornerRadius: Double = 14

    static func channelColor(_ hex: String) -> Color {
        let value = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard value.count == 6, let rgb = UInt32(value, radix: 16) else {
            return raisedSurface
        }
        return Color(
            red: Double((rgb >> 16) & 0xff) / 255,
            green: Double((rgb >> 8) & 0xff) / 255,
            blue: Double(rgb & 0xff) / 255
        )
    }
}
