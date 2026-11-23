import SwiftUI

struct RootView: View {
    @State private var model = GuideModel()
    @State private var playingChannel: ChannelViewData?
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        GuideView(model: model, playChannel: play)
            .task { await model.run() }
            .fullScreenCover(item: $playingChannel) { channel in
                PlaybackView(channelID: channel.id, guide: model)
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    model.updateAiring()
                }
            }
    }

    private func play(_ channel: ChannelViewData) {
        playingChannel = channel
    }
}
