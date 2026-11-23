import SwiftUI

struct GuideFooter: View {
    let status: String?
    let errorMessage: String?

    @ScaledMetric(relativeTo: .caption) private var textSize = 18.0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(SpelunkrTheme.accent)
            }
            if let status {
                Text(status)
            }
            HStack {
                Text("Curated by Spelunkr. Preserved by the Internet Archive.")
                Spacer()
                Text("SPELUNKR.TV")
                    .fontDesign(.monospaced)
                    .tracking(2)
            }
        }
        .font(.system(size: textSize))
        .foregroundStyle(SpelunkrTheme.secondary)
        .padding(.vertical, SpelunkrTheme.spacing)
    }
}
