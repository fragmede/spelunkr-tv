import SwiftUI

struct GuideButtonStyle: ButtonStyle {
    var prominent = false
    var selected = false

    @Environment(\.isFocused) private var isFocused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .headline) private var labelSize = 24.0

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: labelSize, weight: .semibold))
            .padding(.horizontal, SpelunkrTheme.spacing)
            .padding(.vertical, 11)
            .foregroundStyle(isFocused || prominent ? SpelunkrTheme.background : .white)
            .background(
                isFocused || prominent ? SpelunkrTheme.accent : SpelunkrTheme.raisedSurface,
                in: .rect(cornerRadius: 10)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        isFocused ? .white : selected ? SpelunkrTheme.accent : .clear,
                        lineWidth: isFocused ? 4 : 2
                    )
            }
            .scaleEffect(configuration.isPressed ? 0.97 : isFocused && !reduceMotion ? 1.04 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: isFocused)
    }
}
