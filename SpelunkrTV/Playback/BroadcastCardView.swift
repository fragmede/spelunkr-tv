import SwiftUI

struct BroadcastCardView: View {
    let model: PlaybackModel
    let dismiss: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            HStack {
                Text("SPELUNKR")
                    .font(.title2.bold())
                    .tracking(4)
                Spacer()
                Label("LIVE", systemImage: "dot.radiowaves.left.and.right")
                    .foregroundStyle(.yellow)
            }
            Spacer()
            Text(model.cardText)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .frame(maxWidth: 1200)
                .accessibilityIdentifier("broadcast-card-text")
            Text(model.channel?.name.uppercased() ?? "SPELUNKR.TV")
                .font(.headline.monospaced())
                .foregroundStyle(.secondary)
            if let audio = model.airing?.audio {
                AudioCreditView(audio: audio)
            }
            Spacer()
            PlaybackChannelControls(model: model, dismiss: dismiss)
        }
        .padding(72)
        .background(Color(red: 0.065, green: 0.045, blue: 0.16))
    }
}
