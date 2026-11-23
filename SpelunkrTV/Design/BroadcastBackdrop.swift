import SwiftUI

struct BroadcastBackdrop: View {
    var body: some View {
        LinearGradient(
            colors: [SpelunkrTheme.surface, SpelunkrTheme.background, SpelunkrTheme.background],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(SpelunkrTheme.accent.opacity(0.7))
                .frame(height: 3)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
