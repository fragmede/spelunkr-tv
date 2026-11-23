import SwiftUI

struct PlaybackChannelControls: View {
    let model: PlaybackModel
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: 28) {
            Button("Guide", systemImage: "rectangle.grid.2x2", action: dismiss)
                .accessibilityIdentifier("return-to-guide")
            Button("Previous channel", systemImage: "chevron.up", action: previous)
            Button("Next channel", systemImage: "chevron.down", action: next)
        }
        .font(.headline)
    }

    private func previous() { model.switchChannel(-1) }
    private func next() { model.switchChannel(1) }
}
