import SwiftUI

struct FeaturedChannelView: View {
    let channel: ChannelViewData
    let isFavorite: Bool
    let watch: () -> Void
    let toggleFavorite: () -> Void

    @ScaledMetric(relativeTo: .title) private var titleSize = 36.0
    @ScaledMetric(relativeTo: .body) private var descriptionSize = 20.0
    @ScaledMetric(relativeTo: .headline) private var channelSize = 24.0
    @ScaledMetric(relativeTo: .caption) private var metadataSize = 17.0

    var body: some View {
        HStack(alignment: .center, spacing: SpelunkrTheme.spacing) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 14) {
                    Text("CH \(channel.dial)")
                        .font(.system(size: channelSize, weight: .semibold, design: .monospaced))
                        .foregroundStyle(SpelunkrTheme.accent)
                    Text(channel.name.uppercased())
                        .font(.system(size: channelSize, weight: .semibold))
                        .tracking(2)
                        .lineLimit(1)
                }

                Text(channel.current?.title ?? channel.name)
                    .font(.system(size: titleSize, weight: .bold))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(channel.current?.subtitle ?? channel.description)
                    .font(.system(size: descriptionSize))
                    .foregroundStyle(SpelunkrTheme.secondary)
                    .lineLimit(1)

                HStack(spacing: 16) {
                    Button("Watch live", systemImage: "play.fill", action: watch)
                        .buttonStyle(GuideButtonStyle(prominent: true))
                        .accessibilityIdentifier("watch-live")
                    Button(
                        isFavorite ? "Saved" : "Favorite",
                        systemImage: isFavorite ? "star.fill" : "star",
                        action: toggleFavorite
                    )
                    .buttonStyle(GuideButtonStyle())
                    .accessibilityLabel(isFavorite ? "Remove \(channel.name) from favorites" : "Add \(channel.name) to favorites")
                    .accessibilityIdentifier("favorite-toggle")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 12) {
                Spacer(minLength: 0)
                if let program = channel.current {
                    LiveProgramProgress(program: program)
                        .padding(SpelunkrTheme.spacing)
                        .background(.black.opacity(0.66), in: .rect(cornerRadius: 10))
                } else {
                    Text(channel.scheduleError == nil ? "Finding the signal…" : "Schedule unavailable. Select to try again.")
                        .font(.system(size: metadataSize))
                        .foregroundStyle(SpelunkrTheme.secondary)
                }
                if let next = channel.next {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("UP NEXT")
                            .font(.system(size: metadataSize, weight: .bold, design: .monospaced))
                            .tracking(2)
                            .foregroundStyle(SpelunkrTheme.accent)
                        Text(next.title)
                            .font(.system(size: descriptionSize, weight: .semibold))
                            .lineLimit(2)
                        Text(next.startsAt, format: .dateTime.hour().minute())
                            .font(.system(size: metadataSize, design: .monospaced))
                            .foregroundStyle(SpelunkrTheme.secondary)
                    }
                    .padding(SpelunkrTheme.spacing)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.black.opacity(0.58), in: .rect(cornerRadius: 10))
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.leading, 64)
        }
        .padding(24)
        .frame(minHeight: 300)
        .background {
            HStack(spacing: 0) {
                SpelunkrTheme.surface
                    .frame(maxWidth: .infinity)
                BroadcastArtwork(
                    url: channel.current?.thumbnailURL,
                    accent: SpelunkrTheme.channelColor(channel.accentHex)
                )
                .frame(maxWidth: .infinity)
            }
            .overlay {
                LinearGradient(
                    stops: [
                        .init(color: SpelunkrTheme.surface, location: 0.3),
                        .init(color: SpelunkrTheme.surface.opacity(0.93), location: 0.48),
                        .init(color: SpelunkrTheme.surface.opacity(0.12), location: 1)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        }
        .clipShape(.rect(cornerRadius: SpelunkrTheme.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: SpelunkrTheme.cornerRadius)
                .strokeBorder(.white.opacity(0.10), lineWidth: 1)
        }
        .focusSection()
    }
}
