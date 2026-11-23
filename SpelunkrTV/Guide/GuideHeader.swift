import SwiftUI

struct GuideHeader: View {
    @Binding var showingFavorites: Bool
    let showSearch: () -> Void
    let showAbout: () -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var wordmarkSize = 34.0
    @ScaledMetric(relativeTo: .caption) private var captionSize = 17.0
    @ScaledMetric(relativeTo: .headline) private var clockSize = 24.0

    var body: some View {
        HStack(alignment: .center, spacing: SpelunkrTheme.spacing) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 7) {
                    Text("SPELUNKR")
                        .font(.system(size: wordmarkSize, weight: .black, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(SpelunkrTheme.accent)
                    Text("TV")
                        .font(.system(size: clockSize, design: .monospaced))
                        .foregroundStyle(SpelunkrTheme.secondary)
                }
                Text("Cable TV, but weirder.")
                    .font(.system(size: captionSize))
                    .foregroundStyle(SpelunkrTheme.secondary)
            }
            .accessibilityElement(children: .combine)

            Spacer(minLength: SpelunkrTheme.spacing)

            Button("Live guide", action: showAll)
                .buttonStyle(GuideButtonStyle(selected: !showingFavorites))
                .accessibilityIdentifier("live-guide-tab")
            Button("Favorites", systemImage: "star", action: showFavorites)
                .buttonStyle(GuideButtonStyle(selected: showingFavorites))
                .accessibilityIdentifier("favorites-tab")
            Button("Search", systemImage: "magnifyingglass", action: showSearch)
                .buttonStyle(GuideButtonStyle())
                .accessibilityIdentifier("search-button")
            Button("About", systemImage: "info.circle", action: showAbout)
                .labelStyle(.iconOnly)
                .buttonStyle(GuideButtonStyle())

            TimelineView(.periodic(from: .now, by: 30)) { context in
                Text(context.date, format: .dateTime.hour().minute())
                    .font(.system(size: clockSize, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(SpelunkrTheme.secondary)
                    .padding(.leading, SpelunkrTheme.spacing)
            }
        }
        .padding(.top, 4)
        .padding(.bottom, SpelunkrTheme.spacing)
    }

    private func showAll() { showingFavorites = false }
    private func showFavorites() { showingFavorites = true }
}
