import SwiftUI

struct BroadcastArtwork: View {
    let url: URL?
    let accent: Color

    var body: some View {
        AsyncImage(url: url) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            ZStack {
                LinearGradient(
                    colors: [accent.opacity(0.55), SpelunkrTheme.surface],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: "tv")
                    .font(.largeTitle)
                    .foregroundStyle(.white.opacity(0.22))
            }
        }
        .clipped()
        .accessibilityHidden(true)
    }
}
