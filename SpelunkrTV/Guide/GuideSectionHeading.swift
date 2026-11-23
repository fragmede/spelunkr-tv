import SwiftUI

struct GuideSectionHeading: View {
    let count: Int
    let favorites: Bool
    let searchText: String
    let categories: [String]
    @Binding var selection: String?
    let refresh: () -> Void

    @ScaledMetric(relativeTo: .caption) private var detailSize = 19.0
    @ScaledMetric(relativeTo: .title3) private var headingSize = 27.0

    var body: some View {
        HStack(spacing: 18) {
            Text(favorites ? "Favorites" : "On now")
                .font(.system(size: headingSize))
                .bold()
                .fixedSize()
            Text(count, format: .number)
                .font(.system(size: detailSize, design: .monospaced))
                .foregroundStyle(SpelunkrTheme.secondary)
            if !searchText.isEmpty {
                Text("“\(searchText)”")
                    .font(.system(size: detailSize))
                    .foregroundStyle(SpelunkrTheme.accent)
                    .lineLimit(1)
                    .frame(maxWidth: 180)
            }
            CategoryFilterView(categories: categories, selection: $selection)
            Button("Refresh guide", systemImage: "arrow.clockwise", action: refresh)
                .labelStyle(.iconOnly)
                .buttonStyle(GuideButtonStyle())
                .accessibilityIdentifier("refresh-guide")
        }
    }
}
