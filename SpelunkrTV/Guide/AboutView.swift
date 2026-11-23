import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Text("Always on. Wonderfully offbeat.")
                .font(.title)
                .bold()
                .foregroundStyle(SpelunkrTheme.accent)
            Text("An unofficial Apple TV frontend for Spelunkr.")
                .font(.headline)
            Text("Spelunkr curates the channels. The Internet Archive hosts the tapes. Tune in to the same moment as everyone else, whenever you arrive.")
                .foregroundStyle(SpelunkrTheme.secondary)
            Text("Explore the originals at spelunkr.tv and archive.org.")
                .foregroundStyle(SpelunkrTheme.secondary)
            Button("Back to the guide", action: close)
                .buttonStyle(GuideButtonStyle(prominent: true))
        }
        .padding(64)
        .frame(maxWidth: 1100)
    }

    private func close() { dismiss() }
}
