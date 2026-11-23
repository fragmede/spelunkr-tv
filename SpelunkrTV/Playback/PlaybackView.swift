import SwiftUI

struct PlaybackView: View {
    let channelID: String
    @State private var model: PlaybackModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    init(channelID: String, guide: GuideModel) {
        self.channelID = channelID
        _model = State(initialValue: PlaybackModel(guide: guide))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            NativePlayerView(model: model, dismiss: close)
                .ignoresSafeArea()

            if !model.isBroadcastCard, let audio = model.airing?.audio {
                VStack {
                    HStack {
                        AudioCreditView(audio: audio)
                            .padding(20)
                            .background(.black.opacity(0.65), in: .rect(cornerRadius: 12))
                        Spacer()
                    }
                    Spacer()
                }
                .padding(48)
                .allowsHitTesting(false)
            }

            if model.isBroadcastCard {
                BroadcastCardView(model: model, dismiss: close)
            } else if let error = model.errorMessage {
                PlaybackRecoveryView(message: error, model: model, dismiss: close)
            } else if model.isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                    Text("Tuning in…")
                        .font(.title3)
                    Text(model.channel?.name ?? "Spelunkr")
                        .foregroundStyle(.secondary)
                }
                .padding(48)
                .background(.black.opacity(0.85), in: .rect(cornerRadius: 24))
                .allowsHitTesting(false)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("playback-loading")
            }
        }
        .accessibilityIdentifier("playback-screen")
        .task { await model.run(channelID: channelID) }
        .onExitCommand(perform: close)
        .onChange(of: scenePhase) { _, phase in
            model.setActive(phase == .active)
        }
        .onDisappear { model.stop() }
    }

    private func close() {
        model.stop()
        dismiss()
    }
}
