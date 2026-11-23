import SwiftUI

struct PlaybackRecoveryView: View {
    let message: String
    let model: PlaybackModel
    let dismiss: () -> Void

    var body: some View {
        VStack(spacing: 36) {
            ContentUnavailableView {
                Label("A little signal trouble", systemImage: "antenna.radiowaves.left.and.right.slash")
            } description: {
                Text(message)
            } actions: {
                Button("Try again", systemImage: "arrow.clockwise", action: model.retry)
                    .accessibilityIdentifier("retry-playback")
            }
            PlaybackChannelControls(model: model, dismiss: dismiss)
        }
        .padding(72)
        .background(.black.opacity(0.96))
        .accessibilityIdentifier("playback-error")
    }
}
