import SwiftUI

struct CategoryFilterView: View {
    let categories: [String]
    @Binding var selection: String?

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                Button("All channels", action: selectAll)
                    .buttonStyle(GuideButtonStyle(selected: selection == nil))
                    .accessibilityIdentifier("all-categories")
                ForEach(categories, id: \.self) { category in
                    Button(category) { selection = category }
                        .buttonStyle(GuideButtonStyle(selected: selection == category))
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
        }
        .scrollIndicators(.hidden)
        .focusSection()
    }

    private func selectAll() { selection = nil }
}
