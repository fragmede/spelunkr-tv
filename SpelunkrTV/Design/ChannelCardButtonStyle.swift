import SwiftUI

struct ChannelCardButtonStyle: ButtonStyle {
    @Environment(\.isFocused) private var isFocused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(SpelunkrTheme.surface, in: .rect(cornerRadius: SpelunkrTheme.cornerRadius))
            .clipShape(.rect(cornerRadius: SpelunkrTheme.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: SpelunkrTheme.cornerRadius)
                    .strokeBorder(isFocused ? SpelunkrTheme.accent : .white.opacity(0.10), lineWidth: isFocused ? 4 : 1)
            }
            .scaleEffect(configuration.isPressed ? 0.98 : isFocused && !reduceMotion ? 1.025 : 1)
            .shadow(color: .black.opacity(isFocused ? 0.4 : 0), radius: 14, y: 8)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: isFocused)
    }
}
