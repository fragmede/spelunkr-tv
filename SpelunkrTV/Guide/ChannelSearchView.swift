import SwiftUI

struct ChannelSearchView: View {
    @Binding var query: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            Label("Find your frequency", systemImage: "magnifyingglass")
                .font(.title)
                .bold()
            Text("Search channels and what’s on right now.")
                .foregroundStyle(SpelunkrTheme.secondary)
            TextField("Channel or program", text: $query)
                .autocorrectionDisabled()
                .onSubmit(close)
                .accessibilityIdentifier("channel-search-field")
            HStack(spacing: 24) {
                Button("Show results", action: close)
                    .buttonStyle(GuideButtonStyle(prominent: true))
                Button("Clear search", action: clear)
                    .buttonStyle(GuideButtonStyle())
                    .disabled(query.isEmpty)
            }
        }
        .padding(64)
        .frame(maxWidth: 1050)
    }

    private func close() { dismiss() }
    private func clear() { query = "" }
}
