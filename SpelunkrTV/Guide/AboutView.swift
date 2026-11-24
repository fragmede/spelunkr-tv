import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showsPrivacyPolicy = false

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
            HStack(spacing: 24) {
                Button("Privacy Policy") { showsPrivacyPolicy = true }
                    .buttonStyle(GuideButtonStyle())
                Button("Back to the guide", action: close)
                    .buttonStyle(GuideButtonStyle(prominent: true))
            }
        }
        .padding(64)
        .frame(maxWidth: 1100)
        .fullScreenCover(isPresented: $showsPrivacyPolicy) {
            VStack(alignment: .leading, spacing: 30) {
                Text("Privacy Policy")
                    .font(.title.bold())
                    .accessibilityAddTraits(.isHeader)
                    .foregroundStyle(SpelunkrTheme.accent)
                Text("Effective November 23, 2026. Published by OnePatchDown, LLC.")
                Text("The Apple TV app has no account, analytics, or tracking. Favorites stay on your Apple TV. Remove them in the guide or delete the app to clear its local data.")
                Text("The app requests listings, artwork, and streams directly from Spelunkr and the Internet Archive. These providers receive your IP address and ordinary request details, which they handle under their own policies. OnePatchDown does not operate a server that receives these requests or stores your viewing activity.")
                Text("For privacy questions, visit github.com/fragmede/spelunkr-tv/issues. Issues are public. Keep personal information out of them.")
                Button("Back to About") { showsPrivacyPolicy = false }
                    .buttonStyle(GuideButtonStyle(prominent: true))
            }
            .padding(64)
            .frame(maxWidth: 1250)
            .onExitCommand { showsPrivacyPolicy = false }
        }
    }

    private func close() { dismiss() }
}
