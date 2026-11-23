import SwiftUI

struct GuideView: View {
    @Bindable var model: GuideModel
    let playChannel: (ChannelViewData) -> Void

    @State private var isShowingSearch = false
    @State private var isShowingAbout = false
    @FocusState private var focusedChannelID: String?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: SpelunkrTheme.spacing), count: 4)

    var body: some View {
        VStack(spacing: 0) {
            GuideHeader(
                showingFavorites: $model.showingFavorites,
                showSearch: showSearch,
                showAbout: showAbout
            )

            if model.channels.isEmpty {
                GuideLoadingView(isLoading: model.isLoading, errorMessage: model.errorMessage, retry: refresh)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: SpelunkrTheme.spacing) {
                        if let channel = model.selectedChannel {
                            FeaturedChannelView(
                                channel: channel,
                                isFavorite: model.favoriteIDs.contains(channel.id),
                                watch: { playChannel(channel) },
                                toggleFavorite: { model.toggleFavorite(channel.id) }
                            )
                        }

                        GuideSectionHeading(
                            count: model.visibleChannels.count,
                            favorites: model.showingFavorites,
                            searchText: model.searchText,
                            categories: model.categoryOptions,
                            selection: $model.selectedCategory,
                            refresh: refresh
                        )

                        if model.visibleChannels.isEmpty {
                            ContentUnavailableView(
                                model.showingFavorites ? "No favorites here yet" : "No channels found",
                                systemImage: model.showingFavorites ? "star" : "magnifyingglass",
                                description: Text(model.showingFavorites ? "Save a channel with the Favorite button, or try another category." : "Try a different channel name, program, or category.")
                            )
                        } else {
                            LazyVGrid(columns: columns, spacing: SpelunkrTheme.spacing) {
                                ForEach(model.visibleChannels) { channel in
                                    Button { playChannel(channel) } label: {
                                        ChannelCardView(channel: channel, isFavorite: model.favoriteIDs.contains(channel.id))
                                    }
                                    .buttonStyle(ChannelCardButtonStyle())
                                    .focused($focusedChannelID, equals: channel.id)
                                    .accessibilityIdentifier("channel-\(channel.id)")
                                }
                            }
                            .focusSection()
                        }

                        GuideFooter(status: model.statusMessage, errorMessage: model.errorMessage)
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                    .padding(.bottom, SpelunkrTheme.spacing)
                }
                .scrollIndicators(.hidden)
            }
        }
        .padding(.horizontal, SpelunkrTheme.pageInset)
        .padding(.vertical, 12)
        .background { BroadcastBackdrop() }
        .foregroundStyle(.white)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $isShowingSearch) { ChannelSearchView(query: $model.searchText) }
        .sheet(isPresented: $isShowingAbout) { AboutView() }
        .onChange(of: focusedChannelID) { _, channelID in
            if let channelID { model.focusedChannelID = channelID }
        }
    }

    private func showSearch() { isShowingSearch = true }
    private func showAbout() { isShowingAbout = true }
    private func refresh() { Task { await model.refresh() } }
}
