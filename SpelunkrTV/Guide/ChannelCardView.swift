import SwiftUI

struct ChannelCardView: View {
    let channel: ChannelViewData
    let isFavorite: Bool

    @ScaledMetric(relativeTo: .headline) private var nameSize = 23.0
    @ScaledMetric(relativeTo: .body) private var titleSize = 20.0
    @ScaledMetric(relativeTo: .caption) private var metadataSize = 17.0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            BroadcastArtwork(
                url: channel.current?.thumbnailURL,
                accent: SpelunkrTheme.channelColor(channel.accentHex)
            )
            .frame(height: 130)
            .clipped()
            .overlay(alignment: .topLeading) {
                Text("CH \(channel.dial)")
                    .font(.system(size: metadataSize, weight: .bold, design: .monospaced))
                    .foregroundStyle(SpelunkrTheme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.black.opacity(0.75), in: .rect(cornerRadius: 6))
                    .padding(14)
            }
            .overlay(alignment: .topTrailing) {
                if isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: metadataSize))
                        .foregroundStyle(SpelunkrTheme.accent)
                        .padding(8)
                        .background(.black.opacity(0.75), in: .circle)
                        .padding(14)
                        .accessibilityHidden(true)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(channel.name)
                    .font(.system(size: nameSize, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(channel.current?.title ?? (channel.scheduleError == nil ? "Tuning the guide…" : "Schedule unavailable"))
                    .font(.system(size: titleSize))
                    .foregroundStyle(SpelunkrTheme.secondary)
                    .lineLimit(2, reservesSpace: true)

                HStack(spacing: 8) {
                    Circle()
                        .fill(SpelunkrTheme.accent)
                        .frame(width: 6, height: 6)
                        .accessibilityHidden(true)
                    Text(channel.current?.isInterstitial == true ? "STATION BREAK" : "ON NOW")
                        .font(.system(size: metadataSize, weight: .medium, design: .monospaced))
                        .tracking(1)
                    Spacer()
                    if let next = channel.next {
                        Text(next.startsAt, format: .dateTime.hour().minute())
                            .font(.system(size: metadataSize, design: .monospaced))
                    }
                }
                .foregroundStyle(SpelunkrTheme.secondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Channel \(channel.number), \(channel.name). \(channel.current?.title ?? "Schedule loading").\(isFavorite ? " Favorite." : "")")
        .accessibilityHint("Select to watch live")
    }
}
